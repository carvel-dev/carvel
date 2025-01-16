---
aliases: [/kapp-controller/docs/latest/]
title: "About kapp-controller"
toc: "false"
cascade:
  version: v0.55.x
  toc: "true"
  type: docs
  layout: docs
---

kapp-controller provides declarative APIs to customize, install, and update your Kubernetes applications and packages. It is a part of the Carvel toolkit and follows core Carvel design principles. Get started with the [tutorial](packaging-tutorial.md)!

The kapp-controller CLI `kctrl` ("k-control") helps users to observe and interact custom resources surfaced by kapp-controller effectively. It also allows package consumers get up and running with Carvel packages faster.

#### Choice for authors; consistency for consumers
Kubernetes configuration takes many forms -- plain YAML configurations, Helm charts, ytt templates, jsonnet templates, etc.
Software running on Kubernetes lives in many different places: a Git repository, an archive over HTTP, a Helm repository, etc.

kapp-controller provides software authors flexibility to choose their own configuration tools, while providing software consumers with consistent declarative APIs to customize, install, and update software on Kubernetes from various sources.

#### Lightweight and composable
kapp-controller breaks down the installation of applications and packages into three easy to understand steps: 
- Fetch: get configuration and OCI images from various sources including a Git repository, a local ConfigMap, a Helm chart, an OCI registry, etc.
- Template: take user provided values to customize software using ytt templates, helm templates, and more
- Deploy: create/update resources on the cluster

#### GitOps and Continuous Delivery
With its layered approach, kapp-controller can be used as:
- Continuous delivery for Kubernetes applications using [App CR](app-spec.md)
- Kubernetes Package Management using [Package CR and supplementary CRs](packaging.md)
- Managing applications and packages using GitOps

#### Share software and build distributions
Use kapp-controller's Package Management features along with Carvel's imgpkg bundles to distribute Package Repositories that can be added to cluster to provide a catalog of software for users to install. Package Repositries can be automatically updated ensuring users always have access to latest versions of software. Package Repositories and Packages can also be relocated and run in air-gapped environments.

#### Reliable and ready for production!
kapp-controller has been hardened and is in use on production Kubernetes clusters. Learn more through [case studies](/blog/casestudy-modernizing-the-us-army) on our blog.
