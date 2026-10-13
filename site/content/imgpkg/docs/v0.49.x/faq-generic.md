---
aliases: [/imgpkg/docs/latest/faq-generic]
title: FAQ
---

## Using `registry:2` and non-distributable layer

**We do not recommend the usage of `registry:2` in production**

There is a known issue when using `registry:2` image as the registry and using it as the destination of a Bundle or
Image that contains non-distributable layers.

The problem is surfaced with an error similar to

```shell
imgpkg copy \
  -b my.registry.io/some-bundle:0.0.1 \
  --to-repo localhost:5000/some-bundle
imgpkg: Error: PUT http://localhost:5000/v2/some-bundle/manifests/sha256-6195153fbf1af788bb68124fe2e0b016a1d0b6d3d8ca16cc6d23823d8a7b5445.imgpkg: multiple errors returned:
  UNKNOWN: unknown error; UNKNOWN: unknown error; map[]; MANIFEST_BLOB_UNKNOWN: blob unknown to registry; sha256:3a78847ea829208edc2d7b320b7e602b9d12e47689499d5180a9cc7790dec4d7
```

This error happens because the `registry:2` registry does a validation on non-distributable layers and checks the URL
against the provided allowed list, which is empty so it fails.

For local development this validation can be turned off. To do so start the registry using the following command

```shell
docker run --env REGISTRY_VALIDATION_DISABLED=true -d -p 5000:5000 --restart always --name registry registry:2
```
