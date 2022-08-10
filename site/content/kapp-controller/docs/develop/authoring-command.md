---
title: Authoring Command Reference
---

## Package

`kctrl` authoring commands help users generate resources that interact with `kapp-controllers` packaging layer.

### Initialising the package
The `package init` command takes some user inputs and creates boilerplate for package creation.  It should be run before using the `release` command. 
```bash
$ kctrl package init
```
Supported flags:
- `--chdir` _string_, Working directory with package-build and other config

Note: We always suggest to run `pkg init` in an interactive flow.
 
### Releasing the Package
The `package release` command is used to generate Package and PackageMetadata resources.
```bash
$ kctrl package release -v v1.0.0 --repo-output packages
```
Supported flags:
- `-v`, `--version` _string_, Version to be released
- `--repo-output` _string_, Output location for artifacts in repository bundle format
- `--copy-to` _string_, Output location for artifacts (default "carvel-artifacts")
- `--chdir` _string_, Working directory with package-build and other config

## Package Repository
### Releasing a Package Repository
The `package repository release` command publishes a PackageRepository using the output of `--repo-output` flag from the `package release` command.
```bash
$ kctrl package repository release 
```
Supported flags:
- `-v`, `--version` _string_, Version to be released
- `--copy-to` _string_, Output location for artifacts (default "carvel-artifacts")
- `--chdir` _string_, Working directory with package-build and other config
- `--debug` Include debug output

## Dev
`kctrl dev` is set of command to test the packages locally.

### Deploying locally
`kctrl dev deploy` command help in testing the package locally using `kapp-controller`'s APIs.
```bash
$ kctrl dev deploy
```
Supported flags:
- `--delete` Delete deployed app
- `-f`, `--file strings` Set App CR file (required)
- `-b`, `--kbld-build` Allow kbld build
- `-l`, `--local` Use local fetch source
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

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
