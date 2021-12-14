---
title: Package Command
---

## Overview
Package command provides options to interact with package repositories, available packages and package installs.

## package available
`package available` can be used to get or list packages available in a namespace or all namespaces.

### package available list
`package available list` can be used to get a list of packages available in one or all namespaces.

Example:
```bash
$ kctrl package available list
Target cluster 'https://192.168.64.53:8443' (nodes: minikube)

Available summarized packages in namespace 'default'

Name                 Display name  
test-pkg.carvel.dev  Carvel Test Package  

Succeeded

```

## Installed Packages
The `package installed` group of commands can be used to view, create and update installed packages.

### Installing a package
The `package installed create` command can be used to create a new installation. The `package install` command is a sugared alternative for the same.
```bash
$ kctrl package installed create --package-install cert-man --package cert-manager.community.tanzu.vmware.com --version 1.5.4
# or...
$ kctrl package install --package-install cert-man --package cert-manager.community.tanzu.vmware.com --version 1.5.4
```
A values file can also be passed while running this command.
```bash
$ kctrl package install --package-install cert-man --package cert-manager.community.tanzu.vmware.com --version 1.5.4 --values-file values.yml
```
Supported flags:
- `-p`, `--package` _string_, name of available package consumed by the installation
- `--version` _string_, version of package that the package install should consume
- ` --service-account-name` _string_, Name of an existing service account used to install underlying package contents, optional
- `--namespace` _string_, Specified namespace for package installation
- `--wait` _boolean_, Wait for reconciliation to complete (default `true`)
- `--wait-check-interval` _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout` _duration_, Maximum amount of time to wait in wait phase (default 30m0s)

### Updating an installed package
The `package installed update` command can be used to update an existing installation to a newer version or with a new values file.
To update to a newer version:
```bash
$ kctrl package installed update --package-install cert-man --version 1.6.1
```
To update to a newer values file:
```bash
$ kctrl package installed update --package-install cert-man --values-file updated-values.yml
```
Supported flags:
- `--version` _string_, version of package that the package install should consume
- `--install`_boolean_, Install package if the installed package does not exist (default `false`)
- `--namespace` _string_, Specified namespace to find package installation to be updated in
- `--wait` _boolean_, Wait for reconciliation to complete (default `true`)
- `--wait-check-interval` _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout` _duration_, Maximum amount of time to wait in wait phase (default 30m0s)

### Listing package installs
The `package install list` command can be used to list all installed packages.
```bash
$ kctrl package installed list
```
Supported flags:
- `-n`, `--namespace` _string_, Specify namespace where `kctrl` should look for package installs
- `-A`, `--all-namespaces` _boolean_, List installed packages in all namespaces

### Getting details for installed package
The `package installed get` command can be used to fetch information for an installed package.
```bash
$ kctrl package installed get --package-install cert-man
```
This can also be used to view the values being used with the package install.
```bash
$ kctrl package installed get --package-install cert-man --values
```
Or to download the values file consumed by the installation.
```bash
$ kctrl package installed get --package-install cert-man --values-file-output output-values.yml
```
### Shared flags
- `-i`, `--package-install` _string_, assigned name for a package installation

### Created resources
If a service account name is not specified using a flag while creating a package installation, `kctrl` creates a service account, cluster role and cluster role binding to be used by the package install.

If values are specified using a values file, `kctrl` creates a secret using the values that can be consumed by the package installation.
(See [Installing a Package](packaging-tutorial.md#installing-a-package) for information on how `PackageInstall` CRs consume secrets)

These resources are tracked by using the `packaging.carvel.dev/package-...` annotations and similar annotations are added to the resources themselves to assert ownership of the resources, so that they can be safely deleted while deleting the package installation.
(See [Security Model](security-model.md) for information on how `PackageInstall` CRs use service accounts)

## Global Flags
TODO: information about global flags (kubeconfig, color, `--yes`, etc)