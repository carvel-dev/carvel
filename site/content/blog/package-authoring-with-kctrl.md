---
title: "Introducing Kubernetes package authoring with kctrl"
slug: kctrl-release-blog
date: 2022-08-19
author: Rohit Aggarwal, Soumik Majumder
excerpt: "Learn about the package authoring commands introduced in kctrl and how it makes it easier for package authors to create Carvel packages."
image: /img/logo.svg
tags: ['Rohit Aggarwal', 'Soumik Majumder', 'kapp-controller', 'kctrl', 'carvel']
---

In today's post, we are going to see how the kctrl CLI eases the process of package authoring.

A [package](https://carvel.dev/kapp-controller/docs/latest/packaging/#package) is a combination of configuration metadata and OCI images. It informs the package manager what software it holds and how to install itself onto a Kubernetes cluster.

A package author encapsulates, versions and distributes Kubernetes manifests as package for package consumers to install on a Kubernetes cluster. They can choose to create a package by using a third party manifest, e.g. they can choose to create a package from [cert-manager](https://cert-manager.io/), [Dynatrace](https://www.dynatrace.com/), etc., or they can distribute their own project Kubernetes manifest by creating a package.


## Typical Package Authoring journey
Package Authoring is an iterative process and below are the most common steps performed by the authors:
1. Authors know about the Kubernetes manifest they want to package.
2. Add/change the manifest by adding additional [overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/)/[template](https://carvel.dev/ytt/docs/latest/#templating) and test the package. This is the iterative part where authors want to make the changes and test them quickly.
3. Once all the manifest are in place, create the [imgpkg](https://carvel.dev/imgpkg/) bundle (to be mentioned in the package) and the package itself.
4. Add the package to the package repository for distribution.

## How does `kctrl` help package authors?
Today, package authors are supposed to know tools like [imgpkg](https://carvel.dev/imgpkg/), [kbld](https://carvel.dev/kbld/), [vendir](https://carvel.dev/vendir/), etc. before they start on the package authoring journey. These Carvel tools has a learning curve of itself. We wanted to introduce a set of CLI commands that guide users in performing most common packaging steps so that they are able to create and release the package without knowing these tools.

## What are `kctrl` package authoring commands?
* **kctrl package init**: To initialize the Package, PackageInstall and other resources. These resources will be used by the subsequent commands.

* **kctrl dev**: This command will use the Package and PackageInstall generated above and deploy them locally. By locally, we mean that kapp-controller need not be installed on the Kubernetes cluster. Also, it will eliminate the need to push the imgpkg bundle to an OCI registry during the development stage. This will be useful when you are develping the additional overlay/template.

* **kctrl package release**: This command will create and upload the imgpkg bundle with all the Kuberentes manifest of the software. Also, it will create the `package.yml` and `metadata.yml` which can be either checkin to the package repository or released as part of the release artifacts.

* **kctrl package repo release**: This command will create and push the package repository bundle consisting of all the package and packageMetadata files present in the `packages` folder in the working directory. This repository bundle can later on be consumed by package consumers.

![Kctrl flow for kubernetes-package-authoring](/images/blog/introducing-kctrl-package-authoring-commands.png)

![Kctrl flow for kubernetes-package-authoring2](/images/blog/introducing-kctrl-package-authoring-commands2.png)

All these commands are available from version [v0.40.0+](https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest). You can find tutorial with end to end workflow for package authoring [here](/kapp-controller/docs/develop/kctrl-package-authoring.md)!

## What is next for `kctrl` package authoring?
Some of the upcoming features in pipeline are:
- Enhancing the UX experience based on the feedback.
- Generate the `openAPIv3` valuesSchema from Helm Chart values.yaml automatically.
- Enhance `kctrl dev` command to pick the changes as soon as they are made.

## Provide Feedback
We are excited to hear from you about your experience with the tool. There is a github [issue](https://github.com/vmware-tanzu/carvel-kapp-controller/issues/831) created to collect the feedback/feature request/suggestion which you would like to see in the future releases. We encourage you to post it there. Alternatively, you can post it in the [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) slack channel.

## Are you using Carvel?

If you are using any of the Carvel tools, first we would like to thank you! Our goal is to grow the community, improve Carvel and help each other. One of the best ways that helps us do that is to know how others are using the tools. Please add a comment to [this pinned issue](https://github.com/vmware-tanzu/carvel/issues/213) with details on your use case with any of the Carvel tools.

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.