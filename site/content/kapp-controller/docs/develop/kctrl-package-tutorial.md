---
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

3:05:42PM: Creating service account 'cert-man-default-sa'
3:05:42PM: Creating cluster admin role 'cert-man-default-cluster-role'
3:05:43PM: Creating cluster role binding 'cert-man-default-cluster-rolebinding'
3:05:43PM: Creating package install resource
3:05:43PM: Waiting for PackageInstall reconciliation for 'cert-man'
3:05:44PM: Fetch started (1s ago)
3:05:45PM: Fetching 
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - imgpkgBundle:
	    |       image: projects.registry.vmware.com/tce/cert-manager@sha256:ca4c551c1e9c5bc0e2b554f20651c9538c97a1159ccf9c9b640457e18cdec039
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    | 
3:05:45PM: Fetch succeeded 
3:05:47PM: Template succeeded 
3:05:47PM: Deploy started (1s ago)
3:05:49PM: Deploying 
	    | Target cluster 'https://10.92.0.1:443' (nodes: gke-cluster-sm-default-pool-28d3ddcd-gjqs, 2+)
	    | Changes
	    | Namespace     Name                                                Kind                            Conds.  Age  Op      Op st.  Wait to    Rs  Ri
	    | (cluster)     cert-manager                                        Namespace                       -       -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector                             ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector                             ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-approve:cert-manager-io     ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-approve:cert-manager-io     ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-certificates                ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-certificates                ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-certificatesigningrequests  ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-certificatesigningrequests  ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-challenges                  ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-challenges                  ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-clusterissuers              ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-clusterissuers              ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-ingress-shim                ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-ingress-shim                ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-issuers                     ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-issuers                     ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-orders                      ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-orders                      ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             cert-manager-edit                                   ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-view                                   ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                MutatingWebhookConfiguration    -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                ValidatingWebhookConfiguration  -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook:subjectaccessreviews           ClusterRole                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook:subjectaccessreviews           ClusterRoleBinding              -       -    create  -       reconcile  -   -
	    | ^             certificaterequests.cert-manager.io                 CustomResourceDefinition        -       -    create  -       reconcile  -   -
	    | ^             certificates.cert-manager.io                        CustomResourceDefinition        -       -    create  -       reconcile  -   -
	    | ^             challenges.acme.cert-manager.io                     CustomResourceDefinition        -       -    create  -       reconcile  -   -
	    | ^             clusterissuers.cert-manager.io                      CustomResourceDefinition        -       -    create  -       reconcile  -   -
	    | ^             issuers.cert-manager.io                             CustomResourceDefinition        -       -    create  -       reconcile  -   -
	    | ^             orders.acme.cert-manager.io                         CustomResourceDefinition        -       -    create  -       reconcile  -   -
	    | cert-manager  cert-manager                                        Deployment                      -       -    create  -       reconcile  -   -
	    | ^             cert-manager                                        Service                         -       -    create  -       reconcile  -   -
	    | ^             cert-manager                                        ServiceAccount                  -       -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector                             Deployment                      -       -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector                             ServiceAccount                  -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                Deployment                      -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                Service                         -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                ServiceAccount                  -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook:dynamic-serving                Role                            -       -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook:dynamic-serving                RoleBinding                     -       -    create  -       reconcile  -   -
	    | kube-system   cert-manager-cainjector:leaderelection              Role                            -       -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector:leaderelection              RoleBinding                     -       -    create  -       reconcile  -   -
	    | ^             cert-manager:leaderelection                         Role                            -       -    create  -       reconcile  -   -
	    | ^             cert-manager:leaderelection                         RoleBinding                     -       -    create  -       reconcile  -   -
	    | Op:      45 create, 0 delete, 0 update, 0 noop, 0 exists
	    | Wait to: 45 reconcile, 0 delete, 0 noop
	    | 9:35:49AM: ---- applying 23 changes [0/45 done] ----
	    | 9:35:49AM: create validatingwebhookconfiguration/cert-manager-webhook (admissionregistration.k8s.io/v1) cluster
	    | 9:35:49AM: create clusterrole/cert-manager-controller-certificates (rbac.authorization.k8s.io/v1) cluster
	    | 9:35:49AM: create clusterrole/cert-manager-controller-orders (rbac.authorization.k8s.io/v1) cluster
	    | 9:35:49AM: create clusterrole/cert-manager-controller-ingress-shim (rbac.authorization.k8s.io/v1) cluster
	    | 9:35:49AM: create clusterrole/cert-manager-controller-challenges (rbac.authorization.k8s.io/v1) cluster
	    | 9:35:49AM: create clusterrole/cert-manager-controller-approve:cert-manager-io (rbac.authorization.k8s.io/v1) cluster
	    | 9:35:49AM: create clusterrole/cert-manager-edit (rbac.authorization.k8s.io/v1) cluster
	    | 9:35:49AM: create clusterrole/cert-manager-view (rbac.authorization.k8s.io/v1) cluster
	    | 9:35:49AM: create clusterrole/cert-manager-controller-certificatesigningrequests (rbac.authorization.k8s.io/v1) cluster
	    # ....
        # .
        # .
        # .
        # ....
	    | 9:35:59AM:  ^ Waiting for 1 unavailable replicas
	    | 9:35:59AM:  L ok: waiting on replicaset/cert-manager-cainjector-5588886b68 (apps/v1) namespace: cert-manager
	    | 9:35:59AM:  L ongoing: waiting on pod/cert-manager-cainjector-5588886b68-26pwz (v1) namespace: cert-manager
	    | 9:35:59AM:     ^ Pending: ContainerCreating
	    | 9:36:00AM: ongoing: reconcile deployment/cert-manager-webhook (apps/v1) namespace: cert-manager
	    | 9:36:00AM:  ^ Waiting for 1 unavailable replicas
	    | 9:36:00AM:  L ok: waiting on replicaset/cert-manager-webhook-57b5dfd498 (apps/v1) namespace: cert-manager
	    | 9:36:00AM:  L ongoing: waiting on pod/cert-manager-webhook-57b5dfd498-pdx86 (v1) namespace: cert-manager
	    | 9:36:00AM:     ^ Condition Ready is not True (False)
	    | 9:36:01AM: ok: reconcile deployment/cert-manager (apps/v1) namespace: cert-manager
	    | 9:36:01AM: ok: reconcile deployment/cert-manager-cainjector (apps/v1) namespace: cert-manager
	    | 9:36:01AM: ---- waiting on 1 changes [44/45 done] ----
	    | 9:36:08AM: ok: reconcile deployment/cert-manager-webhook (apps/v1) namespace: cert-manager
	    | 9:36:08AM: ---- applying complete [45/45 done] ----
	    | 9:36:08AM: ---- waiting complete [45/45 done] ----
	    | Succeeded
