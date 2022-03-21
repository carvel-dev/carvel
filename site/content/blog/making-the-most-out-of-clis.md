---
title: "Making the most out of CLIs"
slug: making-the-most-out-of-clis
date: 2022-03-21
author: Soumik Majumder
excerpt: "Find out how different Carvel CLIs interacting with resources on the cluster and kubectl fit together like pieces of a jigsaw puzzle"
image: /img/logo.svg
tags: ['Soumik Majumder', 'carvel', 'kctrl']
---

Carvel is glad to have `kapp` and the (brand new!) `kctrl` as a part of our arsenal. In this blog, we will see how these powerful CLIs, along with our good old friend `kubectl`, fit into our day-to-day workflows.

We often see our users leverage all three of them in their workflows. Let's look at what each one of them is super good at!

## `kubectl`
`kubectl` is a CLI built by the Kubernetes team. It let's users interact with the cluster and resources on it.

### Viewing resources current state on the cluster
`kubectl` lets you fetch and view the current state of a resource on the cluster in it's entirety. This is quite useful while exploring resources on a cluster and debugging faulty resources.

### Managing your `kubeconfig` and contexts
The set of commands under `kubectl config` allow us to manage and modify the configurations we use while connecting to our clusters. These configurations include values which indicate which cluster the tool interacts with, how we authenticate with the cluster and default namespace used.
This is used as the default configuration for connecting to a cluster by other tools on the host - more often than not. And `kubectl` allows us to seamlessly modify and switch between multiple "contexts" like these.

### Interacting with nodes
`kubectl` has a set of powerful commands that let us cordon and uncordon nodes (making them available or not available for scheduling). These commands can also help users drain resources from a node so that it can be cordoned safely. Nodes can be "tainted" with certain key-values, which allow only pods that tolerate those "taints" to be scheduled on them.
Learn more about these commands [here](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-strong-cluster-management-strong-).

### Dive into your containers and applications
`kubectl` allows us to attach to processes containers running on pods and execute commands inside them easily. Users can observe the resource consumption on a pod as well.
// might remove
Proxying and port-forwarding options let a pod or the K8s API server serve HTTP content to localhost. Letting users debug their applications easily

## `kapp`
`kapp` CLI helps users manage their workloads effectively on the cluster. This involves defining interactions between resources declaratively and deploying and updating them confidently.

But wait isn't this something `kubectl apply` or `kubectl patch` will help us do for resource manifests?

