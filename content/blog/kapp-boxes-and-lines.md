---
title: "kapp boxes and lines/ kapp high level development overview"
slug: kapp-boxes-and-lines-blog-post
date: 2021-04-08
author: Garrett Cheadle and Nanci Lancaster
excerpt: "a high level overview of the kapp deploy command"
image: /img/logo.svg
tags: ['Garrett Cheadle', 'Nanci Lancaster']
---

What is [kapp](/kapp)? Kapp is a deployment CLI within the Carvel tool suite for Kubernetes that helps manage resources in bulk.

In this demo, Garrett Cheadle, a Carvel maintainer, covers a high level overview of the kapp deploy command, which is a fairly complete, common kapp workflow. The process can be separated in four stages: Setup, Change Calculations, Pre-apply Checks, and Apply.

![Full diagram](/images/blog/full-boxes-and-lines.png)


## Stage 1: Setup

![Setup](/images/blog/setup.png)

The first step in this stage will be initiated by the user. The user will run a `kapp deploy` command with a target [kapp application](https://carvel.dev/kapp/docs/latest/apps/#overview) designated by the `-a` and some configuration included with the `-f` flag: kapp deploy -a my-app -f config.yml.

```bash-plain
> cat -b config-step-1-minimal/config.yml
---
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: simple-app
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
  simple-app: ""
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
       image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
	   env:
	   - name: HELLO_MSG
	     value: stranger


❯ kapp deploy -a simple-app -f config-step-1-minimal
Target cluster 'https://127.0.0.1:49955' (nodes: kind-control-plane)

Changes

Namespace  Name        Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  -       -    create  -       reconcile  -   -
^          simple-app  Service     -       -    create  -       reconcile  -   -

Op:      2 create, 0 delete, 0 update, 0 noop
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

5:08:43PM: ---- applying 2 changes [0/2 done] ----
5:08:43PM: create service/simple-app (v1) namespace: default
5:08:44PM: create deployment/simple-app (apps/v1) namespace: default
5:08:44PM: ---- waiting on 2 changes [0/2 done] ----
5:08:44PM: ok: reconcile service/simple-app (v1) namespace: default
5:08:44PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
5:08:44PM:  ^ Waiting for generation 2 to be observed
5:08:44PM:  L ok: waiting on replicaset/simple-app-65d64b78b8 (apps/v1) namespace: default
5:08:44PM:  L ongoing: waiting on pod/simple-app-65d64b78b8-jbq52 (v1) namespace: default
5:08:44PM:     ^ Pending: ContainerCreating
5:08:44PM: ---- waiting on 1 changes [1/2 done] ----
5:08:44PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
5:08:44PM:  ^ Waiting for 1 unavailable replicas
5:08:44PM:  L ok: waiting on replicaset/simple-app-65d64b78b8 (apps/v1) namespace: default
5:08:44PM:  L ongoing: waiting on pod/simple-app-65d64b78b8-jbq52 (v1) namespace: default
5:08:44PM:     ^ Pending: ContainerCreating
5:08:47PM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
5:08:47PM: ---- applying complete [2/2 done] ----
5:08:47PM: ---- waiting complete [2/2 done] ----

Succeeded
```

The first thing that kapp does is that it upserts (update + insert) the app’s ConfigMap. If the kapp app already exists then we’ll update the ConfigMap, but if it does not exist, kapp will insert and create the ConfigMap.

```bash-plain
❯ kapp app-change list -a simple-app
Target cluster 'https://127.0.0.1:60579' (nodes: kind-control-plane)

App changes

Name                     Started At            Finished At           Successful  Description
simple-app-change-wb7xf  2021-03-29T21:14:21Z  2021-03-29T21:14:25Z  true        update: Op: 2 create, 0 delete, 0 update, 0 noop / Wait to: 2 reconcile, 0 delete, 0 noop

1 app changes

Succeeded
```

The last step of Setup, kapp will create support objects: resource filters, labeled resources, and a preparation object. Labeled resources help kapp talk to the Kubernetes API. Note: In the preparation object, the nonce annotation allows kapp to inject a unique ID, and the annotation value will be replaced with another unique ID on each deploy, forcing a value to change and update every time.

## Stage 2: Change Calculations

![Change Calculations](/images/blog/change-calcs.png)

The first thing that kapp has to do in order to calculate the changes is to distinguish new resources from existing ones in the config files that were provided by the user. Depending on if the resource is new or existing, kapp has different things to do.

For a new resource, it’s going to append the default kapp config to the resources and use the preparation object to validate the presence of certain configurations, i.e. kind, name, version. The labeled resources will adjust any new labels on the new resource.

Kapp identifies existing resources by checking with the API to confirm that resource already exists.

After kapp has distinguished between new and existing resources, kapp will calculate a [directed acyclic graph (DAG)](https://en.wikipedia.org/wiki/Directed_acyclic_graph) of the changes needed to make the deployment happen. There are two changes that kapp considers:

1. Changes to a templated resource, i.e. change to yaml template of a Kubernetes resource
2. Non-template resource changes, i.e. changing an update strategy or rebase rule

Once kapp has considered the changes, the directed acyclic graph is created. This graph is helpful for kapp because DAG is optimized for topological sorting and ordering. We can schedule each change, which each vertex in this graph is a change, and the edges are describing the way that these changes need to happen. Example: If one node (one vertex) points to another node, you know that the first node has to be done before the second node.

During this creation of the graph kapp checks for cycles, and removes duplicates and no-op (shown below) operations. It’s important that we don’t have cycles because it does need to be an acyclic graph.

```bash-plain
❯ kapp ls
Target cluster 'https://127.0.0.1:49955' (nodes: kind-control-plane)

Apps in namespace 'default'

Name        Namespaces  Lcs   Lca
simple-app  default     true  4m

Lcs: Last Change Successful
Lca: Last Change Age

1 apps

Succeeded
❯ kapp deploy -a simple-app -f config-step-1-minimal
Target cluster 'https://127.0.0.1:49955' (nodes: kind-control-plane)

Changes

Namespace  Name  Kind  Conds.  Age  Op  Op st.  Wait to  Rs  Ri

Op:      0 create, 0 delete, 0 update, 0 noop
Wait to: 0 reconcile, 0 delete, 0 noop

Succeeded
```



## Stage 3: Pre-apply Checks

![Pre-apply Checks](/images/blog/pre-apply-checks.png)

During this stage, kapp will check for namespace violations. In kapp, a ConfigMap of the kapp app is either stored on the cluster in the same namespace as the app or stored in its own namespace with other ConfigMaps that describe other kapp apps.

Additionally, during this stage kapp is going to display the diff to the user and ask for confirmation. It will also garbage collect the old ConfigMaps from previous updates and changes that happened in this cluster.

## Stage 4: Apply

![Apply](/images/blog/apply.png)

Lastly, we have the Apply stage. With the directed acyclic graph that was created in stage two, each vertex is a change that needs to happen and the edges are the change rules, or the order in which the changes need to happen.

The first changes will enter into the “Applying Changes” step, and each change is sent off into a Go routine to be applied. They then enter the “Waiting Changes” step, where kapp will keep track of which changes are currently applying. When one has finished, kapp will move that change to the “Unblock Changes” step, which will unblock any changes that the change was blocking.

Example: If “A” and “G” in the graph example below are sent off, and if “A” finishes first, “B” will then be unblocked. Eventually, “G” will finish its Go routine and unblock “D.” But, “D” will not be available until “B” unblocks it, as well.

These changes go through the loop until every change has finished and kapp sorts these resources in order for the Kubernetes API to successfully process them. Examples of why sorting is important: 1. CRDs need to come before the custom resources that use them; 2. Namespaces need to be deployed prior to deploying a resource within that namespace.

Note that kapp tries to wait for the resources to become ready before considering the deploy a success, but if the last change was caught in some state that the change was never reconciled, kapp would consider that a failure.

```bash-plain
❯ kapp deploy -a custom-app -f custom-resource-def
Target cluster 'https://127.0.0.1:60579' (nodes: kind-control-plane)

Changes

Namespace  Name                         Kind                      Conds.  Age  Op      Op st.  Wait to    Rs  Ri
(cluster)  crontabs.stable.example.com  CustomResourceDefinition  -       -    create  -       reconcile  -   -
default    my-new-cron-object           CronTab                   -       -    create  -       reconcile  -   -

Op:      2 create, 0 delete, 0 update, 0 noop
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

3:12:14PM: ---- applying 1 changes [0/2 done] ----
3:12:15PM: create customresourcedefinition/crontabs.stable.example.com (apiextensions.k8s.io/v1beta1) cluster
3:12:15PM: ---- waiting on 1 changes [0/2 done] ----
3:12:15PM: ok: reconcile customresourcedefinition/crontabs.stable.example.com (apiextensions.k8s.io/v1beta1) cluster
3:12:15PM: ---- applying 1 changes [1/2 done] ----
3:12:15PM: create crontab/my-new-cron-object (stable.example.com/v1) namespace: default
3:12:15PM: ---- waiting on 1 changes [1/2 done] ----
3:12:15PM: ok: reconcile crontab/my-new-cron-object (stable.example.com/v1) namespace: default
3:12:15PM: ---- applying complete [2/2 done] ----
3:12:15PM: ---- waiting complete [2/2 done] ----

Succeeded
```

## Join us on Slack and GitHub

We want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace and connect with over 500+ Carvel users.
* Find us on [GitHub]({{% named_link_url "github_url" %}}). Suggest how we can improve the project, the
docs, or share any other feedback.
* Attend our Community Meetings, happening every Monday at 11:30am PT / 2:30pm ET and Offices Hours, happening every 2nd and 4th Thursday of each month, 11:30am PT / 2:30pm ET. Check out the [Community page](https://carvel.netlify.app/community/) for full details on how to attend.

We look forward to hearing from you!
