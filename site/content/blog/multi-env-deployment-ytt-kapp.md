---
title: "Handle multiple environments with ytt and kapp"
slug: multi-env-deployment-ytt-kapp
date: 2022-03-10
author: Yash Sethiya
excerpt: "Managing Multi-environments configuration with ytt and kapp"
image: /img/logo.svg
tags: ['carvel', 'kapp', 'ytt']

---

One of the most typical challenges when deploying a complex application is the handling of different deployment environments during the software lifecycle.

Commonly, the setup is a trilogy of QA/Staging/Production environments. An application developer needs an easy way to deploy to the different environments and also to understand what version is deployed where.

Unlike [many other tools used for templating](https://carvel.dev/ytt/docs/v0.40.0/ytt-vs-x/), ytt takes a different approach to work with YAML files. Instead of interpreting YAML configuration as plain text, it works with YAML structures such as maps, lists, YAML documents, scalars, etc. By doing so ytt is able to eliminate a lot of problems that plague other tools (character escaping, ambiguity, indentation, etc.). Additionally ytt provides Python-like language (Starlark) that executes in a hermetic environment making it friendly, yet more deterministic compared to just using general purpose languages directly or non-familiar custom templating languages.


## How to handle different environment configurations

This problem is usually solved in two ways: templating or patching. [ytt](https://carvel.dev/ytt) supports both approaches. In this section, we’ll see how ytt allows to template YAML configuration, and how it can patch YAML configuration via overlays.

### Data values
Data values provide a way to inject input data. In ytt, before a Data Value can be used in a template, it must be declared. This is done via [Data Values Schema](https://carvel.dev/ytt/docs/v0.40.0/how-to-write-schema/#overview). We will have a common schema file for all the environments.

```yaml
#! schema.yaml (#! is used for comment in ytt)
#@data/values-schema
---
replicaCount: 1

image:
  name: nginx
  tag: "1.14.2"

nameOverride: ""
fullnameOverride: ""

appMode: ""
certificatePath: ""
databaseUser: ""
databasePassword: ""
```

A schema sets the defaults for each data value as they are declared. We will want to override some of those defaults for each of our environments. We do this by creating a values file for each environment. Let's suppose we have two environments `staging` and `prod`.

In `values-staging.yaml` we will be just putting the values that we want to override from schema
 
```yaml
#! values-staging.yaml
#@data/values
---
image:
  tag: "latest"

nameOverride: "staging"

appMode: staging
certificatePath: /etc/ssl/staging
databaseUser: staging-user
databasePassword: staging-password
```

In production maybe we want to have more replicas so we can override that in `values-prod.yaml`

```yaml
#! values-prod.yaml
#@data/values
---
replicaCount: 3

nameOverride: "prod"

appMode: prod
certificatePath: /etc/ssl/prod
databaseUser: prod-user
databasePassword: prod-password
```

## Using Data Values in manifest
Now we will see how we can use the data values that has been declared via data value schema. Here I have put all the resources in single yaml file `app.yaml` just for the demonstration purpose.

```yaml
#! app.yaml
#@ load("@ytt:data", "data")
---
#@ def fullname():
#@ return data.values.fullnameOverride if data.values.fullnameOverride else "sample-app-" + data.values.nameOverride
#@ end

#@ def labels():
app.kubernetes.io/name: #@ fullname()
#@ end

apiVersion: v1
kind: Service
metadata:
  name: #@ fullname()
  labels: #@ labels()
spec:
  selector:
    app: #@ fullname()
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ fullname()
  labels: #@ labels()
spec:
  replicas: #@ data.values.replicaCount
  selector:
    matchLabels: #@ labels()
  template:
    metadata:
      labels: #@ labels()
    spec:
      containers:
        - name: sample-app
          image: #@ data.values.image.name + ":" + data.values.image.tag
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 8080
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: application-settings
data:
  app_mode: #@ data.values.appMode
  certificates: #@ data.values.certificatePath
  db_user: #@ data.values.databaseUser
  db_password: #@ data.values.databasePassword
```

As you can see above file contains lots of ytt annotations (i.e. lines that contain #@), it’s a ytt template. With the help of this annotations we are using the values defined in schema file. 

## Deploying with kapp 
Let's now look into how we can deploy for different environments by passing environment specific `values-*.yaml` we created above. First, let's see the final manifest for staging environment.

```bash
$ ytt -f app.yaml -f schema.yaml -f values-staging.yaml
apiVersion: v1
kind: Service
metadata:
  name: sample-app-staging
  labels:
    app.kubernetes.io/name: sample-app-staging
spec:
  selector:
    app: sample-app-staging
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app-staging
  labels:
    app.kubernetes.io/name: sample-app-staging
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: sample-app-staging
  template:
    metadata:
      labels:
        app.kubernetes.io/name: sample-app-staging
    spec:
      containers:
      - name: sample-app
        image: nginx:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: application-settings
data:
  app_mode: staging
  certificates: /etc/ssl/staging
  db_user: staging-user
  db_password: staging-password
```

**Try this** out in our [ytt interactive playground]((https://carvel.dev/ytt/#gist:https://gist.github.com/sethiyash/63287cf10fcd2155bb0247012939207a)

As our final manifest looks good let's deploy it with kapp - 

```bash
$ kapp deploy -a sample-app -f <(ytt -f app.yaml -f schema.yaml -f values-staging.yaml)
Target cluster 'https://127.0.0.1:57418' (nodes: minikube)

Changes

Namespace  Name                  Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri  
default    application-settings  ConfigMap   -       -    create  -       reconcile  -   -  
^          sample-app-staging    Deployment  -       -    create  -       reconcile  -   -  
^          sample-app-staging    Service     -       -    create  -       reconcile  -   -  

Op:      3 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 3 reconcile, 0 delete, 0 noop

Continue? [yN]: 
```

Here [kapp](https://carvel.dev/kapp/) is showing calculated changes between configuration provided and live cluster state. It then asks for confirmation before actually applying the change.
Similarly, for deploying application on prod environment we will be passing `values-prod.yaml`.

### Overlays
When the user would like to configure fields beyond what the original author has exposed as data values, they should turn to Overlays. Here we look into a way to specify locations within configuration and either add to, remove from, or replace within that existing configuration.

```yaml
#! add-namespace.yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.all, expects="1+"
---
metadata:
  #@overlay/match missing_ok=True
  namespace: my-namespace
```

Let's now consider a usecase where we want to patch the namespace for all of the resources we have and we don't want to edit all the documents to add the `namespace` field. This can easily be achieved by something called as [Overlays](https://carvel.dev/ytt/docs/v0.40.0/ytt-overlays/) in ytt. In `add-namespace.yaml` file we have defined an overlay to add the `namespace` field inside `metadata` for all the resources. Here ` #@overlay/match missing_ok=True` means that let's add the field even if it not exists and if it exists let's change the namespace to `my-namespace`.

On applying overlay, final manifest will look like - 

```bash
$ ytt -f app.yaml -f schema.yaml -f values-prod.yaml -f add-namespace.yaml
apiVersion: v1
kind: Service
metadata:
  name: sample-app-prod
  labels:
    app.kubernetes.io/name: sample-app-prod
  namespace: my-namespace
spec:
  selector:
    app: sample-app-prod
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app-prod
  labels:
    app.kubernetes.io/name: sample-app-prod
  namespace: my-namespace
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: sample-app-prod
  template:
    metadata:
      labels:
        app.kubernetes.io/name: sample-app-prod
    spec:
      containers:
      - name: sample-app
        image: nginx:1.14.2
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: application-settings
  namespace: my-namespace
data:
  app_mode: prod
  certificates: /etc/ssl/prod
  db_user: prod-user
  db_password: prod-password
```

**Try this** out in our [ytt interactive playground](https://carvel.dev/ytt/#gist:https://gist.github.com/sethiyash/2e527d2f5acd93015edb9f4565c9aeed). 

Now let's deploy it using kapp - 
```bash
$ kapp deploy -a sample-app -f <(ytt -f app.yaml -f schema.yaml -f values-prod.yaml -f add-namespace.yaml) -y
Target cluster 'https://127.0.0.1:57418' (nodes: minikube)

Changes

Namespace     Name                  Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri  
my-namespace  application-settings  ConfigMap   -       -    create  -       reconcile  -   -  
^             sample-app-prod       Deployment  -       -    create  -       reconcile  -   -  
^             sample-app-prod       Service     -       -    create  -       reconcile  -   -  

Op:      3 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 3 reconcile, 0 delete, 0 noop

6:55:46PM: ---- applying 1 changes [0/3 done] ----
6:55:46PM: create configmap/application-settings (v1) namespace: my-namespace
6:55:46PM: ---- waiting on 1 changes [0/3 done] ----
6:55:46PM: ok: reconcile configmap/application-settings (v1) namespace: my-namespace
6:55:46PM: ---- applying 2 changes [1/3 done] ----
6:55:46PM: create deployment/sample-app-prod (apps/v1) namespace: my-namespace
6:55:46PM: create service/sample-app-prod (v1) namespace: my-namespace
6:55:46PM: ---- waiting on 2 changes [1/3 done] ----
...
6:55:50PM: ---- applying complete [3/3 done] ----
6:55:50PM: ---- waiting complete [3/3 done] ----

Succeeded
```

This time I deployed using kapp `-y` flag which will not ask for confirmation before applying the changes. It also shows a progress log while reconciling for the changes to provide details on for which resources it is waiting and what all got applied successfully.

Here, just to limit the scope of this article I have used some basic but powerful features of ytt for templating and patching but there are many advanced features provided by ytt which will be worth exploring and can match your specific use case.

To learn more...
- take a feature-wise tour of `ytt` by exploring the ["Basics" example group in the playground](https://carvel.dev/ytt/#example:example-plain-yaml)
- get a more thorough introduction of how to [Use Data Values](https://carvel.dev/ytt/docs/v0.40.0/how-to-use-data-values/).
- if you're curious about the order and manner `ytt` processes inputs, check out [How it works](https://carvel.dev/ytt/docs/v0.40.0/how-it-works/).

Hope you enjoyed reading this blog and believe it will make your life easier in handling different deployment environments. Share your experience in our Carvel's slack channel.
## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.