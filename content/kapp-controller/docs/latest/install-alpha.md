---
title: Installing the Release Candidate
---

To install with `kapp`:

```bash
$ kapp deploy -a kc -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/alpha-releases/v0.20.0-rc.1.yml
```

To install with `kubectl`:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/alpha-releases/v0.20.0-rc.1.yml
```
