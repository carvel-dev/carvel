---
aliases: [/kapp-controller/docs/latest/app-overview]
title: App CR High Level Overview
---

## Overview
kapp-controller provides a declarative way to install, manage, and upgrade applications on a Kubernetes cluster using the App CRD. Get started by installing the [latest release of kapp-controller](install.md).

## App
An App is a set of Kubernetes resources. These resources could span any number of namespaces or could be cluster-wide (e.g. CRDs). An App is represented in kapp-controller using a App CR. 

The App CR comprises of three main sections:
- spec.fetch -- declare source for fetching configuration and OCI images
- spec.template -- declare templating tool and values
- spec.deploy -- declare deployment tool and any deploy specific configuration

Full App CR spec can be found [here](app-spec.md).

### spec.fetch

App CR supports multiple source for fetching configuration and OCI images to give developers flexibility.

- `inline`: specify one or more files within resource
- `imgpkgBundle`: download [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) from registry (available in v0.17.0+)
- `image`: download Docker image from registry
- `http`: download file at URL
- `git`: clone Git repository
- `helmChart`: fetch Helm chart from Helm repository

For each fetch source, App CR supports specifying Secret resources that will be used for authenticating with the source. kapp-controller does not check for `type` value of Secret resource.

#### `image` and `imgpkgBundle` authentication

Allowed secret keys:

- `username` and `password`
- `token`: Alternative to username/password authentication

Also supports [dockerconfigjson secret type](https://kubernetes.io/docs/concepts/configuration/secret/#docker-config-secrets) (v0.19.0+)


#### `git` authentication

Allowed secret keys:

- `ssh-privatekey`: PEM-encoded key that will be provided to SSH
- `ssh-knownhosts`: Optional, set of known hosts allowed to connect (if not specified, all hosts are allowed)
- `username` and `password`: Alternative to private key authentication

#### `http` and `helmChart` authentication

Allowed secret keys:

- `username` and `password`


### spec.template

App CR supports multiple templating, overlaying, and data transformation tools to give developers flexibility.

- `helmTemplate`: uses `helm template` command to render chart
- `ytt`: uses [ytt](/ytt) to render templates
- `kbld`: uses [kbld](/kbld) to resolve image URLs to include digests
- `kustomize`: (not implemented yet) uses kustomize to render configuration
- `jsonnnet`: (not implemented yet) renders jsonnet files
- `sops`: uses [sops](https://github.com/mozilla/sops) to decrypt secrets. [More details](sops.md). Available in v0.11.0+.

---
### spec.deploy

App CR uses Carvel's `kapp` CLI to deploy.

- `kapp`: uses [kapp](/kapp) to deploy resources
