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

![config.yml](/images/blog/stage1A.png)

![kapp deploy](/images/blog/stage1B.png)

The first thing that kapp does is that it upserts (update + insert) the app’s ConfigMap. If the kapp app already exists then we’ll update the ConfigMap, but if it does not exist, kapp will insert and create the ConfigMap.

![config map](/images/blog/stage1C.png)

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

![no-op](/images/blog/stage2.png)

## Stage 3: Pre-apply Checks

During this stage, kapp will check for namespace violations. In kapp, a ConfigMap of the kapp app is either stored on the cluster in the same namespace as the app or stored in its own namespace with other ConfigMaps that describe other kapp apps.

Additionally, during this stage kapp is going to display the diff to the user and ask for confirmation. It will also garbage collect the old ConfigMaps from previous updates and changes that happened in this cluster.


![Pre-apply Checks](/images/blog/pre-apply-checks.png)

## Stage 4: Apply

![Apply](/images/blog/apply.png)

Lastly, we have the Apply stage. With the directed acyclic graph that was created in stage two, each vertex is a change that needs to happen and the edges are the change rules, or the order in which the changes need to happen.

The first changes will enter into the “Applying Changes” step, and each change is sent off into a Go routine to be applied. They then enter the “Waiting Changes” step, where kapp will keep track of which changes are currently applying. When one has finished, kapp will move that change to the “Unblock Changes” step, which will unblock any changes that the change was blocking.

Example: If “A” and “G” in the graph example below are sent off, and if “A” finishes first, “B” will then be unblocked. Eventually, “G” will finish its Go routine and unblock “D.” But, “D” will not be available until “B” unblocks it, as well.

These changes go through the loop until every change has finished and kapp sorts these resources in order for the Kubernetes API to successfully process them. Examples of why sorting is important: 1. CRDs need to come before the custom resources that use them; 2. Namespaces need to be deployed prior to deploying a resource within that namespace.

Note that kapp tries to wait for the resources to become ready before considering the deploy a success, but if the last change was caught in some state that the change was never reconciled, kapp would consider that a failure.

![ordered change](/images/blog/stage4.png)
