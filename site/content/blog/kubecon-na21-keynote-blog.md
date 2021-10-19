---
title: "Breaking Tradition: The Future of Package Management with Kubernetes"
slug: kubecon-na21-keynote-blog
date: 2021-10-14
author: Vibhas Kumar
excerpt: "Hello KubeCon attendees! We were thrilled to share Carvel on the keynote stage..."
image: /img/logo.svg
tags: ['Vibhas']
---

Hello, KubeCon + CloudNativeCon attendees! We were thrilled to share [Carvel on the keynote stage](https://sched.co/ocSC) with you all. This blog post will help you learn more and get started with Carvel's package manager, kapp-controller.

## The Future of Package Management

Package management on Kubernetes should be simple and without any thorns. Earlier this year we introduced [kapp-controller](/kapp-controller/) as a package manager for Kubernetes focusing on the following two key principles:

* Leveraging declarative APIs so users can focus on their desired state and let the system get them there. This also enables easy updates to the software by just updating configuration files and letting Kubernetes do what it does best in reconciling the state.

* Using immutable bundles of software distributed using OCI registries so that the users know exactly what is running on their cluster and can reproduce the state of a cluster at will. These bundles can also be relocated and deployed in an air-gapped environment.

If you want to learn more about why we created a package manager for Kubernetes, check out our [blog post](/blog/introduction-to-carvel-package-manager-for-kubernetes/) covering this topic.

## When and how would I use kapp-controller?

We built the package manager, kapp-controller, with a **layered approach** in mind so that the users can use the right abstraction depending on their use case. There are a few different use cases you can find yourself in:

1. As a developer, you have developed software that you would like to deploy to a Kubernetes cluster for your own use and keep it updated.
> - You can use the [App CR (Custom Resource)](/kapp-controller/docs/latest/app-spec/) that provides a lightweight and flexible way for you to deploy your own software to Kubernetes.

2. As a cluster operator , you have a collection of different versioned software that you would like to offer to your development teams so that they can easily discover, choose and install on their cluster.
> - We built the [kapp-controller's package management APIs](/kapp-controller/docs/latest/packaging/) that are built on top of App CR to address this so that you can package your software, distribute it, and make it discoverable to your users.

3. As a developer, you want to deploy a package on your cluster that is authored by someone else.
> - You can use the package management APIs to simply add a package repository (collection of packages) authored by someone else, discover and install the package that you want.

In the keynote demo, we used the App CR to deploy our Kubernetes application and used a Git reference as the source for fetching so that our application can stay up to date with the changes in the Git repository. Since our application required Contour’s HTTPProxy, we installed an open-source Contour package that was authored by the community. We were able to do that by just adding a package repository to the cluster and choosing a package and its version to install without caring about its internal details.

## How do I learn more and get started?

We recommend that you get started using the below resources. For any more information, our [kapp-controller overview page](/kapp-controller/) is the right place for you.

* [Install your software with App CR and keep it updated](/kapp-controller/docs/latest/walkthrough/)
* [Install your first package from an OSS Package Repository](/kapp-controller/docs/latest/package-consumption/)
* [Create your first package to distribute it to your users](/kapp-controller/docs/latest/package-authoring/)
* [Check out how the U.S. Army is using kapp-controller in production](/blog/casestudy-modernizing-the-us-army)

## Join us on Slack and GitHub

We are excited about this new adventure and we want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 900+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.

We look forward to hearing from you and hope you join us in building a strong packaging and distribution story for applications on Kubernetes!
