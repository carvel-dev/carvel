---
title: Package Authoring Command Reference
---

# Package

## Overview
As of `kctrl` version `v0.40.0+`. Package authoring commands are introduced to smoothen the journey of packaging your manifest as a Carvel Package. As a end result this commands generate required YAML files to consume the Package or PackageRepository. By default this all commands runs in an interactive flow which can be disabled using `-y`, `--yes` flag.

## Package Init
The `package init` command takes some inputs and initialise package creation. It generates `package-build.yml` and `package-resources.yml` which get used to create a Carvel Package and PackageMetadata during `package release` stage. 
```bash
$ kctrl package init
```
Supported flags:
- `--chdir` _string_, Working directory with package-build and other config

Note: We always suggest to run `pkg init` in an interactive flow.
 
## Package Release
Once Package is initialised. The `package release` command get used to publish the Package on the given OCI registry. 
```bash
$ kctrl package release -v v1.0.0 --repo-output packages
```
Supported flags:
- `-v`, `--version` _string_, Version to be released
- `--repo-output` _string_, Output location for artifacts in repository bundle format
- `--copy-to` _string_, Output location for artifacts (default "carvel-artifacts")
- `--chdir` _string_, Working directory with package-build and other config

## Package Repository Release
The `package repository release` command help in building and creating a Carvel PackageRepository. This looks for `packages` directory in the root (which is just created by `package release` command) copy its content into a bundle and push the bundle on the given OCI registry.
```bash
$ kctrl package repository release 
```
Supported flags:
- `-v`, `--version` _string_, Version to be released
- `--copy-to` _string_, Output location for artifacts (default "carvel-artifacts")
- `--chdir` _string_, Working directory with package-build and other config
- `--debug` Include debug output

# Dev

## Some Other Useful Flags
- `--debug` _boolean_, Include debug output
- `-h`, `--help` _boolean_, help for kctrl
- `--tty` Force TTY-like output
- `--color` _boolean_, Set color output (default true)
- `--column` _string_, Filter to show only given columns
- `--json` _boolean_, Output as JSON
- `--kube-api-burst`, _int_, Set Kubernetes API client burst limit (default 1000)
- `--kube-api-qps` _float32_, Set Kubernetes API client QPS limit (default 1000)
- `--kubeconfig` _string_, Path to the kubeconfig file ($KCTRL_KUBECONFIG),
- `--kubeconfig-context`_string_, Kubeconfig context override ($KCTRL_KUBECONFIG_CONTEXT)
- `--kubeconfig-yaml` _string_, Kubeconfig contents as YAML ($KCTRL_KUBECONFIG_YAML)
