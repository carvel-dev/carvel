---
title: "Updating resources automatically when their referenced resources are updated"
slug: updating-resources-automatically-when-their-referenced-resources-are-updated
date: 2022-06-23
author: Kumari Tanushree
excerpt: "Automatic update to the resources by kapp when their referenced resources get updated"
image: /img/logo.svg
tags: ['carvel', 'kapp', 'versioned-resource']

---

Have you ever wanted your deployments or pods to automatically get redeployed when their referenced configmaps or secrets are updated?


In this blog, we are going to learn how to use [kapp](https://carvel.dev/kapp/) re-start or re-deploy the resources when their referenced resources get updated.

 
## Deploy resources where one resource is being referenced by other:

Let's consider a ConfigMap and a Deployment, where the ConfigMap is being referenced by the Deployment's container.
```yaml 
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: simple-config
data:
  hello_msg: hello-carvel
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: simple-app
spec:
  selector:
    matchLabels:
      simple-app: ""
  template:
    metadata:
      labels:
        simple-app: ""
    spec:
      containers:
      - name: simple-app
        image: nginx:1.21.6
        env:
          - name: MSG_KEY
            valueFrom:
              configMapKeyRef:
                 name: simple-config
                 key: hello_msg
```
 
Let's deploy them to the cluster using `kapp`

```bash
$kapp deploy -a app -f  app.yaml
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Changes

Namespace  Name           Kind        Age  Op      Op st.  Wait to    Rs  Ri  
default    simple-app     Deployment  -    create  -       reconcile  -   -  
^          simple-config  ConfigMap   -    create  -       reconcile  -   -  

Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

4:08:11PM: ---- applying 1 changes [0/2 done] ----
4:08:11PM: create configmap/simple-config (v1) namespace: default
4:08:11PM: ---- waiting on 1 changes [0/2 done] ----
4:08:11PM: ok: reconcile configmap/simple-config (v1) namespace: default
4:08:11PM: ---- applying 1 changes [1/2 done] ----
4:08:11PM: create deployment/simple-app (apps/v1) namespace: default
4:08:11PM: ---- waiting on 1 changes [1/2 done] ----
4:08:11PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
4:08:11PM:  ^ Waiting for generation 2 to be observed
4:08:12PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
4:08:12PM:  ^ Waiting for 1 unavailable replicas
4:08:12PM:  L ok: waiting on replicaset/simple-app-657f9c8494 (apps/v1) namespace: default
4:08:12PM:  L ongoing: waiting on pod/simple-app-657f9c8494-t2pw9 (v1) namespace: default
4:08:12PM:     ^ Pending: ContainerCreating
4:08:13PM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
4:08:13PM: ---- applying complete [2/2 done] ----
4:08:13PM: ---- waiting complete [2/2 done] ----

Succeeded

```

Let's check the value of `MSG_KEY` in the `simple-app` pods.
```bash
$kubectl get pods            
NAME                        READY   STATUS    RESTARTS   AGE
simple-app-657f9c8494-t2pw9   1/1     Running   0          99s

$kubectl exec -it simple-app-657f9c8494-t2pw9 sh
# echo $MSG_KEY
hello-carvel
# exit
#
```

Let's update the value of `hello_msg` to `hello-carvel-india` in configmap `simple-config` and re-deploy the app:
```bash
$kapp deploy -a app -f  app.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ update configmap/simple-config (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel
      2 +   hello_msg: hello-carvel-india
  3,  3   kind: ConfigMap
  4,  4   metadata:

Changes

Namespace  Name           Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    simple-config  ConfigMap  3d   update  -       reconcile  ok  -  

Op:      0 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y

4:16:22PM: ---- applying 1 changes [0/1 done] ----
4:16:22PM: update configmap/simple-config (v1) namespace: default
4:16:22PM: ---- waiting on 1 changes [0/1 done] ----
4:16:22PM: ok: reconcile configmap/simple-config (v1) namespace: default
4:16:22PM: ---- applying complete [1/1 done] ----
4:16:22PM: ---- waiting complete [1/1 done] ----

Succeeded
```

Now will verify again the value for `MSG_KEY` in the `simple-app` pods.

```bash
$kubectl get pods            
NAME                        READY   STATUS    RESTARTS   AGE
simple-app-657f9c8494-t2pw9   1/1     Running   0          6m40s

$kubectl exec -it simple-app-657f9c8494-t2pw9 sh
# echo $MSG_KEY
hello-carvel
# exit
#
```
Here, the value for env `MSG_KEY` is still not updated. To reflect the new changes of configmap we have to re-start the pod manually.

```bash
$kubectl delete pod simple-app-cc794fc5-2r2lm 
pod "simple-app-657f9c8494-t2pw9" deleted

$kubectl get pod 
NAME                          READY   STATUS    RESTARTS   AGE
simple-app-797ff748db-mqx97   1/1     Running   0          6s

$kubectl exec -it simple-app-797ff748db-mqx97 sh
# echo $MSG_KEY
hello-carvel-india
# 
```
After restarting the pod we can see the new changes we made in configmap.

In above example, we saw that to reflect the changes of a configmap we need to restart the pod manually.

## Versioned resource in `kapp`:

kapp provides a [solution](https://carvel.dev/kapp/docs/v0.49.0/diff/#versioned-resources) for such scenarios, by offering a way to create uniquely named resources based on an original resource. Whenever we make a change to a resource marked as versioned, entirely new resource will get created by the kapp instead of updating the existing one. Also, it will update the new name to the referencing resource and re-start them to reflect the new changes.

kapp has a concept of [versioned resources](https://carvel.dev/kapp/docs/v0.49.0/diff/#versioned-resources), where it creates a new version for resource whenever a change is made to it. To enable versioning we just need to add the annotation `kapp.k14s.io/versioned: ""` to the resource. Resources which are using this annotaion will follow the naming convention `{resource-name}-ver-{n}` where `n` will start with `1` and will get increamented by `1` after each update.

Let's try to use this annotation for the ConfigMap from our previous example and see what happens when we make a change to it.

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: simple-config
  annotations:
    kapp.k14s.io/versioned: ""
data:
  hello_msg: hello-carvel

---
apiVersion: apps/v1
kind: Deployment
...
```
Now deploy the updated manifest and see the changes.

```bash
$kapp deploy -a app -f  app.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/simple-config-ver-1 (v1) namespace: default @@
      0 + apiVersion: v1
      1 + data:
      2 +   hello_msg: hello-carvel-india
      3 + kind: ConfigMap
      4 + metadata:
      5 +   annotations:
      6 +     kapp.k14s.io/versioned: ""
      7 +   labels:
      8 +     kapp.k14s.io/app: "1655807854822326000"
      9 +     kapp.k14s.io/association: v1.de4bd280dda780c018846ab8dbccf4f0
     10 +   name: simple-config-ver-1
     11 +   namespace: default
     12 + 
@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
123,123                 key: hello_msg
124     -               name: simple-config
    124 +               name: simple-config-ver-1
125,125           image: nginx:1.21.6
126,126           name: simple-app
@@ delete configmap/simple-config (v1) namespace: default @@
  0     - apiVersion: v1
  1     - data:
  2     -   hello_msg: hello-carvel-india
  3     - kind: ConfigMap...
  
Changes

Namespace  Name                 Kind        Age  Op      Op st.  Wait to    Rs  Ri  
default    simple-app           Deployment  3d   update  -       reconcile  ok  -  
^          simple-config        ConfigMap   3d   delete  -       delete     ok  -  
^          simple-config-ver-1  ConfigMap   -    create  -       reconcile  -   -  

Op:      1 create, 1 delete, 1 update, 0 noop, 0 exists
Wait to: 2 reconcile, 1 delete, 0 noop

Continue? [yN]: y
```

As we have added annotation `kapp.k14s.io/versioned: ""` to configmap we can see a configmap with name `simple-config-ver-1` has been created. And `kapp` is updating deployment `simple-app` with new configmap name i.e. `simple-config-ver-1`.

The new set of resources in our `app`:

```bash
$kapp inspect -a app
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Resources in app 'app'

Namespace  Name                         Kind        Owner    Rs  Ri  Age  
default    simple-app                   Deployment  kapp     ok  -   3d  
^          simple-app-657f9c8494        ReplicaSet  cluster  ok  -   3d  
^          simple-app-79d8d56b8d        ReplicaSet  cluster  ok  -   3d  
^          simple-app-79d8d56b8d-tdszn  Pod         cluster  ok  -   3d  
^          simple-config-ver-1          ConfigMap   kapp     ok  -   3d  

Rs: Reconcile state
Ri: Reconcile information

5 resources

Succeeded
```

Let's verify the value for env `MSG_KEY` in the running pod of the deployment `simple-app`.

```bash
$kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
simple-app-5f94df997b-g76d9   1/1     Running   0          25s

$kubectl exec -it simple-app-5f94df997b-g76d9 sh
# 
# echo $MSG_KEY
hello-carvel-india
# 
```
The value for env `MSG_KEY` is same as we defined in configmap `simple-config`, so the changes got updated to deployment without restarting it's pod manually.

Let's update the value of `data.hello_msg` to `hello-tanzu` in configmap and redeploy the app `app` with the updated configmap. 
**Note:-** We will not make any changes to the deployment this time.


```bash
$kapp deploy -a app -f app.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/simple-config-ver-2 (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel-india
      2 +   hello_msg: hello-tanzu
  3,  3   kind: ConfigMap
  4,  4   metadata:
@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
123,123                 key: hello_msg
124     -               name: simple-config-ver-1
    124 +               name: simple-config-ver-2
125,125           image: nginx:1.21.6
126,126           name: simple-app

Changes

Namespace  Name                 Kind        Age  Op      Op st.  Wait to    Rs  Ri  
default    simple-app           Deployment  15h  update  -       reconcile  ok  -  
^          simple-config-ver-2  ConfigMap   -    create  -       reconcile  -   -  

Op:      1 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

1:12:16PM: ---- applying 1 changes [0/2 done] ----
1:12:16PM: create configmap/simple-config-ver-2 (v1) namespace: default
1:12:16PM: ---- waiting on 1 changes [0/2 done] ----
1:12:16PM: ok: reconcile configmap/simple-config-ver-2 (v1) namespace: default
1:12:16PM: ---- applying 1 changes [1/2 done] ----
1:12:17PM: update deployment/simple-app (apps/v1) namespace: default
1:12:17PM: ---- waiting on 1 changes [1/2 done] ----
1:12:17PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
1:12:17PM:  ^ Waiting for generation 4 to be observed
1:12:17PM:  L ok: waiting on replicaset/simple-app-6757478ff5 (apps/v1) namespace: default
1:12:17PM:  L ok: waiting on replicaset/simple-app-5f94df997b (apps/v1) namespace: default
1:12:17PM:  L ok: waiting on pod/simple-app-6757478ff5-xbq2c (v1) namespace: default
1:12:17PM:  L ongoing: waiting on pod/simple-app-5f94df997b-g76d9 (v1) namespace: default
1:12:17PM:     ^ Deleting
1:12:18PM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
1:12:18PM: ---- applying complete [2/2 done] ----
1:12:18PM: ---- waiting complete [2/2 done] ----

Succeeded
```

As already mentioned above, for the resource with annotations `kapp.k14s.io/versioned: ""` kapp will create entirely new resource on every update. Here also we can see kapp is creating a new resource for `configmap` with name `simple-config-ver-2` .
Also, kapp is updating the new configmap name to the deployment so that the new changes get reflected to the deployment as well.

The new set of resources in our `app`:
```bash
$kapp inspect -a app
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Resources in app 'app'

Namespace  Name                         Kind        Owner    Rs  Ri  Age  
default    simple-app                   Deployment  kapp     ok  -   15h  
^          simple-app-5f94df997b        ReplicaSet  cluster  ok  -   15h  
^          simple-app-6757478ff5        ReplicaSet  cluster  ok  -   15h  
^          simple-app-6757478ff5-xbq2c  Pod         cluster  ok  -   15h  
^          simple-config-ver-1          ConfigMap   kapp     ok  -   15h  
^          simple-config-ver-2          ConfigMap   kapp     ok  -   15h  

Rs: Reconcile state
Ri: Reconcile information

6 resources

Succeeded
```
If you look carefully the new set of resources having:
1. **two configmaps:** `simple-config-ver-1` with older changes and `simple-config-ver-2` with new changes
2. **two replicasets:**`simple-app-5f94df997b` with no running pods (older one, kapp deleted it's pod) and `simple-app-6757478ff5` with one running pod and it has the news chnages of configmap as well.

**From above two different examples of deploying resurces with `kubectl` and `kapp` we observed that to reflect the new changes of configmap in the deployment we have to manually delete the running pod in the case of `kubectl` while `kapp` does this for us by itself by marking resources as versioned.**


    
Annotation [kapp.k14s.io/versioned-keep-original](https://carvel.dev/kapp/docs/v0.49.0/diff/#versioned-resources) can be used in conjuction with the annotation `kapp.k14s.io/versioned` to create two type of resource for versioned resources.
1. **Original resource:** kapp will create resource with original name. And whenever new change will happen this resource will get updated as well.
2. **Versioned resourced:** kapp will create resource with the naming convention `<original_name>-ver-n` where `n` increament by `1` on every new update. On every new change a new resource will get created.

Example:
```yaml 
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-example
  annotations:
    kapp.k14s.io/versioned: ""
    kapp.k14s.io/versioned-keep-original: ""
data:
  hello_msg: hello-carvel
```
Will deploy it using `kapp` and see the changes:
```bash
$kapp deploy -a ver-app -f ver-config.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/config-example-ver-1 (v1) namespace: default @@
      0 + apiVersion: v1
      1 + data:
      2 +   hello_msg: hello-carvel
      3 + kind: ConfigMap
      4 + metadata:
      5 +   annotations:
      6 +     kapp.k14s.io/versioned: ""
      7 +     kapp.k14s.io/versioned-keep-original: ""
      8 +   labels:
      9 +     kapp.k14s.io/app: "1655729729870606000"
     10 +     kapp.k14s.io/association: v1.de4bd280dda780c018846ab8dbccf4f0
     11 +   name: simple-config-ver-1
     12 +   namespace: default
     13 + 
@@ create configmap/config-example (v1) namespace: default @@
      0 + apiVersion: v1
      1 + data:
      2 +   hello_msg: hello-carvel
      3 + kind: ConfigMap
      4 + metadata:
      5 +   annotations:
      6 +     kapp.k14s.io/versioned: ""
      7 +     kapp.k14s.io/versioned-keep-original: ""
      8 +   labels:
      9 +     kapp.k14s.io/app: "1655729729870606000"
     10 +     kapp.k14s.io/association: v1.de4bd280dda780c018846ab8dbccf4f0
     11 +   name: simple-config
     12 +   namespace: default
     13 + 

Changes

Namespace  Name                 Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    config-example        ConfigMap  -    create  -       reconcile  -   -  
^          config-example-ver-1  ConfigMap  -    create  -       reconcile  -   -  

Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

6:25:36PM: ---- applying 2 changes [0/2 done] ----
6:25:36PM: create configmap/config-example (v1) namespace: default
6:25:36PM: create configmap/config-example-ver-1 (v1) namespace: default
6:25:36PM: ---- waiting on 2 changes [0/2 done] ----
6:25:36PM: ok: reconcile configmap/config-example (v1) namespace: default
6:25:36PM: ok: reconcile configmap/config-example-ver-1 (v1) namespace: default
6:25:36PM: ---- applying complete [2/2 done] ----
6:25:36PM: ---- waiting complete [2/2 done] ----

Succeeded
```
As we have used annotation`kapp.k14s.io/versioned-keep-original: ""` with `kapp.k14s.io/versioned: ""`, kapp is creating both `original` with name `config-example` and `versioned` resource with name `config-example-ver-1`.

Let's make some change in `configmap` and re-deploy the app.

```bash
$kapp deploy -a ver-app -f ver-config.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/config-example-ver-2 (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel
      2 +   hello_msg: hello-carvel-india
  3,  3   kind: ConfigMap
  4,  4   metadata:
@@ update configmap/config-example (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel
      2 +   hello_msg: hello-carvel-india
  3,  3   kind: ConfigMap
  4,  4   metadata:

Changes

Namespace  Name                 Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    config-example        ConfigMap  3d   update  -       reconcile  ok  -  
^          config-example-ver-2  ConfigMap  -    create  -       reconcile  -   -  

Op:      1 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

6:33:40PM: ---- applying 2 changes [0/2 done] ----
6:33:40PM: create configmap/config-example-ver-2 (v1) namespace: default
6:33:40PM: update configmap/config-example (v1) namespace: default
6:33:40PM: ---- waiting on 2 changes [0/2 done] ----
6:33:40PM: ok: reconcile configmap/config-example-ver-2 (v1) namespace: default
6:33:40PM: ok: reconcile configmap/config-example (v1) namespace: default
6:33:40PM: ---- applying complete [2/2 done] ----
6:33:40PM: ---- waiting complete [2/2 done] ----

Succeeded
```
Kapp is updating the new changes in original resource and creating new versioned resource as well. 

**Use case:** Assume a versioned resource is being referenced by a resource `res1` which is owned by `kapp` and another resource `res2` which is not owned by `kapp`. In this case having both `original` and `versioned resource` is necessary as `res1` can use versioned resources while `res2` can continue with original one.

### Automatic update to non-workload reasources 

*On every update to a `versioned` resources `kapp` re-start only those resources which are refrencing `versioned` resources and are built-in [workload resources](https://kubernetes.io/docs/concepts/workloads/).*

For resources which are not part of built-in `workload resources` can use annotaion [kapp.k14s.io/versioned-explicit-ref](https://carvel.dev/kapp/docs/v0.49.0/diff/#versioned-resources) to have explicit relationship with `versioned` resources if you want them to automatic re-start whenever there is a change in versioned resources.

Let's play with some example:
```yaml 
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: crd-config
  annotations:
    kapp.k14s.io/versioned: ""
data:
  hello_msg: hello-carvel-india

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: simplecrds.example.com
spec:
  group: example.com
  versions:
    - name: v1beta1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                name:
                  type: string
                image:
                  type: string
  scope: Namespaced
  names:
    kind: simplecrd
    plural: simplecrds	

---
apiVersion: "example.com/v1beta1"
kind: simplecrd
metadata:
  name: first-cr
spec:
  name: simple-app
  image: nginx:1.21.6
```

Let's deploy them using `kapp`:
```bash
$kapp deploy -a crd-app -f version-crd.yaml                           
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Changes

Namespace  Name                    Kind                      Age  Op      Op st.  Wait to    Rs  Ri  
(cluster)  simplecrds.example.com  CustomResourceDefinition  -    create  -       reconcile  -   -  
default    crd-config-ver-1        ConfigMap                 -    create  -       reconcile  -   -  
^          first-cr                simplecrd                 -    create  -       reconcile  -   -  

Op:      3 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 3 reconcile, 0 delete, 0 noop

Continue? [yN]: y

5:18:05PM: ---- applying 2 changes [0/3 done] ----
5:18:05PM: create configmap/crd-config-ver-1 (v1) namespace: default
5:18:06PM: create customresourcedefinition/simplecrds.example.com (apiextensions.k8s.io/v1) cluster
5:18:06PM: ---- waiting on 2 changes [0/3 done] ----
5:18:06PM: ok: reconcile customresourcedefinition/simplecrds.example.com (apiextensions.k8s.io/v1) cluster
5:18:06PM: ok: reconcile configmap/crd-config-ver-1 (v1) namespace: default
5:18:06PM: ---- applying 1 changes [2/3 done] ----
5:18:08PM: create simplecrd/first-cr (example.com/v1beta1) namespace: default
5:18:08PM: ---- waiting on 1 changes [2/3 done] ----
5:18:08PM: ok: reconcile simplecrd/first-cr (example.com/v1beta1) namespace: default
5:18:08PM: ---- applying complete [3/3 done] ----
5:18:08PM: ---- waiting complete [3/3 done] ----

Succeeded
```
Let's update the value of `data.hello_msg` to `hello-carvel` in configmap `crd-config` and redeploy the app `crd-app` with the updated configmap.

```bash
$kapp deploy -a crd-app -f version-crd.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/crd-config-ver-2 (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel-india
      2 +   hello_msg: hello-carvel
  3,  3   kind: ConfigMap
  4,  4   metadata:

Changes

Namespace  Name              Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    crd-config-ver-2  ConfigMap  -    create  -       reconcile  -   -  

Op:      1 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]:y

5:34:49PM: ---- applying 1 changes [0/1 done] ----
5:34:49PM: create configmap/crd-config-ver-2 (v1) namespace: default
5:34:49PM: ---- waiting on 1 changes [0/1 done] ----
5:34:49PM: ok: reconcile configmap/crd-config-ver-2 (v1) namespace: default
5:34:49PM: ---- applying complete [1/1 done] ----
5:34:49PM: ---- waiting complete [1/1 done] ----

Succeeded
```


Now what we want is whenever there is any change happen in configmap `crd-config` the custom resource `first-cr` should get updated or restarted. To achive this we have to add annotation `kapp.k14s.io/versioned-explicit-ref:` to the custom resource so that on every update in configmap `crd-config` kapp will make update to custom resource as well.

After adding `kapp.k14s.io/versioned-explicit-ref:` to custom resource `first-cr`, it will be something like:
```yaml
apiVersion: "example.com/v1beta1"
kind: simplecrd
metadata:
  name: first-cr
  annotations:
    kapp.k14s.io/versioned-explicit-ref: |
      apiVersion: v1
      kind: ConfigMap
      name: crd-config
spec:
  name: simple-app
  image: nginx:1.21.6
```

Let's deploy the new YAML and see the difference.
```bash
$kapp deploy -a crd-app -f version-crd.yaml               
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Changes

Namespace  Name      Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    first-cr  simplecrd  3d   update  -       reconcile  ok  -  

Op:      0 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y

5:41:59PM: ---- applying 1 changes [0/1 done] ----
5:41:59PM: update simplecrd/first-cr (example.com/v1beta1) namespace: default
5:41:59PM: ---- waiting on 1 changes [0/1 done] ----
5:41:59PM: ok: reconcile simplecrd/first-cr (example.com/v1beta1) namespace: default
5:41:59PM: ---- applying complete [1/1 done] ----
5:41:59PM: ---- waiting complete [1/1 done] ----

Succeeded
```

Let's update the value of `data.hello_msg` to `hello-tanzu` in configmap `crd-config` and re-deploy the app `crd-app` with the updated configmap.

```bash
$kapp deploy -a app1 -f version-crd.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/crd-config-ver-3 (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel
      2 +   hello_msg: hello-tanzu
  3,  3   kind: ConfigMap
  4,  4   metadata:
@@ update simplecrd/first-cr (example.com/v1beta1) namespace: default @@
  ...
  6,  6         kind: ConfigMap
  7     -       name: crd-config-ver-2
      7 +       name: crd-config-ver-3
  8,  8     creationTimestamp: "2022-06-17T22:34:53Z"
  9,  9     generation: 1

Changes

Namespace  Name              Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    crd-config-ver-3  ConfigMap  -    create  -       reconcile  -   -  
^          first-cr          simplecrd  3d   update  -       reconcile  ok  -  

Op:      1 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

5:43:10PM: ---- applying 1 changes [0/2 done] ----
5:43:10PM: create configmap/crd-config-ver-3 (v1) namespace: default
5:43:10PM: ---- waiting on 1 changes [0/2 done] ----
5:43:10PM: ok: reconcile configmap/crd-config-ver-3 (v1) namespace: default
5:43:10PM: ---- applying 1 changes [1/2 done] ----
5:43:10PM: update simplecrd/first-cr (example.com/v1beta1) namespace: default
5:43:10PM: ---- waiting on 1 changes [1/2 done] ----
5:43:10PM: ok: reconcile simplecrd/first-cr (example.com/v1beta1) namespace: default
5:43:10PM: ---- applying complete [2/2 done] ----
5:43:10PM: ---- waiting complete [2/2 done] ----

Succeeded
```

After adding annotion `kapp.k14s.io/versioned-explicit-ref:` to the custom resource `first-cr`, kapp is able to make update to it when there is any new changes in configmap `crd-config`.



## Join us on Slack and GitHub

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.