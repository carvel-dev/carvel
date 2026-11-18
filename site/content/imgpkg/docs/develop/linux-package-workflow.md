---
title: Linux Package Workflow
---

## Scenario

You want to deploy a large number of services on development and production environments.  In addition, you want to support release of specific integrations of services.

## Prerequisites

To complete this workflow you will need access to an OCI registry like Docker Hub, and optionally, 
a Kubernetes cluster. (If you would like to use a local registry and Kubernetes cluster, try using [Kind](https://kind.sigs.k8s.io/docs/user/local-registry/))

If you would like to deploy the results of this scenario to your Kubernetes cluster, you will additionally need [`kbld`](/kbld) and kubectl.

## Example

We have two images

* `example.registry.fake/hello@sha256:4c8b96d4...`, and
* `example.registry.fake/echo@sha256:6139d4728...`.

Each image needs to be deployed to a `dev` cluster alongside the development configuration files, and separately to a `prod` cluster alongside the production configuration files.  The configuration can be represented as a `ConfigMap` containing a single key `mode` which either has either value `"dev"` or `"prod"`.

```
apiVersion: v1
kind: ConfigMap
data:
  mode: dev
```

In addition, we want to create a `metapackage` so that a well-tested integration of services can be deployed.

To achieve our goals we will

1. Create an `imgpkg` combining `example.registry.fake/hello@sha256:4c8b96d4...` and a development `ConfigMap`
    - this will be pushed to a development distribution
2. Create an `imgpkg` combining `example.registry.fake/hello@sha256:4c8b96d4...` and a production `ConfigMap`
    - this will be pushed to a production distribution

We will create similar development and production flavored packages for `example.registry.fake/echo@sha256:6139d4728...` and push them to separate distribution channels.

Finally, we will create a development flavored `metapackage` and a separate production flavored `metapackage`.  The `metapackage` will depend on specific pinned versions of the `hello` and `echo` `imgpkg`s.

## Static versus Dynamic

It is an explicit goal of this workflow to deploy static packages.  These are packages that require few, or no, `values` to be supplied at deployment time.  We avoid dynamic computation of YAML because we want to use existing tools to audit our packages.  In addition, we want to use `imgpkg` packages within teams that have strong knowledge and trust in Linux package management systems.
