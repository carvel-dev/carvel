---
aliases: [/kapp-controller/docs/latest/dev]
title: Development & Deploy
---

Install ytt, kbld, kapp beforehand (https://carvel.dev).

```
./hack/build.sh # to build locally

# add `-v image_repo=docker.io/username/kapp-controller` with your registry to ytt invocation inside
./hack/deploy.sh # to deploy

export KAPPCTRL_E2E_NAMESPACE=kappctrl-test
./hack/test-all.sh
```

## Release

```
# Bump version in cmd/controller/main.go
# Commit
./hack/build-release.sh
```
