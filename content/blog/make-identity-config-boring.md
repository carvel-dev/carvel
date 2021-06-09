---
title: "How to Make Identity and Config Operations Boring in Kubernetes"
slug: make-identity-config-boring
date: 2020-11-13
author: Nikhita Raghunath
excerpt: "How do you plugin external identity provider using Pinniped and make your deployment process effortless using Carvel (open source set of tools)..."
image: /img/logo.svg
tags: ['Nikitha Raghunath']
---

Almost any software engineer will tell you: if they have to do the same thing more than once, they look for a way to automate it. It’s no different when managing or deploying to Kubernetes. No one wants to have to login to a system more than once a day. No one wants to reinvent the wheel when it comes to a configuration template. No one wants to manually update image references in a config file, or make sure images are built in the correct order of operations. And no one wants to manually track the changes they’ve made to their config files.

The good news is that there are tools across a couple of different projects that help with this.

## Pinniped

Let’s say you want to deploy an app to a Kubernetes cluster at work. To deploy the app, you first need access to the cluster. Since the cluster is owned by your employer, it is likely that accessing the cluster requires you to enter your credentials, and possibly perform multifactor authentication. However, you don’t want to enter your credentials each time you run `kubectl get pods`. That would be very cumbersome! So how do you avoid doing that?

[Pinniped](https://github.com/vmware-tanzu/pinniped), an open source project from VMware, makes this easy by allowing cluster administrators to plug in external identity providers (IDPs) into Kubernetes clusters. It provides a simplified login flow across all clusters. Once you have Pinniped installed on your clusters, the first time that you run a kubectl command it will prompt you to click on a URL. That URL in your browser will redirect you to interactively log in to your upstream IDP and complete authentication. Now, if you run another kubectl command, it will “just work” until your session expires. Even if you access multiple clusters across multiple regions, providers or environments, you only need to login once.

Pinniped makes it simple to consume identities from an external IDP and use those identities across many clusters. Administrators can configure external IDPs via Kubernetes custom resources. This means admins can manage Pinniped using GitOps and standard Kubernetes tools. Currently, the only IDPs supported are webhooks that implement the [Kubernetes TokenReview API](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#webhook-token-authentication). Support for more IDP types is coming soon and the complete roadmap for the project is [public](https://github.com/vmware-tanzu/pinniped/discussions/144).

## Carvel

Okay, now you can access your Kubernetes cluster. But you still need to deploy your app. [Carvel](/) is a set of open source tools — [ytt](/ytt) (YAML Templating Tool), [kbld](/kbld) and [kapp](/kapp) — that make this process effortless. The beauty of Carvel lies in the fact that each tool has a single purpose and a clear boundary. You can choose which ones to use; and there are no dependencies between the tools. So let’s see how Carvel helps in easing the deployment workflow.

As a first step, you have a [config.yaml](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/blob/develop/config-step-1-minimal/config.yml) configuration file that contains Deployment and Service configurations. To ensure that your app is extensible and can take multiple data values, let’s say you decide to customize the configs. Here’s where [ytt](/ytt) proves useful. Ytt allows templating through [annotated YAML files](/ytt/#example:example-load-data-values). Annotations are made using comments against YAML structures — like maps, arrays, etc. If you want to customize imperatively using conditionals and loops, ytt allows you to specify this in a python-like language called [Starlark](https://github.com/bazelbuild/starlark). You can also [validate](/ytt#example:example-assert) the input data by setting up assertions in Starlark. Since ytt uses structure-aware templating instead of text templating, you no longer need to scratch your head about challenges related to indentation or escaping.

While working on your app, let’s say you come across a Kubernetes Deployment configuration on the internet that you’d like to use. To make sure that the config works seamlessly with your app, you probably need to tweak a few knobs (e.g. replicas) in this third-party config file. But, you don’t want to lose track of this underlying third-party configuration. Ytt’s powerful [overlay](/ytt/docs/latest/lang-ref-ytt-overlay/) features make this very easy, by patching the config file with arbitrary changes. Ytt allows the copy of the third-party config file to remain pristine and unmodified. If you aren’t sure of the changes you are making (templating and patching are hard!), you can also try them out in an [interactive playground](/ytt#playground).

If there are any images specified in your config file, they probably need to be built and published. You can use [kbld](/kbld) to achieve this. kbld looks for images within your config file, builds the images via Docker (you can also plug in other builders) and pushes it to the registry of your choice. It even updates image references in the config file, resolving those references to an immutable digest. To make debugging easier in the future, it also annotates the Kubernetes resources with image metadata.

Now that your config file is ready, you need to deploy your app. To deploy your app, you can use `kubectl apply` directly — but kubectl doesn’t tell you what changes would be applied to the resources in your cluster. To get more transparency into the deploy process, you can use [kapp](/kapp). Kapp is a lightweight CLI tool that calculates changes between your configuration and the live cluster state; and only applies the changes you approve. Kapp is also dependency-aware. If you messed up the order of resources in your config file, kapp orders them correctly (e.g. CRDs before custom resources that need them). Kapp also tracks resources based on a uniquely generated label, so that you can delete all resources in one go with a `kapp delete` command.

## Find out More and Join Us!

You can follow the work we do and be part of ongoing discussions by participating in [Pinniped](https://github.com/vmware-tanzu/pinniped) and [Carvel](https://github.com/vmware-tanzu/carvel.dev)’s GitHub issues and [discussions](https://github.com/vmware-tanzu/pinniped/discussions) pages. To contribute, please check out the good first issues. If you or your team would like a demo, create an issue or connect with us in [#pinniped](https://kubernetes.slack.com/messages/pinniped) and [#carvel](https://kubernetes.slack.com/messages/carvel) on the Kubernetes Slack. We are very friendly and would love to hear from you!


