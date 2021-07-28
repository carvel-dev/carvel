---
title: "[Re]Introducing kapp-controller: Carvel’s Package Manager for Kubernetes"
slug: introduction-to-carvel-package-manager
date: 2021-07-29
author: Carvel Team
excerpt: "In this blog post, we will introduce you to the new Package Manager for Kubernetes, kapp-controller..."
image: /img/logo.svg
tags: ['Carvel Team']
---

We’ve been working on an exciting new feature for Carvel that is now available and would like to celebrate this milestone with you! In this blog post, we will introduce you to the new **Package Manager for Kubernetes, [kapp-controller](/kapp-controller/)**.

## What is Carvel and why did we create a Package Manager?

Over the last few years, [Carvel](/) has been built to help the Kubernetes community develop and manage software on their clusters. It provides a suite of small, focused tools all built with a few guiding principles in mind:

* Declarative APIs so users can focus on their desired state and let the system get them there instead of focusing on the imperative commands to get themselves there

* Composable, modular building blocks to give users extreme flexibility in how they work, while still preserving extensibility in their workflow

Recently, though, we felt that something was missing -- the keystone that brings it all together to provide the easiest distribution and installation experience possible. At the core, what we wanted was a lightweight package manager for Kubernetes that provided similar functionality to rpm, brew, apt, etc, but still followed Carvel’s guiding principles. Since we also wanted to keep the experience of software authors in mind, we were additionally looking for the ability to easily create and distribute Packages and Package Repositories (a collection of Packages), preferably using standard OCI registry APIs. To us, these capabilities seemed essential for a tool that would allow the Kubernetes community to build a richer package distribution story and more easily share software with others -- something that we felt was missing.

#### Wait, but what about other Kubernetes Package Managers and deployers?

Unfortunately, while we were exploring the existing solutions, we could not find any that provided the experience we were searching for. The tools that had declarative APIs were not lightweight and came with large upfront investments, which made getting started substantially more difficult, and those that provided a straightforward getting started experience lacked declarative APIs, which forced users to consider how to reach their end goal instead of declaring it and letting the system take them there.

Since no solution out there scratched the Package Management on Kubernetes itch, we decided to build our own by implementing a lightweight layer on top of the existing Carvel tools. This allowed us to ensure it provided everything we were looking for -- extensibile, lightweight, and declarative -- while also including some features we felt were important, such as leveraging OCI registry artifacts to better support air-gapped use cases and artifact signing.

This brings us to today and the [re]introduction of **kapp-controller** as a new **Package Manager for Kubernetes**. For this new feature, we expanded kapp-controller's capabilities to include managing the sources, versions, and installations of software while maintaining Carvel's approach of modular, extensible tooling and declarative APIs. Since this new feature set also leverages the existing Carvel suite, and even supports some non-Carvel tools, package authors will be able to quickly codify the fetching, templating, and installation steps for their software and provide their consumers with an install experience as simple as creating a Kubernetes resource and specifying some configuration values.

## What does the Package Manager do?

Kapp-controller as a package manager is responsible for installing and managing the lifecycle of software within a Kubernetes cluster without requiring the users installing that software to have knowledge of its internal details. To achieve this goal, kapp-controller leverages the concepts of a package and a package repository.

At a high level, a package is versioned metadata which informs kapp-controller how to fetch, template, and install the underlying software contents. These contents usually consist of configuration and source code which has been bundled together and stored in some location --  we recommend an OCI registry, but you can also use a git repo, http server, etc. This abstraction allows kapp-controller to handle the installation and management details, and not the user.

Once authors have created a collection of many packages, a package repository can be used to bundle them and distribute them via an OCI registry. This allows consumers to discover collections of packages and quickly make them available on their cluster for installation. From here, users are able to select which packages they'd like installed and kapp-controller will install them and keep them up to date.

For more details on the resources kapp-controller uses to represent these concepts, see our [docs](/kapp-controller/docs/latest/packaging/#terminology) and [walkthroughs](/kapp-controller/#examples).

## When and how would I use it?

There are a few different stages a developer can find themselves in:

1. You have developed software that you would like to deploy to a Kubernetes cluster for your own use and keep it updated.

2. You need to share your software with another user so that they can deploy it to their cluster.

3. You have a collection of different versioned software that you would like to distribute to your users so that they can easily discover, choose and install on their cluster.

The [App Custom Resource](/kapp-controller/docs/latest/app-spec/) provides a lightweight and flexible way for you to deploy your own software to Kubernetes which helps you if you are at stage 1 above. However, you might have struggled if you are at stage 2 or stage 3. We built these Package Management APIs to help you package your software and distribute it to your users (stage 2). These APIs will also help if you need to distribute multiple packages and make them discoverable to your users (stage 3).

## How do I learn more and get started?

We recommend watching the demo of the Package Management APIs in action and then moving on to an easy to follow and interactive **[tutorial on Katacoda](https://katacoda.com/carvel/scenarios/kapp-controller-package-management)** where you don’t need to set up your own system or you can follow the steps [here](/kapp-controller/docs/latest/packaging-tutorial/) in your favorite playground.

{{< youtube id="PmwkicgEKQE" title="Carvel kapp-controller Demo - Kubernetes Package Management API" >}}

If you would like to get going and try out the new Package Management APIs on your system, check out the following resources.

* [Overview of the APIs and Terminology](/kapp-controller/docs/latest/packaging/)
* [Start creating your package](/kapp-controller/docs/latest/package-authoring/)
* [Helpful workflows](/kapp-controller/#examples) to help you get started

In the next few months, we will also have a set of packages that you will be able to install on your Kubernetes cluster directly. [Join the community](#community) to find out when they are available.

## What’s Next for Carvel and kapp-controller?

In this [initial release](https://github.com/vmware-tanzu/carvel-kapp-controller/releases/tag/v0.20.0), we have provided the basic package management functionality and we plan to work on making it even better. Here are a few things that we are thinking about (not in a particular order):

* Authentication support for Package Repositories hosted on private registry
* Dependency management
* Making the upgrades simpler for packages
* Supporting richer search and filtering capabilities

If you are interested in helping us with the development/direction of kapp-controller or any of our other [roadmap](https://github.com/vmware-tanzu/carvel/blob/develop/ROADMAP.md) items, we would love to have you join us as a contributor! Please review the [CONTRIBUTING.MD doc](https://github.com/vmware-tanzu/carvel/blob/develop/CONTRIBUTING.md) on the [Carvel GitHub repo](https://github.com/vmware-tanzu/carvel) for details on how to get started.

## Join us on Slack and GitHub {#community}

We are excited about this new adventure and we want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace and connect with over 800+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the
docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.

We look forward to hearing from you and hope you join us in building a strong packaging and distribution story for applications on Kubernetes!
