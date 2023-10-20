---
title: "Introducing kctrl, kapp-controller’s native CLI"
slug: kctrl-release-blog
date: 2022-03-21
author: Soumik Majumder
excerpt: "Learn about the new kctrl and how it makes it easier for users to get up and running with Carvel packages."
image: /img/logo.svg
tags: ['Soumik Majumder', 'kapp-controller', 'kctrl', 'carvel']
---

kapp-controller provides declarative APIs to customise, install and update applications and packages reliably replicating workflows involving commonly used tools. It also allows authors of such workflows to package them and ship different versions of such workflows to consumers. The consumers in turn can consume these workflows using declarative APIs.

We realised that package consumers who are not comfortable with authoring YAMLs often face a steep learning curve while trying to get them up and running in their environments. How do we make it easier for package consumers to install, configure and upgrade packages? Enter `kctrl`.

## What is `kctrl`?
`kctrl` is kapp-controller's native CLI which help users effectively interact with and observe custom resources exposed by kapp-controller (App, PackageInstall, PackageRepository, Package CRs). The first release of `kctrl` focuses on helping users getting started with consuming packages with minimum friction. In the next few releases, `kctrl` aims to improve observability of resources created using kapp-controller's declarative APIs, improving the debugging experience and helping users authoring Packages and AppCRs to iterate faster and more efficiently.

## How does `kctrl` help package consumers?
Traditionally, installing a package would involve setting up relevant cluster roles and service accounts which allow the package installations to create desired resources on the cluster. In case the user is configuring the package, they would need to create a Secret which makes this information available and then reference it in their PackageInstall resource. These resources had to be authored and tracked by the user.

`kctrl` helps users get up and running with a package installation with as little as
```bash
$ kctrl package install -i cert-man -p cert-manager.community.tanzu.vmware.com --version 1.6.1 --values-file values.yaml
```
Where, `values.yaml` defines configuration for the installation.

`kctrl` creates service accounts and role bindings with required permissions and keeps track of them. If custom configuration is provided by the user, `kctrl` creates a secret and adds required references to the custom resources being created. When a package is uninstalled, these resources are garbage collected and deleted from the cluster as well.

In case, the user has to use a service account with limited permissions, the same can be supplied to the CLI while installing the application. In this case, kapp-controller does not try to create and track the required resources.

`kctrl` also allows users to add PacakgeRepositories published as `imgpkg` bundles easily to their clusters.
```bash
$ kctrl package repository add -r tce --url projects.registry.vmware.com/tce/main:0.10.0
```

You can find a more detailed end to end workflow for consuming published packages, configuring them and observing them over [here](/kapp-controller/docs/develop/kctrl-package-tutorial/)!

## What is next for `kctrl`?
We want to help our users to easily observe what kapp-controller is doing. `kctrl` aims to do this by surfacing information about what kapp-controller does with the configuration provided by the user in a transparent, legible and usable manner.

This enables developers authoring App CRs and Carvel packages to iterate faster by observing how their configuration affects the cluster. It also enables package consumers to narrow down on the root cause of erroneous installations more conveniently.

Some of the upcoming improvements aimed at demystifying what goes on under the hood and improving the debugging workflow are:
- Observe and follow what an App CR does on the cluster. `kctrl` will surface information revealed by an AppCRs status fields in a readable and sequential manner.
- Observe and inspect resources created by App CRs easily.
- Allow users to pause and trigger reconciliations for App CRs and PackageInstalls easily. This allows users to debug these resources more efficiently.
- The benefits of enhanced observability of App CRs will also extended to AppCRs created due to PackageInstalls.
- A whole set of commands which allows user to get information about App CRs on the cluster! While improving how we observe their current state on the cluster, it also helps users distinguish between authored App CRs and those created by installations.

This [blog](/blog/making-the-most-out-of-clis/) illustrates how `kctrl` fits in with other CLIs interacting with resources on the cluster and enhances workflows.

## Are you using Carvel?

If you are using any of the Carvel tools, first we would like to thank you! Our goal is to grow the community, improve Carvel and help each other. One of the best ways that helps us do that is to know how others are using the tools. Please add a comment to [this pinned issue](https://github.com/carvel-dev/carvel/issues/213) with details on your use case with any of the Carvel tools.

{{< blog_footer >}}