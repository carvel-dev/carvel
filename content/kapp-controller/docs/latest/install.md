---
title: Install
---

Grab the latest copy of YAML from the [Releases page](https://github.com/vmware-tanzu/carvel-kapp-controller/releases) and use your favorite deployment tool (such as [kapp](/kapp) or kubectl) to install it.

Example:

```bash
$ kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
```

or

```bash
$ kubectl apply -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
```
