---
title: "Carvel, formerly k14s, aims to simplify application deployment atop Kubernetes"
slug: introduction-to-carvel-blog-post
date: 2020-08-20
author: Helen George
excerpt: "Now that you've deployed Kubernetes, how do you get apps up and running atop the container runtime?..."
image: /img/logo.svg
tags: ['Helen George']
---

Now that you've deployed Kubernetes, how do you get apps up and running atop the container runtime?
[Carvel](/) (formerly known as k14s), a collection of open-source
tools for working with Kubernetes, is designed to answer this question.

## Carvel was born from frustration with existing tools

Carvel is a set of tools designed to ease lifecycle management of your Kubernetes workloads. The origin
of Carvel begins with Dmitriy Kalinin and Nima Kaviani not being satisfied with existing tools to deploy
Kubernetes workloads. These tools were monolithic, error-prone, and hard to debug. Carvel promises a
better way, one that extracts common app configuration into a library for use by all your
applications.

Carvel is built with UNIX philosophy in mind. We believe each tool should be optimized for a single
purpose, and have clear boundaries. This allows you to weave Carvel into your Kubernetes environment
however you want. It's up to you to choose one element of Carvel, or the entire set of tools.

## What's in a name?

Carvel is a method of boat building where the planks of the hull are laid side-by-side without an overlap
to create a smooth surface and a robust frame. We chose this name because the imagery of workers using
the Carvel technique reminded us how our tools can be combined with UNIX pipes.

## A closer look at Carvel: ytt, kapp, kbld

Here's a quick summary of the tools within Carvel:
* **ytt** is a templating tool that understands YAML structures. It can
also be used for overlaying configuration for Kubernetes workloads. You can try it out in our [interactive playground.](/ytt/#example:example-demo)

* **kapp** makes managing Kubernetes resources easier. The benefit of kapp
is that it
shows you the changes you are about to make before you apply them. This way there are no surprises
or unwanted changes made to your cluster. Kapp also converges a set of resources during each deploy
and waits for them to be ready. It allows you not to worry about the sequences of your workflow.

* **kbld** (pronounced 'k-build') is a container image building
orchestrator. It lets you
build container images with different types of builders. Check out more of kbld's features in its 
[documentation](/kbld/docs/latest).

Want to learn more? Watch “[TGI Kubernetes](https://www.youtube.com/watch?v=CSglwNTQiYg)” featuring
ytt and kapp, then read the [launch blog](https://tanzu.vmware.com/content/blog/introducing-k14s-kubernetes-tools-simple-and-composable-tools-for-application-deployment).

For our part at VMware, we're using Carvel with the [cf-for-k8s project](https://github.com/cloudfoundry/cf-for-k8s)
and [the beta version of VMware Application Service that runs atop Kubernetes](https://network.pivotal.io/products/tas-for-kubernetes/).
We can't wait to see what you can do with these tools!

{{< blog_footer >}}
