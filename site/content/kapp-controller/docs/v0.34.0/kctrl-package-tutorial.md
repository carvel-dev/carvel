---
aliases: [/kapp-controller/docs/latest/kctrl-package-tutorial]
title: Consuming Packages using the CLI
---

## Adding a PackageRepository to the cluster
We will be using the [TCE repository](oss-packages.md#tanzu-community-edition) maintained by the contributors to TCE for this tutorial.

Lets add the repository to our cluster using `kctrl` and a link to the `imgpkg` bundle.

```bash
$ kctrl package repo add -r tce --url projects.registry.vmware.com/tce/main:0.10.0                                                                                                                                                     
Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Waiting for package repository to be added

1:43:45PM: packagerepository/tce (packaging.carvel.dev/v1alpha1) namespace: default: Reconciling
1:43:51PM: packagerepository/tce (packaging.carvel.dev/v1alpha1) namespace: default: ReconcileSucceeded

Succeeded
```

We can list available repositories to verify that the repo has been added.

```bash
$ kctrl package repo list                                                                                                                                                                                                              
Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Repositories in namespace 'default'

Name  Source                                                 Status  
tce   (imgpkg) projects.registry.vmware.com/tce/main:0.10.0  Reconcile succeeded  

Succeeded
```

Lets take a quick look at the packages added as a part of this repository.

```bash
$ kctrl package available list                                                                                                                                                                                                         
Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Available summarized packages in namespace 'default'

Name                                           Display name  
cert-manager.community.tanzu.vmware.com        cert-manager  
contour.community.tanzu.vmware.com             contour  
external-dns.community.tanzu.vmware.com        external-dns  
fluent-bit.community.tanzu.vmware.com          fluent-bit  
gatekeeper.community.tanzu.vmware.com          gatekeeper  
grafana.community.tanzu.vmware.com             grafana  
harbor.community.tanzu.vmware.com              harbor  
knative-serving.community.tanzu.vmware.com     knative-serving  
local-path-storage.community.tanzu.vmware.com  local-path-storage  
multus-cni.community.tanzu.vmware.com          multus-cni  
prometheus.community.tanzu.vmware.com          prometheus  
velero.community.tanzu.vmware.com              velero  
whereabouts.community.tanzu.vmware.com         whereabouts  

Succeeded
```
We can get more details about a particular package.

```bash
$ kctrl package available get -p cert-manager.community.tanzu.vmware.com                                                                                                                                                               
Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Name                 cert-manager.community.tanzu.vmware.com  
Display name         cert-manager  
Categories           - certificate management  
Short description    Certificate management  
Long description     Provides certificate management provisioning within the cluster  
Provider             VMware  
Maintainers          - name: Nicholas Seemiller  
Support description  Go to https://cert-manager.io/ for documentation

Version  Released at  
1.3.3    2021-08-06 18:01:21 +0530 IST  
1.4.4    2021-08-23 22:17:51 +0530 IST  
1.5.4    2021-08-23 22:52:51 +0530 IST  
1.6.1    2021-10-29 17:30:00 +0530 IST  

Succeeded
```

## Installing a Package

Lets install one of these packages. `kctrl` creates the associated resources required by the PackageInstall to create resources on the cluster.

```bash
$ kctrl package install -i cert-man -p cert-manager.community.tanzu.vmware.com --version 1.6.1                                                                                  

Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Creating service account 'cert-man-default-sa'

Creating cluster admin role 'cert-man-default-cluster-role'

Creating cluster role binding 'cert-man-default-cluster-rolebinding'

Creating package install resource

Waiting for PackageInstall reconciliation for 'cert-man'

1:56:57PM: packageinstall/cert-man (packaging.carvel.dev/v1alpha1) namespace: default: Reconciling
1:57:24PM: packageinstall/cert-man (packaging.carvel.dev/v1alpha1) namespace: default: ReconcileSucceeded

Succeeded
```
`kctrl` waits for the PackageInstall to reconcile successfully.

Users can also pass a `values.yml` file defining values to be consumed by the package using the `--values-file` flag. Let's see what values are accepted by the Cert Manager Package and supply custom values to it.

```bash
$ kctrl package available get -p cert-manager.community.tanzu.vmware.com/1.6.1 --values-schema                                                                                                                                         
Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Values schema for 'cert-manager.community.tanzu.vmware.com/1.6.1'

Key        Default       Type    Description  
namespace  cert-manager  string  The namespace in which to deploy cert-manager.  

Succeeded
```
It is worth noting that both the package name and version have to be supplied to view the values a package accepts as these might change across versions. `kctrl` accepts this in the `package-name/package-version` format.

Lets create a `values.yml` file that supplies a custom value for `namespace` to the installation.

```yaml
cat > values.yml << EOF
---
namespace: cert-man-install
EOF
```
Let's update the installation to use these values.

`kctrl` creates a secret with the values defined in the file, updates the package installation to consume it and then waits for it to reconcile to the new desired state.

```bash
$ kctrl package installed update -i cert-man --values-file values.yml                                                                                

Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Getting package install for 'cert-man'

Creating secret 'cert-man-default-values'

Updating package install for 'cert-man'

Waiting for PackageInstall reconciliation for 'cert-man'

2:07:48PM: packageinstall/cert-man (packaging.carvel.dev/v1alpha1) namespace: default: Reconciling
2:08:18PM: packageinstall/cert-man (packaging.carvel.dev/v1alpha1) namespace: default: Reconciling
2:08:28PM: packageinstall/cert-man (packaging.carvel.dev/v1alpha1) namespace: default: ReconcileSucceeded

Succeeded
```

## Deleting an installation
`kctrl` can be used to delete an installation and associated resources created with it. `kctrl` waits for them to be deleted from the cluster.
```bash
$ kctrl package installed delete -i cert-man                                                                           

Delete package install 'cert-man' from namespace 'default'

Continue? [yN]: y

Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Deleting package install 'cert-man' from namespace 'default'

Waiting for deletion of package install 'cert-man' from namespace 'default'

2:12:28PM: packageinstall/cert-man (packaging.carvel.dev/v1alpha1) namespace: default: Deleting
2:12:52PM: packageinstall/cert-man (packaging.carvel.dev/v1alpha1) namespace: default: DeletionSucceeded

Deleting 'ServiceAccount': cert-man-default-sa

Deleting 'ClusterRole': cert-man-default-cluster-role

Deleting 'ClusterRoleBinding': cert-man-default-cluster-rolebinding

Deleting 'Secret': cert-man-default-values

Succeeded
```

## Deleting an added repository
`kctrl` deletes the PackageRepository and waits till it is deleted from the cluster.

```bash
$ kctrl package repo delete -r tce                                                                                                                                                                                                     
Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

Deleting package repository 'tce' in namespace 'default'

Continue? [yN]: y

Waiting for deletion to be completed...

2:21:58PM: packagerepository/tce (packaging.carvel.dev/v1alpha1) namespace: default: Deleting
2:22:02PM: packagerepository/tce (packaging.carvel.dev/v1alpha1) namespace: default: DeletionSucceeded

Succeeded
```

## Congratulations!
You can now get up and running with published repositories and manage packages faster using `kctrl`.
