---
title: "Simplifying Package Authoring"
slug: simplifying-package-authoring
date: 2022-08-16
author: Rohit Aggarwal
excerpt: "Simplifying Package Authoring with kctrl"
image: /img/logo.svg
tags: ['carvel', 'package', 'author', 'kctrl', 'create']
---

In Carvel, Kubernetes(K8s) manifest are distributed and consumed via the concept of Package. A package Author encapsulates, version, and distribute K8s manifest for others to install on a Kubernetes cluster. A package author can choose to create a package by using third party manifest e.g. they can choose to create a package from cert-manager or they want to distribute their own project configurations by creating a Package.

Package Authoring is an iterative process and below are the steps authors go through:
1. Authors know about the K8s manifest they want to package.
2. Add/change the manifest by adding ytt overlay/template and test the package. This is the iterative part where authors want to make the changes and test them quickly.
3. Once all the manifest are in place, create the imgpkg bundle(to be mentioned in the package) and package.
4. Add the package to the package repository for distribution.

Today, package authors are supposed to know all the Carvel tools as they are being used in the package authoring journey. Learning the Carvel tools before package authoring is a bit of learning curve. As part of simplifying package authoring, we wanted to reduce this learning curve so that authors can focus on package authoring. As part of this, few commands have been added to the `kctrl` cli.

![Kctrl flow for simplifying-package-authoring](/images/blog/simplifying-package-authoring-kctrl-flow.png)


**kctrl pkg init**: To initialize the App/Package and create the App/PackageInstall.

**kctrl dev**: To deploy App/PackageInstall CR locally.

**kctrl pkg release**: Create, upload the imgpkg bundle and Package to be released.

**kctrl pkg repo release**: Create the repo bundle so that it can be consumed by Package consumers.

Lets, try to create a `Dynatrace` package by using the above commands.

## Create a package

## Prerequisites

1. Install Carvel tools using [`install.sh`](https://carvel.dev/install.sh) script.
2. [`Dynatrace`](https://github.com/Dynatrace/dynatrace-operator) releases the [`kubernetes.yaml`](https://github.com/Dynatrace/dynatrace-operator/releases) which can be packaged and be available for distribution.
3. K8s cluster (I will be using minikube).
4. OCI registry where the package bundle and repository bundles will be pushed (I will be using my DockerHub account).

## kctrl pkg init - Initialize the package

This command asks a few basic questions regarding how we want to initialize our package. Lets go through the question together:

![Simplifying package authoring - pkg init basic details](/images/blog/simplifying-package-authoring-package-basic-details.png)

* In this question, we need to enter the package name which will be a valid DNS subdomain name.

![Simplifying package authoring - pkg init content option](/images/blog/simplifying-package-authoring-package-content-option.png)

* Here, we need to enter from where to get the K8s manifest which needs to be packages. As mentioned earlier, `dynatrace` releases `kubernetes.yaml` as part of their github release artifacts. Hence, we will select `Option 2`.

![Simplifying package authoring - pkg init dynatrace repository details](/images/blog/simplifying-package-authoring-dynatrace-repository-details.png)

* 

![Simplifying package authoring - pkg init vendir sync](/images/blog/simplifying-package-authoring-vendir-sync.png)
