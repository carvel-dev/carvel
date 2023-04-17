---
title: "Getting to know App resources better with kctrl"
slug: kcrl-app-commands-blog
date: 2022-05-05
author: Soumik Majumder
excerpt: "Get better visibility into your app resources with kctrl's new app commands and enhancements to the package commands"
image: /img/kapp-controller.svg
tags: ['carvel', 'kapp-controller', 'gitops', 'apps', 'kctrl', 'cli']
---

Since the previous release of `kctrl`, we have been iterating over how we can help users take a closer look at what App CRs are doing on the cluster. This includes ones authored by users and those that are created as a result of package installations.

As promised, the latest release of `kctrl` introduces a set of commands which allow users to observe and interact with App CRs more conveniently. [`kctrl` v0.36.1](https://github.com/carvel-dev/kapp-controller/releases/tag/v0.36.1) also introduces a status tailing experience which surfaces relevant information while waiting for resources to reconcile.

# The `app` commands
These commands aim to help users manage App CRs on the cluster better. Lets dig in and see what they look like!

The user can list apps created on the cluster by running,
```bash
$ kctrl app list
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

Available apps in namespace 'default'

Name        Status               Since Deploy  Owner                     Age  
hello-app   Reconcile succeeded  1m            PackageInstall/hello-app  1m  
simple-app  Reconcile succeeded  22s           -                         1m  

Succeeded
```
`kctrl` makes a distinction between App CRs deployed by users and the ones created due to a package installation. 

We can take a closer look at an app by using the `get` command.
```bash
$ kctrl app get -a simple-app
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

Namespace         default  
Name              hello-app  
Service Account   hello-app-default-sa  
Status            Reconcile succeeded  
Owner References  - packaging.carvel.dev/v1alpha1/PackageInstall/hello-app  
Conditions        - type: ReconcileSucceeded  
                    status: "True"  
                    reason: ""  
                    message: ""  

Succeeded
```
In case the app errors out, the command displays relevant errors. For instance, an app which is applying a resource with a misspelt "kind" field looks like:
```bash
$ kctrl app get -a faulty-app
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

Namespace             default  
Name                  faulty-app  
Service Account       default-ns-sa  
Status                Reconcile failed: Deploying: Error (see .status.usefulErrorMessage for details)  
Owner References      -  
Conditions            - type: ReconcileFailed  
                        status: "True"  
                        reason: ""  
                        message: 'Deploying: Error (see .status.usefulErrorMessage for details)'  
Failing Stage         deploy  
Useful Error Message  kapp: Error: Expected to find kind '/v1/ConfigMaps', but did not:  
                      - Kubernetes API server did not have matching apiVersion + kind  
                      - No matching CRD was found in given configuration  

Succeeded
```
It highlights that the deploy stage failed, while displaying the error message.

The `pause` and `kick` commands help users pause and trigger reconciliations for their apps.

Pausing an app stops reconciliation for that particular app, which means that kapp-controller will not try to periodically reconcile the app to ensure the desired state on the cluster.
```bash
$ kctrl app pause -a simple-app
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

Pausing reconciliation for App 'simple-app' in namespace 'default'
Continue? [yN]: y

Pausing reconciliation for App 'simple-app' in namespace 'default'

Succeeded
```
On the other hand, the `kick` command triggers a reconciliation for the App CR without waiting for the sync period to elapse.
```bash
./kctrl app kick -a simple-app                                                                                                                                                                                           ─╯
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

Triggering reconciliation for app 'simple-app' in namespace 'default'
Continue? [yN]: y

2:46:05AM: Triggering reconciliation for app 'simple-app' in namespace 'default'
2:46:06AM: Waiting for app reconciliation for 'simple-app'
2:46:06AM: Fetch started 
2:46:06AM: Fetching 
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - git:
	    |       commitTitle: Update build.yml (#7)...
	    |       sha: 4305318f9fd7f44b489692461c4c8d64ed2151f5
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    | 
2:46:06AM: Fetch succeeded 
2:46:06AM: Template succeeded 
2:46:06AM: Deploy started (1s ago)
2:46:07AM: Deploying 
	    | Target cluster 'https://10.92.0.1:443'
	    | Changes
	    | Namespace  Name  Kind  Conds.  Age  Op  Op st.  Wait to  Rs  Ri
	    | Op:      0 create, 0 delete, 0 update, 0 noop, 0 exists
	    | Wait to: 0 reconcile, 0 delete, 0 noop
	    | Succeeded
2:46:07AM: App reconciled 

Succeeded
```
The `kick` command also gives us a glimpse of the new tailing behaviour!

While waiting for the app to reconcile, `kctrl` illustrates the stages of reconciliation of the app. We can see information about the fetch, template and deploy stages while the app reconciles. The status of the app is streamed as and when it is updated till the app reconciles successfully.

The `kick` command can also be used to bring paused apps back to life.

The `status` command allows users to observe the last reconciliation of an app while displaying some metrics. 
```bash
$ kctrl app status -a simple-app
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

Name       simple-app  
Namespace  default  
Status     Reconcile succeeded  
Metrics    33 consecutive successes  

2:50:26AM: Fetch started (29s ago)
2:50:26AM: Fetching (29s ago)
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - git:
	    |       commitTitle: Update build.yml (#7)...
	    |       sha: 4305318f9fd7f44b489692461c4c8d64ed2151f5
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    | 
2:50:26AM: Fetch succeeded (29s ago)
2:50:26AM: Template succeeded (29s ago)
2:50:26AM: Deploy started (29s ago)
2:50:26AM: Deploying (29s ago)
	    | Target cluster 'https://10.92.0.1:443'
	    | Changes
	    | Namespace  Name  Kind  Conds.  Age  Op  Op st.  Wait to  Rs  Ri
	    | Op:      0 create, 0 delete, 0 update, 0 noop, 0 exists
	    | Wait to: 0 reconcile, 0 delete, 0 noop
	    | Succeeded
2:50:26AM: App reconciled (29s ago)

Succeeded
```
What's interesting is that if this command is run while an app is reconciling, it tails the status till the app reconciles successfully or fails.

The output for a failing app looks something like this,
```bash
$ kctrl app status -a faulty-app
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

Name       faulty-app  
Namespace  default  
Status     Reconcile failed  
Metrics    36 consecutive failures  

2:55:06AM: Fetch started (25s ago)
2:55:06AM: Fetching (25s ago)
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - inline: {}
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    | 
2:55:06AM: Fetch succeeded (25s ago)
2:55:06AM: Template succeeded (25s ago)
2:55:06AM: Deploy started (25s ago)
2:55:07AM: Deploy failed (24s ago)
	    | kapp: Error: Expected to find kind '/v1/ConfigMaps', but did not:
	    | - Kubernetes API server did not have matching apiVersion + kind
	    | - No matching CRD was found in given configuration

kctrl: Error: Reconciling app:
  Deploy failed
```

The `delete` command allows users to delete App CRs while tailing the deletion of the resources created by it.
```bash
$ kctrl app delete -a simple-app
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

Deleting app 'simple-app' in namespace 'default'
Continue? [yN]: y

2:58:05AM: Waiting for app deletion for 'simple-app'
2:58:05AM: Delete started (2s ago)
2:58:07AM: Deleting 
	    | Target cluster 'https://10.92.0.1:443'
	    | Changes
	    | Namespace  Name                         Kind           Conds.  Age  Op      Op st.  Wait to  Rs  Ri
	    | default    simple-app                   Deployment     2/2 t   26m  delete  -       delete   ok  -
	    | ^          simple-app                   Endpoints      -       26m  -       -       delete   ok  -
	    | ^          simple-app                   Service        -       26m  delete  -       delete   ok  -
	    | ^          simple-app-5894d79b7f        ReplicaSet     -       26m  -       -       delete   ok  -
	    | ^          simple-app-5894d79b7f-wxjrd  Pod            4/4 t   26m  -       -       delete   ok  -
	    | ^          simple-app-stnf4             EndpointSlice  -       26m  -       -       delete   ok  -
	    | Op:      0 create, 2 delete, 0 update, 4 noop, 0 exists
	    | Wait to: 0 reconcile, 6 delete, 0 noop
	    | 9:28:05PM: ---- applying 6 changes [0/6 done] ----
	    | 9:28:05PM: noop endpointslice/simple-app-stnf4 (discovery.k8s.io/v1) namespace: default
	    | 9:28:05PM: noop replicaset/simple-app-5894d79b7f (apps/v1) namespace: default
	    | 9:28:05PM: noop pod/simple-app-5894d79b7f-wxjrd (v1) namespace: default
	    | 9:28:05PM: noop endpoints/simple-app (v1) namespace: default
	    | 9:28:05PM: delete deployment/simple-app (apps/v1) namespace: default
	    | 9:28:05PM: delete service/simple-app (v1) namespace: default
	    | 9:28:05PM: ---- waiting on 6 changes [0/6 done] ----
	    | 9:28:05PM: ongoing: delete pod/simple-app-5894d79b7f-wxjrd (v1) namespace: default
	    | 9:28:05PM: ok: delete service/simple-app (v1) namespace: default
	    | 9:28:05PM: ok: delete endpoints/simple-app (v1) namespace: default
	    | 9:28:05PM: ongoing: delete replicaset/simple-app-5894d79b7f (apps/v1) namespace: default
	    | 9:28:05PM: ok: delete deployment/simple-app (apps/v1) namespace: default
	    | 9:28:05PM: ongoing: delete endpointslice/simple-app-stnf4 (discovery.k8s.io/v1) namespace: default
	    | 9:28:05PM: ---- waiting on 3 changes [3/6 done] ----
	    | 9:28:06PM: ok: delete replicaset/simple-app-5894d79b7f (apps/v1) namespace: default
	    | 9:28:06PM: ok: delete endpointslice/simple-app-stnf4 (discovery.k8s.io/v1) namespace: default
	    | 9:28:06PM: ongoing: delete pod/simple-app-5894d79b7f-wxjrd (v1) namespace: default
	    | 9:28:06PM:  ^ Deleting
	    | 9:28:06PM: ---- waiting on 1 changes [5/6 done] ----
	    | 9:28:13PM: ok: delete pod/simple-app-5894d79b7f-wxjrd (v1) namespace: default
	    | 9:28:13PM: ---- applying complete [6/6 done] ----
	    | 9:28:13PM: ---- waiting complete [6/6 done] ----
2:58:13AM: App 'simple-app' in namespace 'default' deleted 

Succeeded
```
Now that we know how we can talk to our App CRs, let's see how observing them improves the package consumption experience.
# Enhanced package consumption workflow
When a user installs a package, kapp-controller observes the PackageInstall resource created and creates an App CR which syncs periodically to ensure that the state on the cluster is the same as the one defined by the package. Since, `kctrl` tails the status of the underlying App CR providing more information about the stages of the reconciliation process. The experience is similar to the tailing behaviour in the app commands.

This lets the users be more aware of what is happening while the installation reconciles, and analyse any erroneous behaviour better.

Let's take a look at what this looks like, 
```bash
$ kctrl package install -i hello-app -p hello-app.corp.com --version 1.0.0
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

11:22:20AM: Creating service account 'hello-app-default-sa'
11:22:20AM: Creating cluster admin role 'hello-app-default-cluster-role'
11:22:20AM: Creating cluster role binding 'hello-app-default-cluster-rolebinding'
11:22:20AM: Creating package install resource
11:22:21AM: Waiting for PackageInstall reconciliation for 'hello-app'
11:22:21AM: Fetch started (1s ago)
11:22:22AM: Fetching 
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - imgpkgBundle:
	    |       image: index.docker.io/100mik/hello-app@sha256:29c02895e51a0157ff844afd97a8ccd42a7ba0dd2e89bf5f9c6a668e17482ccb
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    | 
11:22:22AM: Fetch succeeded 
11:22:22AM: Template succeeded 
11:22:22AM: Deploy started (2s ago)
11:22:24AM: Deploying 
	    | Target cluster 'https://10.92.0.1:443' (nodes: minikube)
	    | Changes
	    | Namespace  Name               Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
	    | default    simple-server-app  Deployment  -       -    create  -       reconcile  -   -
	    | ^          simple-server-app  Service     -       -    create  -       reconcile  -   -
	    | Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
	    | Wait to: 2 reconcile, 0 delete, 0 noop
	    | 5:52:23AM: ---- applying 2 changes [0/2 done] ----
	    | 5:52:23AM: create deployment/simple-server-app (apps/v1) namespace: default
	    | 5:52:23AM: create service/simple-server-app (v1) namespace: default
	    | 5:52:23AM: ---- waiting on 2 changes [0/2 done] ----
	    | 5:52:23AM: ok: reconcile service/simple-server-app (v1) namespace: default
	    | 5:52:23AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:52:23AM:  ^ Waiting for generation 2 to be observed
	    | 5:52:23AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:52:23AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:52:23AM:     ^ Pending
	    | 5:52:23AM: ---- waiting on 1 changes [1/2 done] ----
	    | 5:52:23AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:52:23AM:  ^ Waiting for 3 unavailable replicas
	    | 5:52:23AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:52:23AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:52:23AM:     ^ Pending
	    | 5:52:23AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-glwjq (v1) namespace: default
	    | 5:52:23AM:     ^ Pending
	    | 5:52:23AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-85xnh (v1) namespace: default
	    | 5:52:23AM:     ^ Pending
	    | 5:52:24AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:52:24AM:  ^ Waiting for 3 unavailable replicas
	    | 5:52:24AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:52:24AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:52:24AM:     ^ Pending: ContainerCreating
	    | 5:52:24AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-glwjq (v1) namespace: default
	    | 5:52:24AM:     ^ Pending: ContainerCreating
	    | 5:52:24AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-85xnh (v1) namespace: default
	    | 5:52:24AM:     ^ Pending: ContainerCreating
	    | 5:52:25AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:52:25AM:  ^ Waiting for 1 unavailable replicas
	    | 5:52:25AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:52:25AM:  L ok: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:52:25AM:  L ok: waiting on pod/simple-server-app-85dd75f479-glwjq (v1) namespace: default
	    | 5:52:25AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-85xnh (v1) namespace: default
	    | 5:52:25AM:     ^ Pending: ContainerCreating
	    | 5:52:27AM: ok: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:52:27AM: ---- applying complete [2/2 done] ----
	    | 5:52:27AM: ---- waiting complete [2/2 done] ----
	    | Succeeded
11:22:27AM: App reconciled 

Succeeded
```
We can see that after fetching and templating the the config, a deployment and a service are created. The app is marked as reconciled once these resources reach their desired state. Lets supply a values file to the PackageInstall, we will supply a value for `user_name` which should update the deployment,
```bash
$ kctrl package installed update -i hello-app --values-file - << EOF
---
user_name: 100mik
EOF
Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

11:27:17AM: Getting package install for 'hello-app'
11:27:18AM: Creating secret 'hello-app-default-values'
11:27:18AM: Updating package install for 'hello-app'
11:27:18AM: Waiting for PackageInstall reconciliation for 'hello-app'
11:27:19AM: Fetching 
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - imgpkgBundle:
	    |       image: index.docker.io/100mik/hello-app@sha256:29c02895e51a0157ff844afd97a8ccd42a7ba0dd2e89bf5f9c6a668e17482ccb
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    | 
11:27:19AM: Fetch succeeded 
11:27:19AM: Template succeeded 
11:27:19AM: Deploy started (3s ago)
11:27:21AM: Deploying (1s ago)
	    | Target cluster 'https://10.92.0.1:443' (nodes: minikube)
	    | Changes
	    | Namespace  Name               Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
	    | default    simple-server-app  Deployment  2/2 t   4m   update  -       reconcile  ok  -
	    | Op:      0 create, 0 delete, 1 update, 0 noop, 0 exists
	    | Wait to: 1 reconcile, 0 delete, 0 noop
	    | 5:57:20AM: ---- applying 1 changes [0/1 done] ----
	    | 5:57:21AM: update deployment/simple-server-app (apps/v1) namespace: default
	    | 5:57:21AM: ---- waiting on 1 changes [0/1 done] ----
	    | 5:57:21AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:57:21AM:  ^ Waiting for generation 4 to be observed
	    | 5:57:21AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:57:21AM:  L ok: waiting on replicaset/simple-server-app-85d68c6b67 (apps/v1) namespace: default
	    | 5:57:21AM:  L ok: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:57:21AM:  L ok: waiting on pod/simple-server-app-85dd75f479-glwjq (v1) namespace: default
	    | 5:57:21AM:  L ok: waiting on pod/simple-server-app-85dd75f479-85xnh (v1) namespace: default
	    | 5:57:21AM:  L ongoing: waiting on pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 5:57:21AM:     ^ Pending: ContainerCreating
	    | 5:57:22AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:57:22AM:  ^ Waiting for 1 unavailable replicas
	    | 5:57:22AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:57:22AM:  L ok: waiting on replicaset/simple-server-app-85d68c6b67 (apps/v1) namespace: default
	    | 5:57:22AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:57:22AM:     ^ Deleting
	    | 5:57:22AM:  L ok: waiting on pod/simple-server-app-85dd75f479-glwjq (v1) namespace: default
	    | 5:57:22AM:  L ok: waiting on pod/simple-server-app-85dd75f479-85xnh (v1) namespace: default
	    | 5:57:22AM:  L ongoing: waiting on pod/simple-server-app-85d68c6b67-t9xf9 (v1) namespace: default
	    | 5:57:22AM:     ^ Pending: ContainerCreating
	    | 5:57:22AM:  L ok: waiting on pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 5:57:23AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:57:23AM:  ^ Waiting for 1 unavailable replicas
	    | 5:57:23AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:57:23AM:  L ok: waiting on replicaset/simple-server-app-85d68c6b67 (apps/v1) namespace: default
	    | 5:57:23AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:57:23AM:     ^ Deleting
	    | 5:57:23AM:  L ok: waiting on pod/simple-server-app-85dd75f479-glwjq (v1) namespace: default
	    | 5:57:23AM:  L ok: waiting on pod/simple-server-app-85dd75f479-85xnh (v1) namespace: default
	    | 5:57:23AM:  L ok: waiting on pod/simple-server-app-85d68c6b67-t9xf9 (v1) namespace: default
	    | 5:57:23AM:  L ok: waiting on pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 5:57:24AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:57:24AM:  ^ Waiting for 1 unavailable replicas
	    | 5:57:24AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:57:24AM:  L ok: waiting on replicaset/simple-server-app-85d68c6b67 (apps/v1) namespace: default
	    | 5:57:24AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:57:24AM:     ^ Deleting
	    | 5:57:24AM:  L ok: waiting on pod/simple-server-app-85dd75f479-glwjq (v1) namespace: default
	    | 5:57:24AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-85xnh (v1) namespace: default
	    | 5:57:24AM:     ^ Deleting
	    | 5:57:24AM:  L ok: waiting on pod/simple-server-app-85d68c6b67-t9xf9 (v1) namespace: default
	    | 5:57:24AM:  L ok: waiting on pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 5:57:24AM:  L ongoing: waiting on pod/simple-server-app-85d68c6b67-bm9n4 (v1) namespace: default
	    | 5:57:24AM:     ^ Pending: ContainerCreating
	    | 5:57:25AM: ongoing: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:57:25AM:  ^ Waiting for 1 unavailable replicas
	    | 5:57:25AM:  L ok: waiting on replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 5:57:25AM:  L ok: waiting on replicaset/simple-server-app-85d68c6b67 (apps/v1) namespace: default
	    | 5:57:25AM:  L ongoing: waiting on pod/simple-server-app-85dd75f479-lf267 (v1) namespace: default
	    | 5:57:25AM:     ^ Deleting
	    | 5:57:25AM:  L ok: waiting on pod/simple-server-app-85dd75f479-glwjq (v1) namespace: default
	    | 5:57:25AM:  L ok: waiting on pod/simple-server-app-85d68c6b67-t9xf9 (v1) namespace: default
	    | 5:57:25AM:  L ok: waiting on pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 5:57:25AM:  L ongoing: waiting on pod/simple-server-app-85d68c6b67-bm9n4 (v1) namespace: default
	    | 5:57:25AM:     ^ Pending: ContainerCreating
	    | 5:57:26AM: ok: reconcile deployment/simple-server-app (apps/v1) namespace: default
	    | 5:57:26AM: ---- applying complete [1/1 done] ----
	    | 5:57:26AM: ---- waiting complete [1/1 done] ----
11:27:26AM: App reconciled 

Succeeded
```
Once the new values are supplied we can see that another reconciliation is triggered. We can observe that the deployment is updated and the reconciliation completes once the desired number of replicas are available.

The `package installed delete` command has a similar experience as well, the user can observe how `kapp` waits for deletion of resources created due to the installation before the package installation is deleted.
```bash
$ kctrl package installed delete -i hello-app
Delete package install 'hello-app' from namespace 'default'

Continue? [yN]: y

Target cluster 'https://127.0.0.1:64709' (nodes: minikube)

11:38:17AM: Deleting package install 'hello-app' from namespace 'default'
11:38:17AM: Waiting for deletion of package install 'hello-app' from namespace 'default'
11:38:17AM: Delete started (2s ago)
11:38:19AM: Deleting 
	    | Target cluster 'https://10.92.0.1:443' (nodes: minikube)
	    | Changes
	    | Namespace  Name                                Kind           Conds.  Age  Op      Op st.  Wait to  Rs  Ri
	    | default    simple-server-app                   Deployment     2/2 t   15m  delete  -       delete   ok  -
	    | ^          simple-server-app                   Endpoints      -       15m  -       -       delete   ok  -
	    | ^          simple-server-app                   Service        -       15m  delete  -       delete   ok  -
	    | ^          simple-server-app-85d68c6b67        ReplicaSet     -       10m  -       -       delete   ok  -
	    | ^          simple-server-app-85d68c6b67-bm9n4  Pod            4/4 t   10m  -       -       delete   ok  -
	    | ^          simple-server-app-85d68c6b67-krz67  Pod            4/4 t   10m  -       -       delete   ok  -
	    | ^          simple-server-app-85d68c6b67-t9xf9  Pod            4/4 t   10m  -       -       delete   ok  -
	    | ^          simple-server-app-85dd75f479        ReplicaSet     -       15m  -       -       delete   ok  -
	    | ^          simple-server-app-xpr9f             EndpointSlice  -       15m  -       -       delete   ok  -
	    | Op:      0 create, 2 delete, 0 update, 7 noop, 0 exists
	    | Wait to: 0 reconcile, 9 delete, 0 noop
	    | 6:08:18AM: ---- applying 9 changes [0/9 done] ----
	    | 6:08:18AM: noop endpointslice/simple-server-app-xpr9f (discovery.k8s.io/v1) namespace: default
	    | 6:08:18AM: noop pod/simple-server-app-85d68c6b67-bm9n4 (v1) namespace: default
	    | 6:08:18AM: noop pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 6:08:18AM: noop pod/simple-server-app-85d68c6b67-t9xf9 (v1) namespace: default
	    | 6:08:18AM: noop endpoints/simple-server-app (v1) namespace: default
	    | 6:08:18AM: noop replicaset/simple-server-app-85d68c6b67 (apps/v1) namespace: default
	    | 6:08:18AM: noop replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 6:08:18AM: delete deployment/simple-server-app (apps/v1) namespace: default
	    | 6:08:18AM: delete service/simple-server-app (v1) namespace: default
	    | 6:08:18AM: ---- waiting on 9 changes [0/9 done] ----
	    | 6:08:18AM: ok: delete service/simple-server-app (v1) namespace: default
	    | 6:08:18AM: ongoing: delete endpointslice/simple-server-app-xpr9f (discovery.k8s.io/v1) namespace: default
	    | 6:08:18AM: ongoing: delete pod/simple-server-app-85d68c6b67-t9xf9 (v1) namespace: default
	    | 6:08:18AM: ongoing: delete pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 6:08:18AM: ongoing: delete pod/simple-server-app-85d68c6b67-bm9n4 (v1) namespace: default
	    | 6:08:18AM: ongoing: delete replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 6:08:18AM: ongoing: delete replicaset/simple-server-app-85d68c6b67 (apps/v1) namespace: default
	    | 6:08:18AM: ok: delete endpoints/simple-server-app (v1) namespace: default
	    | 6:08:18AM: ok: delete deployment/simple-server-app (apps/v1) namespace: default
	    | 6:08:18AM: ---- waiting on 6 changes [3/9 done] ----
	    | 6:08:19AM: ok: delete replicaset/simple-server-app-85d68c6b67 (apps/v1) namespace: default
	    | 6:08:19AM: ok: delete endpointslice/simple-server-app-xpr9f (discovery.k8s.io/v1) namespace: default
	    | 6:08:19AM: ongoing: delete pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 6:08:19AM:  ^ Deleting
	    | 6:08:19AM: ongoing: delete pod/simple-server-app-85d68c6b67-t9xf9 (v1) namespace: default
	    | 6:08:19AM:  ^ Deleting
	    | 6:08:19AM: ok: delete replicaset/simple-server-app-85dd75f479 (apps/v1) namespace: default
	    | 6:08:19AM: ongoing: delete pod/simple-server-app-85d68c6b67-bm9n4 (v1) namespace: default
	    | 6:08:19AM:  ^ Deleting
	    | 6:08:19AM: ---- waiting on 3 changes [6/9 done] ----
	    | 6:08:22AM: ok: delete pod/simple-server-app-85d68c6b67-krz67 (v1) namespace: default
	    | 6:08:22AM: ---- waiting on 2 changes [7/9 done] ----
	    | 6:08:31AM: ok: delete pod/simple-server-app-85d68c6b67-t9xf9 (v1) namespace: default
	    | 6:08:31AM: ---- waiting on 1 changes [8/9 done] ----
11:38:32AM: App 'hello-app' in namespace 'default' deleted 
11:38:33AM: packageinstall/hello-app (packaging.carvel.dev/v1alpha1) namespace: default: DeletionSucceeded
11:38:33AM: Deleting 'Secret': hello-app-default-values
11:38:34AM: Deleting 'ServiceAccount': hello-app-default-sa
11:38:34AM: Deleting 'ClusterRole': hello-app-default-cluster-role
11:38:34AM: Deleting 'ClusterRoleBinding': hello-app-default-cluster-rolebinding

Succeeded
```
The resources created during the installation are deleted after successful deletion of the PackageInstall.

In line with the app commands, `kctrl` has `package installed pause`, `package installed kick` and `package installed status` commands respectively which allow users to pause reconciliations, trigger reconciliations and observe the status of reconciliation for PackageInstalls respectively. The status of reconciliation is tailed till the PackageInstall has reconciled when a reconciliation is triggered using the `kick` command (just like `app kick`!).

The `app` commands and enhancements to the `package` improve observability and help users get to know what their apps are doing better!

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
