---
aliases: [/kapp-controller/docs/latest/management-command]
title: Management Commands Reference
---

## Package
Package commands provides options to interact with package repositories, available packages and package installs.

### Available packages
The `package available` group of commands can be used to get or list packages available in a namespace or all namespaces.

#### Listing available packages
The `package available list` command can be used to get a list of packages available in one or all namespaces.
```bash
$ kctrl package available list
```
A package can also be passed to get different available versions of the package.
```bash
$ kctrl package available list -p pkg.test.carvel.dev
```
Supported flags:
- `-A`, `--all-namespaces` _string_, List available packages in all namespaces
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `-p`, `--package`, _string_, List all available versions of package
- `--summary`, _boolean_, Show summarized list of packages (default true)
- `--wide`, _boolean_, Show additional info

#### Getting details of available packages
The `package available get` command can be used to get details of available packages or specific versions of a package.
```bash
$ kctrl package available get -p pkg.test.carvel.dev
# or...
$ kctrl package available get -p pkg.test.carvel.dev/1.0.0
```
The `values-schema` flag can be used to get the available values schema for a specific version of the package.
```bash
$ kctrl package available get -p pkg.test.carvel.dev/1.0.0 --values-schema
```
Supported flags:
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `-p`, `--package`, _string_, List all available versions of package
- `--values-schema`, _string_, Values schema of the package (optional)

### Installed Packages
The `package installed` group of commands can be used to view, create and update installed packages.

#### Installing a package
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
- `--service-account-name` _string_, Name of an existing service account used to install underlying package contents, optional
- `--namespace` _string_, Specified namespace for package installation
- `--dangerous-allow-use-of-shared-namespace` _boolean_, Allow installation of packages in shared namespaces (`default`, `kube-public`)
- `--wait` _boolean_, Wait for reconciliation to complete (default `true`)
- `--wait-check-interval` _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout` _duration_, Maximum amount of time to wait in wait phase (default 30m0s)
- `--values` _boolean_, Add or keep values supplied to package install, optional (default `true`)
- `--values-file` _string_, The path to the configuration values file, optional
- `--ytt-overlay-file` _string_, Path to ytt overlay file (can also be a directory)
- `--ytt-overlays` _boolean_, Add or keep ytt overlays (default true)

#### Updating an installed package
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
- `--values` _boolean_, Add or keep values supplied to package install, optional (default `true`)
- `--values-file` _string_, The path to the configuration values file, optional
- `--ytt-overlay-file` _string_, Path to ytt overlay file (can also be a directory)
- `--ytt-overlays` _boolean_, Add or keep ytt overlays (default true)

#### Listing package installs
The `package installed list` command can be used to list all installed packages.
```bash
$ kctrl package installed list
```
Supported flags:
- `-n`, `--namespace` _string_, Specify namespace where `kctrl` should look for package installs
- `-A`, `--all-namespaces` _boolean_, List installed packages in all namespaces

#### Getting details for installed package
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

#### Pausing reconciliation for a package install
The `kctrl package installed pause` command can be used to pause reconciliation for a package installation.
```bash
$ kctrl package installed pause -i cert-man
```
Supported flags:
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

#### Triggering reconciliation for package installation
The `kctrl package installed kick` command can be used to trigger reconciliation for an installed package.
```bash
$ kctrl package installed kick -i cert-man
```
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `--wait` _boolean_, Wait for reconciliation to complete (default true)
- `--wait-check-interval` _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout` _duration_, Maximum amount of time to wait in wait phase (default 5m0s)

#### Observing status of app created by package installation
The `kctrl package installed status` command can be used to observe the status of the app created by the package installation with information from the last reconciliation. The command tails and streams app status updates till the app reconciles or fails if the command is run while the installation is reconciling.
```bash
$ kctrl package installed status -i cert-man
```
Supported flags:
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

#### Deleting package installatiions
The `package installed delete` command can be used to delete package installations and resources created along with it by `kctrl`.
```bash
$ kctrl package installed delete -i cert-man
```
Created resources other than the `PackageInstall` resource might include Secrets, Service Accounts, Cluster Roles and Cluster Role Bindings which are cleaned up if they were created while installing the package using the CLI.

#### Shared flags
- `-i`, `--package-install` _string_, assigned name for a package installation

#### Created resources
If a service account name is not specified using a flag while creating a package installation, `kctrl` creates a service account, cluster role and cluster role binding to be used by the package install.

