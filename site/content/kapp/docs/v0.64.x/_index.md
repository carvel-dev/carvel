---
aliases: [/kapp/docs/latest/]
title: "About kapp"
toc: "false"
cascade:
  version: v0.64.x
  toc: "true"
  type: docs
  layout: docs
---

`kapp` (pronounced: `kap`) CLI encourages Kubernetes users to manage resources in bulk by working with "Kubernetes applications" (sets of resources with the same label). It focuses on resource diffing, labeling, deployment and deletion. Unlike tools like Helm, `kapp` considers YAML templating and management of packages outside of its scope, though it works great with tools that generate Kubernetes configuration.

![Kapp Deploy](/images/kapp/kapp-deploy-screenshot.png)

Features:

- Works with standard Kubernetes YAMLs
- Focuses exclusively on deployment workflow, not packaging or templating
  - but plays well with tools (such as [ytt](/ytt)) that produce Kubernetes configuration
- Converges application resources (creates, updates and/or deletes resources) in each deploy
  - based on comparison between provided files and live objects in the cluster
- Separates calculation of changes ([diff stage](diff.md)) from application of changes ([apply stage](apply.md))
- [Waits for resources](apply-waiting.md) to be "ready"
- Creates CRDs and Namespaces first and supports [custom change ordering](apply-ordering.md)
- Works [without admin privileges](rbac.md) and does not use custom CRDs
  - making it possible to use kapp as a regular user in a single namespace
- Records application deployment history
- Opt-in resource version management
  - for example, to trigger Deployment rollout when ConfigMap changes
- Optionally streams Pod logs during deploy
- Works with any group of labeled resources (`kapp -a label:tier=web inspect -t`)
- Works without server side components
- GitOps friendly (`kapp app-group deploy -g all-apps --directory .`)

## Blog posts

- [Deploying Kubernetes Applications with ytt, kbld, and kapp](/blog/deploying-apps-with-ytt-kbld-kapp)

## Talks

- [ytt and kapp @ TGI Kubernetes 079](https://www.youtube.com/watch?v=CSglwNTQiYg) with Joe Beda
- [Managing Applications in Production: Helm vs ytt & kapp @ Kubecon 2020](https://www.youtube.com/watch?v=WJw1MDFMVuk)
- [Introduction to Carvel @ Rawkode Live](https://www.youtube.com/watch?v=LBCmMTofNxw)