3:06:09PM: App reconciled 

Succeeded
```
(_deploy output truncated_)

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

3:10:05PM: Getting package install for 'cert-man'
3:10:06PM: Creating secret 'cert-man-default-values'
3:10:06PM: Updating package install for 'cert-man'
3:10:06PM: Waiting for PackageInstall reconciliation for 'cert-man'
3:10:08PM: Fetching 
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - imgpkgBundle:
	    |       image: projects.registry.vmware.com/tce/cert-manager@sha256:ca4c551c1e9c5bc0e2b554f20651c9538c97a1159ccf9c9b640457e18cdec039
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    | 
3:10:08PM: Fetch succeeded 
3:10:10PM: Template succeeded 
3:10:10PM: Deploy started (1s ago)
3:10:12PM: Deploying 
	    | Target cluster 'https://10.92.0.1:443' (nodes: gke-cluster-sm-default-pool-28d3ddcd-gjqs, 2+)
	    | Changes
	    | Namespace         Name                                                Kind                            Conds.  Age  Op      Op st.  Wait to    Rs  Ri
	    | (cluster)         cert-man-install                                    Namespace                       -       -    create  -       reconcile  -   -
	    | ^                 cert-manager                                        Namespace                       -       4m   delete  -       delete     ok  -
	    | ^                 cert-manager-cainjector                             ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-controller-approve:cert-manager-io     ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-controller-certificates                ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-controller-certificatesigningrequests  ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-controller-challenges                  ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-controller-clusterissuers              ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-controller-ingress-shim                ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-controller-issuers                     ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-controller-orders                      ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-webhook                                MutatingWebhookConfiguration    -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-webhook                                ValidatingWebhookConfiguration  -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager-webhook:subjectaccessreviews           ClusterRoleBinding              -       4m   update  -       reconcile  ok  -
	    | ^                 certificaterequests.cert-manager.io                 CustomResourceDefinition        2/2 t   4m   update  -       reconcile  ok  -
	    | ^                 certificates.cert-manager.io                        CustomResourceDefinition        2/2 t   4m   update  -       reconcile  ok  -
	    | ^                 challenges.acme.cert-manager.io                     CustomResourceDefinition        2/2 t   4m   update  -       reconcile  ok  -
	    | ^                 clusterissuers.cert-manager.io                      CustomResourceDefinition        2/2 t   4m   update  -       reconcile  ok  -
	    | ^                 issuers.cert-manager.io                             CustomResourceDefinition        2/2 t   4m   update  -       reconcile  ok  -
	    | ^                 orders.acme.cert-manager.io                         CustomResourceDefinition        2/2 t   4m   update  -       reconcile  ok  -
	    | cert-man-install  cert-manager                                        Deployment                      -       -    create  -       reconcile  -   -
	    | ^                 cert-manager                                        Service                         -       -    create  -       reconcile  -   -
	    | ^                 cert-manager                                        ServiceAccount                  -       -    create  -       reconcile  -   -
	    | ^                 cert-manager-cainjector                             Deployment                      -       -    create  -       reconcile  -   -
	    | ^                 cert-manager-cainjector                             ServiceAccount                  -       -    create  -       reconcile  -   -
	    | ^                 cert-manager-webhook                                Deployment                      -       -    create  -       reconcile  -   -
	    | ^                 cert-manager-webhook                                Service                         -       -    create  -       reconcile  -   -
	    | ^                 cert-manager-webhook                                ServiceAccount                  -       -    create  -       reconcile  -   -
	    | ^                 cert-manager-webhook:dynamic-serving                Role                            -       -    create  -       reconcile  -   -
	    | ^                 cert-manager-webhook:dynamic-serving                RoleBinding                     -       -    create  -       reconcile  -   -
	    | cert-manager      cert-manager                                        Deployment                      2/2 t   4m   delete  -       delete     ok  -
	    | ^                 cert-manager                                        Service                         -       4m   delete  -       delete     ok  -
	    | ^                 cert-manager                                        ServiceAccount                  -       4m   delete  -       delete     ok  -
	    | ^                 cert-manager-cainjector                             Deployment                      2/2 t   4m   delete  -       delete     ok  -
	    | ^                 cert-manager-cainjector                             ServiceAccount                  -       4m   delete  -       delete     ok  -
	    | ^                 cert-manager-webhook                                Deployment                      2/2 t   4m   delete  -       delete     ok  -
	    | ^                 cert-manager-webhook                                Service                         -       4m   delete  -       delete     ok  -
	    | ^                 cert-manager-webhook                                ServiceAccount                  -       4m   delete  -       delete     ok  -
	    | ^                 cert-manager-webhook:dynamic-serving                Role                            -       4m   delete  -       delete     ok  -
	    | ^                 cert-manager-webhook:dynamic-serving                RoleBinding                     -       4m   delete  -       delete     ok  -
	    | kube-system       cert-manager-cainjector:leaderelection              RoleBinding                     -       4m   update  -       reconcile  ok  -
	    | ^                 cert-manager:leaderelection                         RoleBinding                     -       4m   update  -       reconcile  ok  -
	    | Op:      11 create, 11 delete, 20 update, 0 noop, 0 exists
	    | Wait to: 31 reconcile, 11 delete, 0 noop
	    | 9:40:25AM: ---- applying 20 changes [0/42 done] ----
	    | 9:40:25AM: delete serviceaccount/cert-manager (v1) namespace: cert-manager
	    | 9:40:25AM: delete deployment/cert-manager-cainjector (apps/v1) namespace: cert-manager
	    | 9:40:25AM: delete deployment/cert-manager-webhook (apps/v1) namespace: cert-manager
	    | 9:40:25AM: delete role/cert-manager-webhook:dynamic-serving (rbac.authorization.k8s.io/v1) namespace: cert-manager
	    | 9:40:25AM: delete rolebinding/cert-manager-webhook:dynamic-serving (rbac.authorization.k8s.io/v1) namespace: cert-manager
	    | 9:40:25AM: delete serviceaccount/cert-manager-cainjector (v1) namespace: cert-manager
	    | 9:40:25AM: delete deployment/cert-manager (apps/v1) namespace: cert-manager
	    | 9:40:25AM: delete serviceaccount/cert-manager-webhook (v1) namespace: cert-manager
	    | 9:40:25AM: delete service/cert-manager-webhook (v1) namespace: cert-manager
	    | 9:40:25AM: delete namespace/cert-manager (v1) cluster
	    | 9:40:25AM: delete service/cert-manager (v1) namespace: cert-manager
	    | 9:40:26AM: update customresourcedefinition/certificaterequests.cert-manager.io (apiextensions.k8s.io/v1) cluster
	    # ....
        # .
        # .
        # .
        # ....
	    | 9:40:37AM: ---- waiting on 1 changes [41/42 done] ----
	    | 9:40:43AM: ok: reconcile deployment/cert-manager-webhook (apps/v1) namespace: cert-man-install
	    | 9:40:43AM: ---- applying complete [42/42 done] ----
	    | 9:40:43AM: ---- waiting complete [42/42 done] ----
	    | Succeeded
3:10:43PM: App reconciled 


Succeeded
```
(_deploy output truncated_)

