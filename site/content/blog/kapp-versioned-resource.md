---
title: "Updating resources automatically when their referenced resources are updated"
slug: updating-resources-automatically-when-their-referenced-resources-are-updated
date: 2022-06-30
author: Kumari Tanushree
excerpt: "In this blog, we are going to learn how to use kapp to automatically re-start or re-deploy the resources when their referenced resources get updated."
image: /img/logo.svg
tags: ['carvel', 'kapp', 'versioned-resource']

---

Have you ever wanted your deployments or pods to automatically get redeployed when their referenced ConfigMaps or secrets are updated?

In this blog, we are going to learn how to use [kapp](https://carvel.dev/kapp/) to re-start or re-deploy the resources when their referenced resources get updated.

## Deploy resources where one resource is being referenced by other

Let's consider a ConfigMap and a deployment, where the ConfigMap is being referenced by the deployment.
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
        image: docker.io/dkalinin/k8s-simple-app:latest
        env:
          - name: MSG_KEY
            valueFrom:
              configMapKeyRef:
                 name: simple-config
                 key: hello_msg
```
 
Let's deploy them to the cluster using `kapp`.

```bash
$ kapp deploy -a app -f app.yaml
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Changes

Namespace  Name           Kind        Age  Op      Op st.  Wait to    Rs  Ri  
default    simple-app     Deployment  -    create  -       reconcile  -   -  
^          simple-config  ConfigMap   -    create  -       reconcile  -   -  

Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y
```

Let's check the value of environment variable `MSG_KEY` in the running pod of deployment `simple-app`.
```bash
$ kubectl get pods            
NAME                        READY   STATUS    RESTARTS   AGE
simple-app-657f9c8494-t2pw9   1/1     Running   0          99s

$ kubectl exec -it simple-app-657f9c8494-t2pw9 sh
# echo $MSG_KEY
hello-carvel
# exit
#
```

Let's update the value of `data.hello_msg ` to `hello-kapp` in ConfigMap `simple-config` and re-deploy the app:
```bash
$ kapp deploy -a app -f app.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ update configmap/simple-config (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel
      2 +   hello_msg: hello-kapp
  3,  3   kind: ConfigMap
  4,  4   metadata:

Changes

Namespace  Name           Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    simple-config  ConfigMap  3d   update  -       reconcile  ok  -  

Op:      0 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y
```

Now let's verify again the value of environment variable `MSG_KEY` in the running pod of deployment `simple-app`.

```bash
$ kubectl get pods            
NAME                        READY   STATUS    RESTARTS   AGE
simple-app-657f9c8494-t2pw9   1/1     Running   0          6m40s

$ kubectl exec -it simple-app-657f9c8494-t2pw9 sh
# echo $MSG_KEY
hello-carvel
# exit
#
```
Here, the value of environment variable `MSG_KEY` is still not updated. To reflect the new changes of ConfigMap we have to re-start the pod manually.

```bash
$ kubectl delete pod simple-app-657f9c8494-t2pw9 
pod "simple-app-657f9c8494-t2pw9" deleted

$ kubectl get pod 
NAME                          READY   STATUS    RESTARTS   AGE
simple-app-797ff748db-mqx97   1/1     Running   0          6s

$ kubectl exec -it simple-app-797ff748db-mqx97 sh
# echo $MSG_KEY
hello-kapp
# 
```
After restarting the pod we can see the new changes we made in ConfigMap.

In above example, we saw that to reflect the changes of a ConfigMap we need to restart the pod manually.

## Versioned resource in `kapp`

Kapp has a concept of [versioned resources](https://carvel.dev/kapp/docs/v0.49.0/diff/#versioned-resources), where it creates a new version for resource whenever a change is made to it. To enable versioning we just need to add the annotation `kapp.k14s.io/versioned: ""` to the resource. Resources which are using this annotation will follow the naming convention `{resource-name}-ver-{n}` where `n` will start with `1` and will get incremented by `1` on every update.

Whenever we make a change to a resource marked as versioned, an entirely new resource will get created by kapp instead of updating the existing one. Also, it will update the new name to the referencing resource and re-start them to reflect the new changes.

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
  hello_msg: hello-kapp

---
apiVersion: apps/v1
kind: Deployment
...
```
Now deploy the updated manifest and see the changes.

```bash
$ kapp deploy -a app -f app.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/simple-config-ver-1 (v1) namespace: default @@
      0 + apiVersion: v1
      1 + data:
      2 +   hello_msg: hello-kapp
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
125,125           image: docker.io/dkalinin/k8s-simple-app:latest
126,126           name: simple-app
@@ delete configmap/simple-config (v1) namespace: default @@
  0     - apiVersion: v1
  1     - data:
  2     -   hello_msg: hello-kapp
  3     - kind: ConfigMap
  4     - metadata:
  5     -   creationTimestamp: "2022-06-17T21:19:07Z"
  6     -   labels:
  7     -     kapp.k14s.io/app: "1655807854822326000"
  8     -     kapp.k14s.io/association: v1.de4bd280dda780c018846ab8dbccf4f0
  9     -   managedFields:
 10     -   - apiVersion: v1
 11     -     fieldsType: FieldsV1
 12     -     fieldsV1:
 13     -       f:data:
 14     -         .: {}
 15     -         f:hello_msg: {}
 16     -       f:metadata:
 17     -         f:annotations:
 18     -           .: {}
 19     -           f:kapp.k14s.io/identity: {}
 20     -           f:kapp.k14s.io/original: {}
 21     -           f:kapp.k14s.io/original-diff-md5: {}
 22     -         f:labels:
 23     -           .: {}
 24     -           f:kapp.k14s.io/app: {}
 25     -           f:kapp.k14s.io/association: {}
 26     -     manager: kapp
 27     -     operation: Update
 28     -     time: "2022-06-17T21:27:59Z"
 29     -   name: simple-config
 30     -   namespace: default
 31     -   resourceVersion: "102821"
 32     -   uid: c45dc89e-2eea-4c2a-800d-2513d94246c7
 33     - 

  
Changes

Namespace  Name                 Kind        Age  Op      Op st.  Wait to    Rs  Ri  
default    simple-app           Deployment  3d   update  -       reconcile  ok  -  
^          simple-config        ConfigMap   3d   delete  -       delete     ok  -  
^          simple-config-ver-1  ConfigMap   -    create  -       reconcile  -   -  

Op:      1 create, 1 delete, 1 update, 0 noop, 0 exists
Wait to: 2 reconcile, 1 delete, 0 noop

Continue? [yN]: y
```

As we have added annotation `kapp.k14s.io/versioned: ""` to ConfigMap we can see ConfigMap `simple-config` is getting deleted and a new resource with name `simple-config-ver-1` has been created. Also `kapp` is updating deployment `simple-app` with new ConfigMap name i.e. `simple-config-ver-1`.


Let's verify the value of environment variable `MSG_KEY` in the running pod of the deployment `simple-app`.

```bash
$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
simple-app-5f94df997b-g76d9   1/1     Running   0          25s

$ kubectl exec -it simple-app-5f94df997b-g76d9 sh
# 
# echo $MSG_KEY
hello-kapp
# 
```
The value of environment variable `MSG_KEY` is same as we defined in ConfigMap `simple-config`, so the changes got updated to the deployment without restarting it's pod manually.

Let's update the value of `data.hello_msg` to `hello-tanzu` in ConfigMap and redeploy the app `app` with the updated ConfigMap.


```bash
$ kapp deploy -a app -f app.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/simple-config-ver-2 (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-kapp
      2 +   hello_msg: hello-tanzu
  3,  3   kind: ConfigMap
  4,  4   metadata:
@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
123,123                 key: hello_msg
124     -               name: simple-config-ver-1
    124 +               name: simple-config-ver-2
125,125           image: docker.io/dkalinin/k8s-simple-app:latest
126,126           name: simple-app

Changes

Namespace  Name                 Kind        Age  Op      Op st.  Wait to    Rs  Ri  
default    simple-app           Deployment  15h  update  -       reconcile  ok  -  
^          simple-config-ver-2  ConfigMap   -    create  -       reconcile  -   -  

Op:      1 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y
```
The new set of resources in our `app`:
```bash
$ kapp inspect -a app
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

**Two ConfigMaps:** `simple-config-ver-1` with older changes and `simple-config-ver-2` with new changes.

**From above two different examples of deploying `non-versioned resources` and `versioned resources`, we observed that to reflect the new changes of ConfigMap in the deployment we have to manually delete the running pod in the case of `non-versioned resources` while `kapp` does this for us by itself in the case of `versioned resources`.**


    
Annotation [kapp.k14s.io/versioned-keep-original](https://carvel.dev/kapp/docs/v0.49.0/diff/#versioned-resources) can be used in conjuction with the annotation `kapp.k14s.io/versioned` to create two type of resource for versioned resources.
1. **Versioned resource:** kapp will create resource with the naming convention `<original_name>-ver-n` where `n` increament by `1` on every new update. On every new change a new resource will get created.
2. **Original resource:** kapp will create resource with original name. And whenever new change will happen this resource will get updated as well.


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
$ kapp deploy -a ver-app -f ver-config.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Changes

Namespace  Name                  Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    config-example        ConfigMap  -    create  -       reconcile  -   -  
^          config-example-ver-1  ConfigMap  -    create  -       reconcile  -   -  

Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y
```
As we have used annotation`kapp.k14s.io/versioned-keep-original: ""` with `kapp.k14s.io/versioned: ""`, kapp is creating both `original` with name `config-example` and `versioned` resource with name `config-example-ver-1`.

Let's make some change in `ConfigMap` and re-deploy the app.

```bash
$ kapp deploy -a ver-app -f ver-config.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/config-example-ver-2 (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel
      2 +   hello_msg: hello-kapp
  3,  3   kind: ConfigMap
  4,  4   metadata:
@@ update configmap/config-example (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-carvel
      2 +   hello_msg: hello-kapp
  3,  3   kind: ConfigMap
  4,  4   metadata:

Changes

Namespace  Name                 Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    config-example        ConfigMap  3d   update  -       reconcile  ok  -  
^          config-example-ver-2  ConfigMap  -    create  -       reconcile  -   -  

Op:      1 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y
```
Kapp is updating the new changes in original resource and creating new versioned resource as well. 

### Automatic update to resources by having explicit reference of versioned resource

*On every update to a `versioned` resources `kapp` re-start only those resources which are refrencing `versioned` resources and are listed under default rule set in `kapp` ([workload resources](https://kubernetes.io/docs/concepts/workloads/)).*

For resources which are not part of default rule set of `kapp` can use annotaion [kapp.k14s.io/versioned-explicit-ref](https://carvel.dev/kapp/docs/v0.49.0/diff/#versioned-resources) to have explicit relationship with `versioned` resources if you want them to automatic re-start whenever there is a change in versioned resources.

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
  hello_msg: hello-kapp

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
  image: docker.io/dkalinin/k8s-simple-app:latest
```

Let's deploy them using `kapp`:
```bash
$ kapp deploy -a crd-app -f version-crd.yaml                           
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Changes

Namespace  Name                    Kind                      Age  Op      Op st.  Wait to    Rs  Ri  
(cluster)  simplecrds.example.com  CustomResourceDefinition  -    create  -       reconcile  -   -  
default    crd-config-ver-1        ConfigMap                 -    create  -       reconcile  -   -  
^          first-cr                simplecrd                 -    create  -       reconcile  -   -  

Op:      3 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 3 reconcile, 0 delete, 0 noop

Continue? [yN]: y
```
Let's update the value of `data.hello_msg` to `hello-carvel` in ConfigMap `crd-config` and redeploy the app `crd-app`.

```bash
$ kapp deploy -a crd-app -f version-crd.yaml --diff-changes
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

@@ create configmap/crd-config-ver-2 (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   hello_msg: hello-kapp
      2 +   hello_msg: hello-carvel
  3,  3   kind: ConfigMap
  4,  4   metadata:

Changes

Namespace  Name              Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    crd-config-ver-2  ConfigMap  -    create  -       reconcile  -   -  

Op:      1 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]:y
```


Now what we want is whenever there is any change happen in ConfigMap `crd-config` the custom resource `first-cr` should get updated or restarted. To achieve this we have to add annotation `kapp.k14s.io/versioned-explicit-ref` to the custom resource so that on every update in ConfigMap `crd-config` kapp will make update to custom resource as well.

After adding `kapp.k14s.io/versioned-explicit-ref` to custom resource `first-cr`, it will be something like:
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
  image: docker.io/dkalinin/k8s-simple-app:latest
```

Let's deploy updated YAML `version-crd.yaml`.
```bash
$ kapp deploy -a crd-app -f version-crd.yaml               
Target cluster 'https://127.0.0.1:33907' (nodes: minikube)

Changes

Namespace  Name      Kind       Age  Op      Op st.  Wait to    Rs  Ri  
default    first-cr  simplecrd  3d   update  -       reconcile  ok  -  

Op:      0 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y
```

Let's update the value of `data.hello_msg` to `hello-tanzu` in ConfigMap `crd-config` and re-deploy the app `crd-app`.

```bash
$ kapp deploy -a app1 -f version-crd.yaml --diff-changes
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
```

After adding annotion `kapp.k14s.io/versioned-explicit-ref` to the custom resource `first-cr`, kapp is able to make update to it whenever there is any new changes in ConfigMap `crd-config`.

Congratulations! We now know how we can leverage `kapp` to manage inter-dependent resources better and help us get more done declaratively.

{{< blog_footer >}}