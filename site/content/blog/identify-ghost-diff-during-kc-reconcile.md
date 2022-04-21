---
title: "Identify ghost diff during kapp Controller reconciliation"
slug: identify-ghost-diff-during-kapp-controller-reconciliation
date: 2022-04-21
author: Rohit Aggarwal
excerpt: "Identify ghost diff during kapp Controller reconciliation "
image: /img/logo.svg
tags: ['carvel', 'kapp-controller', 'gitops', 'diffs', 'diff']
---

# Identify ghost diff during kapp Controller reconciliation

[kapp controller](https://carvel.dev/kapp-controller/), a Package manager, is compatible with Gitops philosophy. It is continuously ensuring that the cluster is or converging towards the desired state. It does so by running the reconciliation loop after every `syncPeriod` duration. In each reconciliation cycle, it monitors the current state of the resources on the cluster and tries to bring it to the desired state if there is any mismatch. It does so with the help of [kapp](https://carvel.dev/kapp/). 

kapp, another carvel tool, performs a diff by comparing `current state` of the resource on the cluster with the `desired state` during a `deploy` or `delete`. The desired state is provided via manifest. If the user wants to change the resource, they should update the manifest and redeploy using kapp. It is not a good practice to update the deployed resource directly on the cluster. 

## What are `ghost` diffs

However, sometimes some resources can get updated on the cluster by controller, operator, mutating Webhook, etc. These changes are not explicitly requested. Since these updates are dynamically added to a resource on the cluster, kapp is unaware of them. In the subsequent `kapp deploy`, kapp will see these updates as divergence from the desired state. Diffs arising out of it is what we call as `ghost` diffs. For example, based on load, `HorizontalPodAutoscalar` can increase the no. of replicas for a deployment. Thus your actual replicas will be different from what is specified in the deployment manifest.

#### Why we should avoid 

Everytime a diff is detected, kapp creates a new configMap to track [app-change](https://carvel.dev/kapp/docs/latest/state-namespace/#app-changes) history. These configmaps store the exit status and summary of operations( e.g. no. of updated/deleted/created resources) performed in that `kapp deploy`. If packages create `ghost` diffs in the Kubernetes(K8s) cluster, we will end up with large no. of configMaps. Good news is kapp allows you to cap (default 200) the number of app-changes to be stored. 

#### How to resolve 

To avoid these diffs from appearing, users can add [rebase rules](https://carvel.dev/kapp/docs/latest/config/#rebaserules) to specify exactly what information to retain from current state of deployed resource. Read more about why kapp made a consicious decision to avoid 3 way merge [here](https://carvel.dev/kapp/docs/latest/merge-method/)

## Detection and Resolution in Packages

Since Package consumers are aware of the `Package` configuration only, it becomes difficult for them to identify which part of the underlying resource configuration is causing these diffs.

In this blog, we will see how to identify the resources causing these ghost diffs and also what part of their configuration is participating in it.

#### Prerequisites

* carvel tool set
* Kubernetes cluster(I'm using minikube)

Ensure that kapp-controller is installed on your K8s cluster. Since this blog will be using `HorizontalPodAutoscaler`, we have to enable `metrics-server` on minikube.

```bash
$ minikube addons enable metrics-server
    ▪ Using image k8s.gcr.io/metrics-server/metrics-server:v0.4.2
  The 'metrics-server' addon is enabled
```

I will be using [kctrl](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) to interact with `kapp-controller` resources. 

#### Install the Package

For the purpose of this blog, I have already created a Carvel package `simple-app-package`. This package is part of the package repository `my-pkg-repo`.  If you are interested in how to create package and package repository, I would recommend to go over [packaging-tutorial](https://carvel.dev/kapp-controller/docs/latest/packaging-tutorial/).

First, we need to install the package repository. 

```bash
$ kctrl package repository add -r demo-pkg-repo --url docker.io/rohitagg2020/my-pkg-repo:1.0.0
Target cluster 'https://192.168.64.82:8443' (nodes: minikube)

Waiting for package repository to be added

1:38:45PM: packagerepository/demo-pkg-repo (packaging.carvel.dev/v1alpha1) namespace: default: Reconciling
1:38:50PM: packagerepository/demo-pkg-repo (packaging.carvel.dev/v1alpha1) namespace: default: ReconcileSucceeded

Succeeded
```

Once the package repository is installed, we can check the list of available packages.
```bash
$ kctrl package available list --summary=false
Target cluster 'https://192.168.64.82:8443' (nodes: minikube)

Available packages in namespace 'default'

Name                 Version  Released at
simple-app.corp.com  1.0.0    0001-01-01 00:00:00 +0000 UTC

Succeeded
```

Let's install the package.

```bash
$ kctrl package install -i pkg-demo -p simple-app.corp.com --version 1.0.0
Target cluster 'https://192.168.64.82:8443' (nodes: minikube)

Creating service account 'pkg-demo-default-sa'
Creating cluster admin role 'pkg-demo-default-cluster-role'
Creating cluster role binding 'pkg-demo-default-cluster-rolebinding'
Creating package install resource
Waiting for PackageInstall reconciliation for 'pkg-demo'

1:40:20PM: packageinstall/pkg-demo (packaging.carvel.dev/v1alpha1) namespace: default: Reconciling
1:40:30PM: packageinstall/pkg-demo (packaging.carvel.dev/v1alpha1) namespace: default: ReconcileSucceeded

Succeeded
```

After the deploy has finished, kapp-controller would have installed the package in the cluster. We can verify this by checking the pods to see that we have a workload pod running. The output should show two running pods which is part of simple-app:

```bash
$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
simple-app-8648457765-8jtpq   1/1     Running   0          56s
simple-app-8648457765-p5lzp   1/1     Running   0          56s
```

#### Identify ghost diffs exist or not

In our package, we have set `syncPeriod` to 10 min. This means after every 10 min, kapp controller will try to reconcile the package. kapp creates a configmap every time it sees that there are some resources that needs to be redeployed. Thus, if we see new configmaps appearing, it means ghost diffs are being generated. To identify the configmaps related to an installed package, we have to look at the configmap with installed package Prefix. Let's check the configmaps.

```bash 
$ kubectl get configmaps | grep pkg-demo
pkg-demo-ctrl                     1      1m40s
pkg-demo-ctrl-change-ndr7w        1      1m40s
```

Lets do the same after 10 min of package installation, so that reconcilliation cycle would have run once. 

```bash
$ kubectl get configmaps | grep pkg-demo
pkg-demo-ctrl                     1      12m
pkg-demo-ctrl-change-ndr7w        1      12m
pkg-demo-ctrl-change-t7zgc        1      56s
```
We can see that one more configmap is generated. If I check the configmap content, I can see that there has been one update, but I don't know which resource got updated and what is causing this update. 

```bash
$ kubectl get configmap pkg-demo-ctrl-change-t7zgc -oyaml
apiVersion: v1
data:
  spec: '{"startedAt":"2022-04-14T08:21:28.264641525Z","finishedAt":"2022-04-14T08:21:32.42972746Z","successful":true,"description":"update:
    Op: 0 create, 0 delete, 1 update, 0 noop, 0 exists / Wait to: 1 reconcile, 0 delete,
    0 noop","namespaces":["default"]}'
kind: ConfigMap
...
```

As a package consumer, I can see that there are ghost diff's appearing. 

#### Identify actual configuration causing the diffs

To identify what is causing them, we will make a copy of the package. We will modify the deploy section of the package. It will help us to get the configuration applied by `kapp`. Let's start:

```bash
$ kubectl get pkg simple-app.corp.com.1.0.0 -oyaml > copy-simple-app-package.yaml
```

Open copy-simple-app-package.yaml. Remove labels starting with `kapp`. Add the below snippet to the kapp section. Setting the `diff-changes` to true will enable the `kapp` to show changes.
```
...
- kapp:
    rawOptions:
    - --diff-changes=true
...
```

I would recommend not to tinker with the original package. Hence, let's change the package version. Lets change it from 1.0.0 to 2.0.0. Specifically, update in the `spec.version` and `metadata.name`. Now, apply this package in the cluster so that it will be available for install.

```bash 
$ kubectl apply -f copy-simple-app-package.yaml
package.data.packaging.carvel.dev/simple-app.corp.com.2.0.0 created
```

Now, if we will see list of available packages, we can see our locally created package as well. 

```bash
$ kctrl package available list --summary=false
Target cluster 'https://192.168.64.82:8443' (nodes: minikube)

Available packages in namespace 'default'

Name                 Version  Released at
simple-app.corp.com  1.0.0    0001-01-01 00:00:00 +0000 UTC
simple-app.corp.com  2.0.0    0001-01-01 00:00:00 +0000 UTC

Succeeded
```

Let's update the package to the version `2.0.0`

```bash
$ kctrl package installed update -i pkg-demo -p simple-app.corp.com --version 2.0.0
Target cluster 'https://192.168.64.84:8443' (nodes: minikube)

Getting package install for 'pkg-demo'
Updating package install for 'pkg-demo'
Waiting for PackageInstall reconciliation for 'pkg-demo'

11:31:28AM: packageinstall/pkg-demo (packaging.carvel.dev/v1alpha1) namespace: default: ReconcileSucceeded

Succeeded
```

After the package is deployed successfully, let's see what the initial configuration of the resources looks like. We can get that by describing [App](https://carvel.dev/kapp-controller/docs/latest/app-overview/#app) linked to the package. Similar to configmap, the package creates `App` with the same name as its name. As the output is long, I have added only a small snippet.

```bash
$ kubectl describe app pkg-demo
...
@@ create deployment/simple-app (apps/v1) namespace: default @@
      0 + apiVersion: apps/v1
      1 + kind: Deployment
      2 + metadata:
      3 +   annotations:
      4 +     kbld.k14s.io/images: |
      5 +       - origins:
      6 +         - preresolved:
      7 +             url: index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
      8 +         url: index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
      9 +   labels:
     10 +     kapp.k14s.io/app: "1649925743708215040"
     11 +     kapp.k14s.io/association: v1.22a4cbb25c518f776737777e8407b8d9
     12 +   name: simple-app
     13 +   namespace: default
     14 + spec:
     15 +   progressDeadlineSeconds: 600
     16 +   replicas: 2
     17 +   revisionHistoryLimit:
...
```

You will see that it is creating a deployment, service and HPA.

Let the reconcilliation loop run once. After the reconcilliation loop is run, we will see that another configmap has been generated. Now, if we will run `app describe` again, we will see the exact diff.

```bash
$ kubectl get configmaps | grep pkg-demo
pkg-demo-ctrl                     1      12m
pkg-demo-ctrl-change-4vpdq        1      2m24s
pkg-demo-ctrl-change-rnjxf        1      12m

$ kubectl describe app pkg-demo
...
Status:
  Conditions:
    Status:                         True
    Type:                           ReconcileSucceeded
  Consecutive Reconcile Successes:  2
  Deploy:
    Exit Code:   0
    Finished:    true
    Started At:  2022-04-14T08:52:35Z
    Stdout:      Target cluster 'https://10.96.0.1:443' (nodes: minikube)
@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
125,125     progressDeadlineSeconds: 600
126     -   replicas: 1
    126 +   replicas: 2
127,127     revisionHistoryLimit: 10
128,128     selector:
Changes
Namespace  Name        Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  2/2 t   10m  update  -       reconcile  ok  -
Op:      0 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop
...
```

Here, as we can see, the change in the number of replicas has resulted in the creation of ghost diffs. This is because HPA has reduced the no. of Replicas since there is no load on the server.

Note: There is already an opened [issue](https://github.com/vmware-tanzu/carvel-kapp/issues/338) in kapp which will allow users to view the diff information by running `app-change`. Once it is available, users can directly see the diff information in the config map and they can skip the whole process of creating a new package and adding `diff-changes=true` to kapp.

This is how a Package consumer can discover the reason for ghost diffs and take appropriate action. In this case, adding a [rebase rule](https://carvel.dev/kapp/docs/latest/hpa-deployment-rebase/#docs) will remove the ghost diffs.



## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30 am PT / 1:30 pm ET. Check out the [Community page](/community/) for full details on how to attend.