## Deleting an installation
`kctrl` can be used to delete an installation and associated resources created with it. `kctrl` waits for them to be deleted from the cluster.
```bash
$ kctrl package installed delete -i cert-man                                                                           

Delete package install 'cert-man' from namespace 'default'

Continue? [yN]: y

Target cluster 'https://127.0.0.1:56457' (nodes: minikube)

3:12:41PM: Deleting package install 'cert-man' from namespace 'default'
3:12:41PM: Waiting for deletion of package install 'cert-man' from namespace 'default'
3:12:42PM: Delete started (1s ago)
3:12:44PM: Deleting 
	    | Target cluster 'https://10.92.0.1:443' (nodes: gke-cluster-sm-default-pool-28d3ddcd-gjqs, 2+)
	    | Changes
	    | Namespace         Name                                                Kind                            Conds.  Age  Op      Op st.  Wait to  Rs  Ri
	    | (cluster)         cert-man-install                                    Namespace                       -       2m   delete  -       delete   ok  -
	    | ^                 cert-manager-cainjector                             ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-cainjector                             ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-approve:cert-manager-io     ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-approve:cert-manager-io     ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-certificates                ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-certificates                ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-certificatesigningrequests  ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-certificatesigningrequests  ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-challenges                  ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-challenges                  ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-clusterissuers              ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-clusterissuers              ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-ingress-shim                ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-ingress-shim                ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-issuers                     ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-issuers                     ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-orders                      ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-controller-orders                      ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-edit                                   ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-view                                   ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-webhook                                MutatingWebhookConfiguration    -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-webhook                                ValidatingWebhookConfiguration  -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-webhook:subjectaccessreviews           ClusterRole                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-webhook:subjectaccessreviews           ClusterRoleBinding              -       6m   delete  -       delete   ok  -
	    | ^                 certificaterequests.cert-manager.io                 CustomResourceDefinition        2/2 t   6m   delete  -       delete   ok  -
	    | ^                 certificates.cert-manager.io                        CustomResourceDefinition        2/2 t   6m   delete  -       delete   ok  -
	    | ^                 challenges.acme.cert-manager.io                     CustomResourceDefinition        2/2 t   6m   delete  -       delete   ok  -
	    | ^                 clusterissuers.cert-manager.io                      CustomResourceDefinition        2/2 t   6m   delete  -       delete   ok  -
	    | ^                 issuers.cert-manager.io                             CustomResourceDefinition        2/2 t   6m   delete  -       delete   ok  -
	    | ^                 orders.acme.cert-manager.io                         CustomResourceDefinition        2/2 t   6m   delete  -       delete   ok  -
	    | cert-man-install  cert-manager                                        Deployment                      2/2 t   2m   delete  -       delete   ok  -
	    | ^                 cert-manager                                        Endpoints                       -       2m   -       -       delete   ok  -
	    | ^                 cert-manager                                        Service                         -       2m   delete  -       delete   ok  -
	    | ^                 cert-manager                                        ServiceAccount                  -       2m   delete  -       delete   ok  -
	    | ^                 cert-manager-7b9d7974f                              ReplicaSet                      -       2m   -       -       delete   ok  -
	    | ^                 cert-manager-7b9d7974f-s47vm                        Pod                             4/4 t   2m   -       -       delete   ok  -
	    | ^                 cert-manager-cainjector                             Deployment                      2/2 t   2m   delete  -       delete   ok  -
	    | ^                 cert-manager-cainjector                             ServiceAccount                  -       2m   delete  -       delete   ok  -
	    | ^                 cert-manager-cainjector-6d9d6b7c5b                  ReplicaSet                      -       2m   -       -       delete   ok  -
	    | ^                 cert-manager-cainjector-6d9d6b7c5b-sgjlc            Pod                             4/4 t   2m   -       -       delete   ok  -
	    | ^                 cert-manager-kp9sj                                  EndpointSlice                   -       2m   -       -       delete   ok  -
	    | ^                 cert-manager-webhook                                Deployment                      2/2 t   2m   delete  -       delete   ok  -
	    | ^                 cert-manager-webhook                                Endpoints                       -       2m   -       -       delete   ok  -
	    | ^                 cert-manager-webhook                                Service                         -       2m   delete  -       delete   ok  -
	    | ^                 cert-manager-webhook                                ServiceAccount                  -       2m   delete  -       delete   ok  -
	    | ^                 cert-manager-webhook-56676b8df7                     ReplicaSet                      -       2m   -       -       delete   ok  -
	    | ^                 cert-manager-webhook-56676b8df7-hl62t               Pod                             4/4 t   2m   -       -       delete   ok  -
	    | ^                 cert-manager-webhook-5r7jg                          EndpointSlice                   -       2m   -       -       delete   ok  -
	    | ^                 cert-manager-webhook:dynamic-serving                Role                            -       2m   delete  -       delete   ok  -
	    | ^                 cert-manager-webhook:dynamic-serving                RoleBinding                     -       2m   delete  -       delete   ok  -
	    | kube-system       cert-manager-cainjector:leaderelection              Role                            -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager-cainjector:leaderelection              RoleBinding                     -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager:leaderelection                         Role                            -       6m   delete  -       delete   ok  -
	    | ^                 cert-manager:leaderelection                         RoleBinding                     -       6m   delete  -       delete   ok  -
	    | Op:      0 create, 45 delete, 0 update, 10 noop, 0 exists
	    | Wait to: 0 reconcile, 55 delete, 0 noop
	    | 9:42:47AM: ---- applying 16 changes [0/55 done] ----
	    | 9:42:47AM: noop pod/cert-manager-7b9d7974f-s47vm (v1) namespace: cert-man-install
	    | 9:42:47AM: noop endpointslice/cert-manager-webhook-5r7jg (discovery.k8s.io/v1) namespace: cert-man-install
	    | 9:42:47AM: noop endpointslice/cert-manager-kp9sj (discovery.k8s.io/v1) namespace: cert-man-install
	    | 9:42:47AM: noop endpoints/cert-manager (v1) namespace: cert-man-install
	    | 9:42:47AM: noop replicaset/cert-manager-cainjector-6d9d6b7c5b (apps/v1) namespace: cert-man-install
	    | 9:42:47AM: noop replicaset/cert-manager-webhook-56676b8df7 (apps/v1) namespace: cert-man-install
	    | 9:42:47AM: noop replicaset/cert-manager-7b9d7974f (apps/v1) namespace: cert-man-install
	    | 9:42:47AM: delete customresourcedefinition/orders.acme.cert-manager.io (apiextensions.k8s.io/v1) cluster
	    | 9:42:47AM: noop endpoints/cert-manager-webhook (v1) namespace: cert-man-install
	    | 9:42:47AM: noop pod/cert-manager-cainjector-6d9d6b7c5b-sgjlc (v1) namespace: cert-man-install
	    | 9:42:47AM: delete customresourcedefinition/certificaterequests.cert-manager.io (apiextensions.k8s.io/v1) cluster
	    | 9:42:47AM: noop pod/cert-manager-webhook-56676b8df7-hl62t (v1) namespace: cert-man-install
	    | 9:42:47AM: delete customresourcedefinition/clusterissuers.cert-manager.io (apiextensions.k8s.io/v1) cluster
	    | 9:42:47AM: delete customresourcedefinition/issuers.cert-manager.io (apiextensions.k8s.io/v1) cluster
	    | 9:42:47AM: delete customresourcedefinition/certificates.cert-manager.io (apiextensions.k8s.io/v1) cluster
	    | 9:42:48AM: delete customresourcedefinition/challenges.acme.cert-manager.io (apiextensions.k8s.io/v1) cluster
        # ....
        # .
        # .
        # .
        # ....
3:13:03PM: App 'cert-man' in namespace 'default' deleted 
3:13:03PM: packageinstall/cert-man (packaging.carvel.dev/v1alpha1) namespace: default: DeletionSucceeded
3:13:03PM: Deleting 'Secret': cert-man-default-values
3:13:04PM: Deleting 'ServiceAccount': cert-man-default-sa
3:13:04PM: Deleting 'ClusterRole': cert-man-default-cluster-role
3:13:04PM: Deleting 'ClusterRoleBinding': cert-man-default-cluster-rolebinding
Succeeded
```
(_delete output truncated_)

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