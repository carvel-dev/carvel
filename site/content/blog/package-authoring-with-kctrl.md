---
title: "Introducing kctrl package authoring commands"
slug: kctrl-pkg-authoring-cmds
date: 2022-08-19
author: Rohit Aggarwal, Soumik Majumder
excerpt: "Learn about the package authoring commands introduced in kctrl and how it makes it easier for package authors to create Carvel packages."
image: /img/logo.svg
asciinema: true
tags: ['Rohit Aggarwal', 'Soumik Majumder', 'kapp-controller', 'kctrl', 'carvel']
---

In today's post, we are going to see how the kctrl CLI eases the process of package authoring.

A [package](https://carvel.dev/kapp-controller/docs/latest/packaging/#package) is a combination of configuration metadata and OCI images. It informs the package manager what software it holds and how to install itself onto a Kubernetes cluster.

A package author encapsulates, versions and distributes Kubernetes manifests as package for package consumers to install on a Kubernetes cluster. They can choose to create a package by using a third party manifest like ones released by [cert-manager](https://cert-manager.io/), [Dynatrace](https://www.dynatrace.com/), etc., or they can distribute their own project Kubernetes manifest by creating a package.


## Typical Package Authoring journey
Package Authoring is an iterative process and below are the most common steps performed by the authors:
1. Authors know about the Kubernetes manifest they want to package.
2. Add/change the manifest by adding additional [overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/)/[template](https://carvel.dev/ytt/docs/latest/#templating) and test the package. This is the iterative part where authors want to make the changes and test them quickly.
3. Once all the manifest are in place, create the [imgpkg](https://carvel.dev/imgpkg/) bundle (to be mentioned in the package) and the package itself.
4. Add the package to a package repository for distribution.

## How does `kctrl` help package authors?
Today, before package authors start on their authoring journey, are required to know about tools like [imgpkg](https://carvel.dev/imgpkg/), [kbld](https://carvel.dev/kbld/), [vendir](https://carvel.dev/vendir/), etc. which are building blocks for Carvel packages. Our intention is to introduce a set of CLI commands that would guide authors through the common packaging steps to enable them to create and release the packages without being familiar with these tools, while also learning about them in the process. We aim to achieve most of the scenarios using kctrl. For more complex use cases authors can always leverage these tools.

{{< asciinema key="authoring-commands-blog" rows="30" preload="1" speed="2">}}

## What are `kctrl` package authoring commands?
* [**kctrl package init**](/kapp-controller/docs/latest/authoring-command/#initialising-the-package): To initialize the Package, PackageInstall and other resources. These resources will be used by the subsequent commands.

* [**kctrl dev**](/kapp-controller/docs/latest/authoring-command/#dev): This command will use the Package and PackageInstall generated above and deploy them locally. By locally, we mean that kapp-controller need not be installed on the Kubernetes cluster. Also, it will eliminate the need to push the imgpkg bundle to an OCI registry during the development stage. This will be useful when you are develping the additional overlay/template.

* [**kctrl package release**](/kapp-controller/docs/latest/authoring-command/#releasing-the-package): This command will create and upload the imgpkg bundle with all the Kubernetes manifest of the software. Also, it will create the `package.yml` and `metadata.yml` files which can be either checked in to the package repository or released as part of the release artifacts.

* [**kctrl package repo release**](/kapp-controller/docs/latest/authoring-command/#releasing-a-package-repository): This command will create and push the package repository bundle consisting of all the Package and PackageMetadata files present in the `packages` folder of the working directory. This repository bundle can later on be consumed by package consumers.

![Kctrl flow for kubernetes-package-authoring](/images/blog/introducing-kctrl-package-authoring-commands.png)

All these commands are available from version [v0.40.0+](https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest). You can find a tutorial with end to end workflow for package authoring [here](/kapp-controller/docs/latest/kctrl-package-authoring.md)!

`kctrl` [v0.40.0](https://github.com/vmware-tanzu/carvel-kapp-controller/releases/tag/v0.40.0) is an alpha release of the package authoring commands. We are excited for you to try out the tool. We are eager to hear about your experiences and how it solves your use-case. There is a github [issue](https://github.com/vmware-tanzu/carvel-kapp-controller/issues/831) created to collect the feedback/feature request/suggestion which you would like to see in the future releases. We encourage you to post it there. Alternatively, you can post it in the [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) slack channel.

## Are you using Carvel?

If you are using any of the Carvel tools, first we would like to thank you! Our goal is to grow the community, improve Carvel and help each other. One of the best ways that helps us do that is to know how others are using the tools. Please add a comment to [this pinned issue](https://github.com/vmware-tanzu/carvel/issues/213) with details on your use case with any of the Carvel tools.

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.