If values are specified using a values file, `kctrl` creates a secret using the values that can be consumed by the package installation.
(See [Installing a Package](packaging-tutorial.md#installing-a-package) for information on how `PackageInstall` CRs consume secrets)

These resources are tracked by using the `packaging.carvel.dev/package-...` annotations and similar annotations are added to the resources themselves to assert ownership of the resources, so that they can be safely deleted while deleting the package installation.
(See [Security Model](security-model.md) for information on how `PackageInstall` CRs use service accounts)

## Package Repositories
The `package repository` group of commands can be used to view, create and delete packages repositories.

### Adding package repositories
The `package repository add` command can be used to add a package repository to a namespace.
```bash
$ kctrl package repository add -r test-repo --url index.docker.io/k8slt/kc-e2e-test-repo:latest
```
Supported flags:
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `--dangerous-allow-use-of-shared-namespace` _boolean_, Allow addition of package repositories in shared namespaces (`default`, `kube-public`)
- `-r`, `--repository`, _string_, Set package repository name (required)
- `--secret-ref`, _string_, SecretRef name for imgpkg bundle (optional)
- `--url`, _string_, OCI registry url for package repository bundle (required)
- `--wait`, _boolean_, Wait for reconciliation to complete (default true)
- `--wait-check-interval`, _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout`, _duration_, Maximum amount of time to wait in wait phase (default 5m0s)

### Updating existing package repositories
The `package repository update` command can be used to update an existing repository.
```bash
$ kctrl package repository update -r test-repo --url index.docker.io/k8slt/kc-e2e-test-repo-2:latest
```
Supported flags:
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `-r`, `--repository`, _string_, Set package repository name (required)
- `--secret-ref`, _string_, SecretRef name for imgpkg bundle (optional)
- `--url`, _string_, OCI registry url for package repository bundle (required)
- `--wait`, _boolean_, Wait for reconciliation to complete (default true)
- `--wait-check-interval`, _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout`, _duration_, Maximum amount of time to wait in wait phase (default 5m0s)

### Listing package repositories
The `package repository list` command can be used to list existing repositories.
```bash
$ kctrl package repository list
```
Supported flags:
- `-A`, `--all-namespaces` _string_, List available packages in all namespaces
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

### Getting details for package repositories
The `package repository get` command can be used to get details of an existing package repository.
```bash
$ kctrl package repository get -r test-repo
```
Supported flags:
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `-r`, `--repository` _string_, Set package repository name (required)

### Deleting package repositories
The `package repository delete` command can be used to delete a package repository.
```bash
$ kctrl package repository delete -r test-repo
```
Supported flags:
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `-r`, `--repository` _string_, Set package repository name (required)
- `--wait`, _boolean_, Wait for reconciliation to complete (default true)
- `--wait-check-interval`, _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout`, _duration_, Maximum amount of time to wait in wait phase (default 5m0s)
## App
The app commands let users observe and interact with Apps conveniently.

### Listing apps
The `kctrl app list` command can be used to list apps.
```bash
$ kctrl app list
```
Supported flags:
- `-A`, `--all-namespaces` _boolean_, List apps in all namespaces
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

### Geting details for an app
The `kctrl app get` command can be used to get details for an app.
```bash
$ kctrl app get -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

### Observe status of an app
The `kctrl app status` command allows users to observe the status of the app with information from the last reconciliation. The command tails and streams app status updates till the app reconciles or fails if the command is run while the app is reconciling.
```bash
$ kctrl app status -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `--ignore-not-exists` _boolean_, Keep following app if it does not exist

### Pause reconciliation of an app
The `kctrl app pause` command allows pausing of periodic recopnciliation of an app.
```bash
$ kctrl app pause -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

### Trigger reconciliation of an app
The `kctrl app kick` command can be used to trigger reconciliation of a command and tail the app status till it reconciles if desired. It can also be used to restart periodic reconciliation for a paused app.
```bash
$ kctrl app kick -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `--wait` _boolean_, Wait for reconciliation to complete (default true)
- `--wait-check-interval` _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout` _duration_, Maximum amount of time to wait in wait phase (default 5m0s)

### Delete an app
The `kctrl app delete` command can be used to delete an app.
```bash
$ kctrl app delete -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `--noop` _boolean_, Ignore resources created by the app and delete the custom resource itself
- `--wait` _boolean_, Wait for reconciliation to complete (default true)
- `--wait-check-interval` _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout` _duration_, Maximum amount of time to wait in wait phase (default 5m0s)

## Global Flags
- `--color` _boolean_, Set color output (default true)
- `--column` _string_, Filter to show only given columns
- `--debug` _boolean_, Include debug output
- `-h`, `--help` _boolean_, help for kctrl
- `--json` _boolean_, Output as JSON
- `--kube-api-burst`, _int_, Set Kubernetes API client burst limit (default 1000)
- `--kube-api-qps` _float32_, Set Kubernetes API client QPS limit (default 1000)
- `--kubeconfig` _string_, Path to the kubeconfig file ($KCTRL_KUBECONFIG),
- `--kubeconfig-context`_string_, Kubeconfig context override ($KCTRL_KUBECONFIG_CONTEXT)
- `--kubeconfig-yaml` _string_, Kubeconfig contents as YAML ($KCTRL_KUBECONFIG_YAML)
- `--tty` _boolean_, Force TTY-like output (default true)
- `-v`, `--version` _boolean_, version for kctrl
- `-y`, `--yes`, _boolean_, Assumes yes for any prompt

## Environment variables

Environment Variables:
 - `FORCE_COLOR`: set to `1` to force colors to the printed. Useful to preserve colors when piping output such as in `kctrl app list --tty --all-namespaces |& less -R`