Well yes, but `kapp` goes a step further, it helps users order resources in their manifests, apply changes safely and predictably, and then goes on to wait for the resources to reach their desired state. (You could take a deep dive into this over [here](https://carvel.dev/kapp/docs/latest/))

Let's see how `kapp` makes our lives easier.

### Grouping related resources
`kapp` lets users group and [order multiple resources](https://carvel.dev/kapp/docs/latest/apply-ordering/#example) easily. This lets us do tasks like "create a Deployment after a Job has finished" declaratively in our manifests.
`kapp` also caters to other use cases, like [versioning resources](https://carvel.dev/kapp/docs/latest/diff/#versioned-resources) and defining [create/update/delete strategies](https://carvel.dev/kapp/docs/latest/apply/#controlling-apply-via-resource-annotations) for resources in the abstract "application". These features allow users to efficiently and declaratively manage resources to be deployed on clusters.

### Applying changes safely and confidently
While applying changes to the cluster, `kapp` shows a diff against the resources on the cluster (as seen [here](https://carvel.dev/kapp/docs/latest/)), this lets the user be more aware of the changes a patch or a deploy has on the cluster.
Once the user confirms the changes, `kapp` waits for resources to reach their desired state ensuring that the changes are in effect as the user intended.

### View the grouped resources and their statuses easily
The `kapp inspect` command enables users to view resources that have been grouped into an "application". It lists the resources and surfaces information about whether or not the resources are in a healthy state. In case a resource is not in it's desired state, helpful information which helps the user work towards the cause of the failure is surfaced as well.

## `kctrl`
So what does our newest ally bring to the table?
`kctrl` allows users to interact easily with `kapp-controllers` custom resources. It allows users to easily consume published Carvel packages and (will eventually help) interact with and debug [AppCRs](https://carvel.dev/kapp-controller/docs/latest/app-overview/) in a comprehensive manner.

### Get up and running with Carvel packages easily
Initially, installing a package would require the consumer to author a PackageInstall CR which would refer to a particular Package and a version, along with Secrets or ConfigMaps defining values consumed by the PackageInstall and an assigned service account it uses to make changes.
`kctrl` allows users to easily install a package and conveniently supply details required to install it. Carvel packages can be configured by supplying certain values to them during installation. The CLI allows users to easily supply these values as a YAML file. This file is used to create a secret which is referenced by the PackageInstall created under the hood.
This enables package consumers to be up and running, even if they are not ready to get their hands dirty with some YAML.

### Have a reference while authoring values for packages
As we discussed earlier, some packages accept configuration in the form of a YAML file defining certain values. The structure of such files for a package is defined using an OpenAPI schema while authoring these packages. `kctrl` let's user surface details about the values accepted along with short descriptions of the effect they have.

### Re-configure and fix installations with ease
`kctrl` also allows users to update the values supplied to a PackageInstall and bump versions for an installation easily. Of course, without the user having to author resources themselves.

### What is coming up for `kctrl`?
AppCRs are at the heart of Carvel's Packaging API. Different versions of a Package, are essentially different workflows defined in an AppCR style so that they can be distributed - multiple packages can be grouped together and distributed as a PackageRepository. And each PackageInstall resource decides which version of the AppCR should be running on a cluster.

`kctrl` will be making it easier for users to interact with and managing AppCRs. This helps users better debug AppCRs defining GitOps (or other single-source-of-truth) workflows - which might have been authored by them or created due to a package installation.

`kctrl` will:
- Surface information essential for debugging erroneous AppCRs in a comprehensive manner to the user
- Allow users to easily pause and force reconciliation for AppCRs - essential in debugging workflows
- Make it easy to inspect resources that are being created by an AppCR

## To sum up...
`kubectl` is really useful for viewing resources as-is on the cluster, lets us manage our default kubeconfig easily, and is unparalleled when it comes to interacting with nodes and how they are scheduled.

`kapp` is a one-stop solution for managing resources on your clusters effectively. It also helps users deploy changes to the cluster reliably and confidently.

`kctrl` is the ideal tool for interacting with custom resources defined by `kapp-controller`. It helps users get started and get more done while having minimal knowledge of what happens under the hood and without authoring the resources themselves. It also enhances how users interact with AppCRs that are at the core of `kapp-controller` helping them fix issues faster.

## Are you using Carvel?

If you are using any of the Carvel tools, first we would like to thank you! Our goal is to grow the community, improve Carvel and help each other. One of the best ways that helps us do that is to know how others are using the tools. Please add a comment to [this pinned issue](https://github.com/vmware-tanzu/carvel/issues/213) with details on your use case with any of the Carvel tools.

## Join the Carvel Community

Carvel is better because of our contributors and maintainers. It is because of you that we can bring great software to the community. Interested in joining this amazing community? There are several ways to get involved:

 * Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
 * Find us on GitHub in the main [Carvel repo](https://github.com/vmware-tanzu/carvel), or, go to any of the Carvel [tool-specific repos](https://github.com/vmware-tanzu/carvel#carvel) that may interest you in contributing. Feel free to suggest how we can improve the project, the docs, or share any other feedback, as well as provide code contributions. 
 * Attend our Community Meetings, happening every Thursday at 10:30 am PT / 1:30 pm ET. Check out the [Community page](/community/) for full details on how to attend.

