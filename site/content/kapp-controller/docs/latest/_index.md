---
title: "About kapp-controller"
toc: "false"
cascade:
  version: latest
  toc: "true"
  type: docs
  layout: docs
---

kapp-controller provides a Kubernetes native package management and continuous delivery experience through custom resource definitions. 
These new resources for [package management](packaging.md) and [continuous delivery](app-spec.md) help users author software packages 
and consume packages to ease the process of sharing, installing, and managing software on Kubernetes. 

---

Given that software configurations for Kubernetes software can be specified in various forms:

- plain YAML configurations
- Helm charts
- ytt templates
- jsonnet templates
- etc.

and found in various locations:

- Git repository
- Archive over HTTP
- Helm repository
- etc.

and written/provided by:

- in-house development teams
- vendors offering COTS products

kapp-controller allows users to encapsulate, customize, install, and update such software in a _consistent_ and _manageable_ manner.

---

Another motivation for kapp-controller was to make a small and single purpose system (as opposed to a general CD system); hence, it's lightweight, easy-to-understand and easy-to-debug. It builds on small composable tools to achieve its goal and therefore is easy to think about.

Finally, for the fans of GitOps, kapp-controller turns [kapp](/kapp) into your _continuous_ cluster reconciler.
