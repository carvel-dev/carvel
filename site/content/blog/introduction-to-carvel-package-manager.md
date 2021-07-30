---
title: "Introducing kapp-controller as a Package Manager for Kubernetes"
slug: introduction-to-carvel-package-manager-for-kubernetes
date: 2021-07-28
author: Vibhas Kumar and Eli Wrenn
excerpt: "In this blog post we will introduce you to kapp-controller as a Package Manager for Kubernetes..."
image: /img/logo.svg
tags: ['Vibhas Kumar', 'Eli Wrenn', 'Vibhas Kumar and Eli Wrenn']
---

We've been working on an exciting new feature in Carvel that is now available and would like to celebrate this milestone with you! In this blog post, we will introduce you to [kapp-controller](/kapp-controller/), a **Package Manager for Kubernetes, [kapp-controller](/kapp-controller/)**.

## What is Carvel and why did we create a Package Manager?

Over the last few years, [Carvel](/) has been built to help the Kubernetes community develop and manage software on their clusters. It provides a suite of small, focused tools all built with a few guiding principles in mind:

* Declarative APIs so users can focus on their desired state and let the system get them there

* Composable, modular building blocks to give users full flexibility in how they work, while still preserving extensibility in their workflow

Recently, though, we felt that something was missing -- the keystone that brings it all together to provide a simple software distribution and installation experience on Kubernetes. At the core, what we wanted was a lightweight package manager for Kubernetes that provided similar functionality to rpm, brew, apt, etc, but still followed Carvel's guiding principles. Keeping the experience of software authors in mind, we were additionally looking for the ability to easily create and distribute Packages and Package Repositories (a collection of Packages) using standard OCI registry APIs so that signed software can be installed on air-gapped environments. To us, these capabilities seemed essential for a tool that would allow us and the Kubernetes community to build a richer package distribution story and more easily share software with others.

Since no solution out there scratched our itch for lightweight and declarative package management, we decided to implement a thin layer on top of the existing Carvel tools. This brings us to today and the [re]introduction of **kapp-controller** as a **Package Manager for Kubernetes**.

## What does the Package Manager do?

kapp-controller as a package manager is responsible for installing and managing the lifecycle of software within a Kubernetes cluster without requiring the users installing that software to have knowledge of its internal details. To achieve this goal, kapp-controller leverages the concepts of a package and a package repository.

At a high level, a package is versioned metadata which informs kapp-controller how to fetch, template, and install the underlying software contents. These contents usually consist of configuration and container images which have been bundled together and stored in some location --  we recommend an OCI registry (but you can also use a git repo, http server, etc). This abstraction allows kapp-controller, and not the user, to handle the installation and management details.

Once authors have created a collection of many packages, a package repository can be used to bundle them and distribute them via an OCI registry. This allows consumers to discover collections of packages and quickly make them available on their cluster for installation. From here, users are able to select which packages they'd like installed and kapp-controller will install them and keep them up to date.

For more details on the Kubernetes custom resources kapp-controller uses to represent these concepts, see our [docs](/kapp-controller/docs/latest/packaging/#terminology) and [walkthroughs](/kapp-controller/#examples).

## When and how would I use it?

There are a few different use cases you can find yourself in:

(a) You have developed software that you would like to deploy to a Kubernetes cluster for your own use and keep it updated.

(b) You have a collection of different versioned software that you would like to distribute to your users so that they can easily discover, choose and install on their cluster.

The [App CR (Custom Resource)](/kapp-controller/docs/latest/app-spec/) provides a lightweight and flexible way for you to deploy your own software to Kubernetes which helps you if your use case is (a). However, you might have struggled if you are faced with use case (b). We built these Package Management APIs to to address use case (b) so that you can package your software, distribute it, and make it discoverable to your users.

## How do I learn more and get started?

We recommend:

* Watching the below demo of the Package Management APIs in action
* Following an interactive **[tutorial on Katacoda](https://katacoda.com/carvel/scenarios/kapp-controller-package-management)** where you don't need to set up your own Kubernetes cluster
* Alternatively, following the [same steps](/kapp-controller/docs/latest/packaging-tutorial/) on your own cluster

{{< youtube id="PmwkicgEKQE" title="Carvel kapp-controller Demo - Kubernetes Package Management API" >}}

If you would like to read more about Package Management APIs, check out the following resources:

* [Overview of the APIs and Terminology](/kapp-controller/docs/latest/packaging/)
* [Start creating your package](/kapp-controller/docs/latest/package-authoring/)
* [Helpful workflows](/kapp-controller/#examples) to help you get started

In the next few months, we will also share a set of packages that you will be able to install on your Kubernetes cluster directly.

## What's Next for Carvel and kapp-controller?

In the initial release, we have provided the basic package management functionality and we plan to work on making it even better. Here are a few things that we are thinking about (not in a particular order):

* Supporting OCI registries that require authentication
* Dependency management between packages
* Supporting more sophisticated package upgrades based on package metadata

If you are interested in helping us with the development/direction of kapp-controller or any of our other [roadmap](https://github.com/vmware-tanzu/carvel/blob/develop/ROADMAP.md) items, we would love to have you join us as a contributor! Please review the [CONTRIBUTING.MD doc](https://github.com/vmware-tanzu/carvel/blob/develop/CONTRIBUTING.md) on the [Carvel GitHub repo](https://github.com/vmware-tanzu/carvel) for details on how to get started.

## Join us on Slack and GitHub {#community}

We are excited about this new adventure and we want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace and connect with over 800+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.

We look forward to hearing from you and hope you join us in building a strong packaging and distribution story for applications on Kubernetes!
