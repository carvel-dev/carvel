---
aliases: [/kapp-controller/docs/latest/kctrl-package-tutorial]
title: Consuming Packages using the CLI
---

## Adding a PackageRepository to the cluster
We will be using the [kadras-packages](https://github.com/kadras-io/kadras-packages) repository for this tutorial.

Lets add the repository to our cluster using `kctrl` and a link to the `imgpkg` bundle.

```bash
$ kctrl package repo add -r kadras-packages --url ghcr.io/kadras-io/kadras-packages -n kadras-system --create-namespace                                                                                                                            
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

7:47:58PM: Created namespace 'kadras-system'

Waiting for package repository to be added

7:47:59PM: Waiting for package repository reconciliation for 'kadras-packages'
7:47:59PM: Fetch started (6s ago)
7:48:06PM: Fetching
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - imgpkgBundle:
	    |       image: ghcr.io/kadras-io/kadras-packages@sha256:350b0db26791b4315b4a4d9767b952241e52cbeef7c2c5f3c520a77d6d203274
	    |       tag: 0.17.3
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    |
7:48:06PM: Fetch succeeded
7:48:07PM: Template succeeded
7:48:07PM: Deploy started
7:48:08PM: Deploying
	    | Target cluster 'https://10.96.0.1:443'
	    | Changes
	    | Namespace      Name                                            Kind             Age  Op      Op st.                      Wait to  Rs  Ri
	    | kadras-system  buildpacks-catalog.packages.kadras.io           PackageMetadata  -    create  fallback on update or noop  -        -   -
	    | ^              buildpacks-catalog.packages.kadras.io.0.10.0    Package          -    create  fallback on update or noop  -        -   -
	    | ^              cert-manager-issuers.packages.kadras.io         PackageMetadata  -    create  fallback on update or noop  -        -   -
	    | ^              cert-manager-issuers.packages.kadras.io.0.2.3   Package          -    create  fallback on update or noop  -        -   -
	    | ^              cert-manager.packages.kadras.io                 PackageMetadata  -    create  fallback on update or noop  -        -   -
	    | ^              cert-manager.packages.kadras.io.1.14.4          Package          -    create  fallback on update or noop  -        -   -
	    | ^              contour.packages.kadras.io                      PackageMetadata  -    create  fallback on update or noop  -        -   -
		# ....
        # .
        # .
        # .
        # ....
	    | 2:18:08PM: ok: noop packagemetadata/cert-manager.packages.kadras.io (data.packaging.carvel.dev/v1alpha1) namespace: kadras-system
	    | 2:18:08PM: ok: noop packagemetadata/cert-manager-issuers.packages.kadras.io (data.packaging.carvel.dev/v1alpha1) namespace: kadras-system
	    | 2:18:08PM: ---- applying complete [42/42 done] ----
	    | 2:18:08PM: ---- waiting complete [42/42 done] ----
	    | Succeeded
7:48:08PM: Deploy succeeded

Succeeded
```
(_deploy output truncated_)

We can list available repositories to verify that the repo has been added.

```bash
$ kctrl package repository list -n kadras-system
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

Repositories in namespace 'kadras-system'

Name             Source                                      Status
kadras-packages  (imgpkg) ghcr.io/kadras-io/kadras-packages  Reconcile succeeded

Succeeded
```

Lets take a quick look at the packages added as a part of this repository.

```bash
$ kctrl package available list -n kadras-system
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

Available summarized packages in namespace 'kadras-system'

Name                                      Display name
buildpacks-catalog.packages.kadras.io     buildpacks-catalog
cert-manager-issuers.packages.kadras.io   cert-manager-issuers
cert-manager.packages.kadras.io           cert-manager
contour.packages.kadras.io                contour
crossplane.packages.kadras.io             crossplane
dapr.packages.kadras.io                   dapr
developer-portal.packages.kadras.io       developer-portal
engineering-platform.packages.kadras.io   engineering-platform
flux.packages.kadras.io                   flux
gitops-configurer.packages.kadras.io      gitops-configurer
knative-serving.packages.kadras.io        knative-serving
kpack.packages.kadras.io                  kpack
kyverno.packages.kadras.io                kyverno
metrics-server.packages.kadras.io         metrics-server
rabbitmq-operator.packages.kadras.io      rabbitmq-operator
rbac-configurer.packages.kadras.io        rbac-configurer
secretgen-controller.packages.kadras.io   secretgen-controller
service-binding.packages.kadras.io        service-binding
tekton-pipelines.packages.kadras.io       tekton-pipelines
weaviate.packages.kadras.io               weaviate
workspace-provisioner.packages.kadras.io  workspace-provisioner

Succeeded
```
We can get more details about a particular package.

```bash
$ kctrl package available get -p cert-manager.packages.kadras.io -n kadras-system
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

Name                 cert-manager.packages.kadras.io
Display name         cert-manager
Categories           - certificate-management
                     - security
                     - tls
Short description    X.509 certificate management for Kubernetes and OpenShift.
Long description     Adds certificates and certificate issuers as resource types in Kubernetes
                     clusters, and simplifies the process of obtaining, renewing and using those
                     certificates. It can issue certificates from a variety of supported sources. It
                     will ensure certificates are valid and up to date, and attempt to renew
                     certificates at a configured time before expiry.
Provider             Kadras
Maintainers          - name: Thomas Vitale
Support description  Go to https://kadras.io for documentation and
                     https://github.com/kadras-io/package-for-cert-manager for community support.

Version  Released at
1.14.4   2024-03-11 21:50:10 +0530 IST

Succeeded
```

## Installing a Package

Lets install one of these packages. `kctrl` creates the associated resources required by the PackageInstall to create resources on the cluster.

```bash
$ kctrl package install -i cert-manager -p cert-manager.packages.kadras.io -v 1.14.4 -n kadras-system
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

8:03:13PM: Creating service account 'cert-manager-kadras-system-sa'
8:03:13PM: Creating cluster admin role 'cert-manager-kadras-system-cluster-role'
8:03:13PM: Creating cluster role binding 'cert-manager-kadras-system-cluster-rolebinding'
8:03:13PM: Creating overlay secrets
8:03:13PM: Creating package install resource
8:03:13PM: Waiting for PackageInstall reconciliation for 'cert-manager'
8:03:14PM: Fetch started (3s ago)
8:03:18PM: Fetching
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - imgpkgBundle:
	    |       image: ghcr.io/kadras-io/package-for-cert-manager@sha256:d71e3e3afac1ec3d66fd086f8d201778bac0e5ddfc1d12b8a4356e4a0090a00c
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    |
8:03:18PM: Fetch succeeded
8:03:19PM: Template succeeded
8:03:19PM: Deploy started (1s ago)
8:03:21PM: Deploying
	    | Target cluster 'https://10.96.0.1:443' (nodes: minikube)
	    | Changes
	    | Namespace     Name                                                Kind                            Age  Op      Op st.  Wait to    Rs  Ri
	    | (cluster)     cert-manager                                        Namespace                       -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector                             ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector                             ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-cluster-view                           ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-approve:cert-manager-io     ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-approve:cert-manager-io     ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-certificates                ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-certificates                ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-certificatesigningrequests  ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-certificatesigningrequests  ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-challenges                  ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-challenges                  ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-clusterissuers              ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-clusterissuers              ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-ingress-shim                ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-ingress-shim                ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-issuers                     ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-issuers                     ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-orders                      ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-controller-orders                      ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             cert-manager-edit                                   ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-view                                   ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                MutatingWebhookConfiguration    -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                ValidatingWebhookConfiguration  -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook:subjectaccessreviews           ClusterRole                     -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook:subjectaccessreviews           ClusterRoleBinding              -    create  -       reconcile  -   -
	    | ^             certificaterequests.cert-manager.io                 CustomResourceDefinition        -    create  -       reconcile  -   -
	    | ^             certificates.cert-manager.io                        CustomResourceDefinition        -    create  -       reconcile  -   -
	    | ^             challenges.acme.cert-manager.io                     CustomResourceDefinition        -    create  -       reconcile  -   -
	    | ^             clusterissuers.cert-manager.io                      CustomResourceDefinition        -    create  -       reconcile  -   -
	    | ^             issuers.cert-manager.io                             CustomResourceDefinition        -    create  -       reconcile  -   -
	    | ^             orders.acme.cert-manager.io                         CustomResourceDefinition        -    create  -       reconcile  -   -
	    | cert-manager  canonical-registry-credentials                      Secret                          -    create  -       reconcile  -   -
	    | ^             cert-manager                                        Deployment                      -    create  -       reconcile  -   -
	    | ^             cert-manager                                        Service                         -    create  -       reconcile  -   -
	    | ^             cert-manager                                        ServiceAccount                  -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector                             Deployment                      -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector                             ServiceAccount                  -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                Deployment                      -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                Service                         -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook                                ServiceAccount                  -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook:dynamic-serving                Role                            -    create  -       reconcile  -   -
	    | ^             cert-manager-webhook:dynamic-serving                RoleBinding                     -    create  -       reconcile  -   -
	    | kube-system   cert-manager-cainjector:leaderelection              Role                            -    create  -       reconcile  -   -
	    | ^             cert-manager-cainjector:leaderelection              RoleBinding                     -    create  -       reconcile  -   -
	    | ^             cert-manager:leaderelection                         Role                            -    create  -       reconcile  -   -
	    | ^             cert-manager:leaderelection                         RoleBinding                     -    create  -       reconcile  -   -
	    | Op:      47 create, 0 delete, 0 update, 0 noop, 0 exists
	    | Wait to: 47 reconcile, 0 delete, 0 noop
	    | 2:33:19PM: ---- applying 24 changes [0/47 done] ----
	    | 2:33:20PM: create validatingwebhookconfiguration/cert-manager-webhook (admissionregistration.k8s.io/v1) cluster
	    | 2:33:20PM: create namespace/cert-manager (v1) cluster
	    # ....
        # .
        # .
        # .
        # ....
	    | 2:34:19PM: ---- waiting on 1 changes [46/47 done] ----
	    | 2:34:28PM: ongoing: reconcile deployment/cert-manager (apps/v1) namespace: cert-manager
	    | 2:34:28PM:  ^ Waiting for 1 unavailable replicas
	    | 2:34:28PM:  L ok: waiting on replicaset/cert-manager-76d59565fc (apps/v1) namespace: cert-manager
	    | 2:34:28PM:  L ongoing: waiting on pod/cert-manager-76d59565fc-7p8c9 (v1) namespace: cert-manager
	    | 2:34:28PM:     ^ Pending: ContainerCreating
	    | 2:34:46PM: ok: reconcile deployment/cert-manager (apps/v1) namespace: cert-manager
	    | 2:34:46PM: ---- applying complete [47/47 done] ----
	    | 2:34:46PM: ---- waiting complete [47/47 done] ----
	    | Succeeded
8:04:46PM: Deploy succeeded

Succeeded
```
(_deploy output truncated_)

`kctrl` waits for the PackageInstall to reconcile successfully.

Users can also pass a `values.yml` file defining values to be consumed by the package using the `--values-file` flag. Let's see what values are accepted by the Cert Manager Package and supply custom values to it.

```bash
$ kctrl package available get -p cert-manager.packages.kadras.io/1.14.4 --values-schema -n kadras-system
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

Values schema for 'cert-manager.packages.kadras.io/1.14.4'

Key                             Default       Type     Description
controller.loglevel             2             integer  Number of the log level verbosity.
leader_election.lease_duration  60s           string   The duration that non-leader candidates will wait after observing a leadership renewal until attempting to acquire leadership of a led but unrenewed leader slot. This is effectively the maximum duration that a leader can be stopped before it is replaced by another candidate.
leader_election.namespace       kube-system   string   Namespace used to perform leader election. The default namespace needs changing in environments like GKE. More information: https://cert-manager.io/docs/installation/compatibility/#gke.
leader_election.renew_deadline  40s           string   The interval between attempts by the acting leader to renew a leadership slot before it stops leading.
leader_election.retry_period    15s           string   The duration the clients should wait between attempting acquisition and renewal of a leadership.
namespace                       cert-manager  string   The namespace in which to deploy cert-manager.
policies.include                false         boolean  Whether to include the out-of-the-box Kyverno policies to validate and secure the package installation.
proxy.http_proxy                ""            string   The HTTP proxy to use for network traffic.
proxy.https_proxy               ""            string   The HTTPS proxy to use for network traffic.
proxy.no_proxy                  ""            string   A comma-separated list of hostnames, IP addresses, or IP ranges in CIDR format that should not use the proxy.
webhook.host_network            false         boolean  Whether to run the webhook in the host network so that it can be reached by the cert-manager controller in environments like AWS EKS. More information: https://cert-manager.io/docs/installation/compatibility/#aws-eks.
webhook.loglevel                2             integer  Number of the log level verbosity.
webhook.replicas                1             integer  The number of replicas. In order to enable high availability, it should be greater than 1.
webhook.secure_port             10250         integer  The port where the webhook is exposed. The default port needs changing in environments like AWS EKS and AWS Fargate. More information: https://cert-manager.io/docs/installation/compatibility/#aws-eks.

Succeeded
```
It is worth noting that both the package name and version have to be supplied to view the values a package accepts as these might change across versions. `kctrl` accepts this in the `package-name/package-version` format.

Lets create a `values.yml` file that supplies a custom value for `namespace` to the installation.

```yaml
cat > values.yml << EOF
---
namespace: cert-manager-install
EOF
```
Let's update the installation to use these values.

`kctrl` creates a secret with the values defined in the file, updates the package installation to consume it and then waits for it to reconcile to the new desired state.

```bash
$ kctrl package installed update -i cert-manager --values-file values.yml -n kadras-system
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

8:09:33PM: Creating secret 'cert-manager-kadras-system-values'
8:09:33PM: Creating overlay secrets
8:09:33PM: Updating package install for 'cert-manager' in namespace 'kadras-system'
8:09:33PM: Waiting for PackageInstall reconciliation for 'cert-manager'
8:09:33PM: Waiting for generation 2 to be observed
8:09:37PM: Fetching
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - imgpkgBundle:
	    |       image: ghcr.io/kadras-io/package-for-cert-manager@sha256:d71e3e3afac1ec3d66fd086f8d201778bac0e5ddfc1d12b8a4356e4a0090a00c
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    |
8:09:37PM: Fetch succeeded
8:09:38PM: Template succeeded
8:09:38PM: Deploy started (2s ago)
8:09:40PM: Deploying
	    | Target cluster 'https://10.96.0.1:443' (nodes: minikube)
	    | Changes
	    | Namespace             Name                                                Kind                            Age  Op      Op st.  Wait to    Rs  Ri
	    | (cluster)             cert-manager                                        Namespace                       6m   delete  -       delete     ok  -
	    | ^                     cert-manager-cainjector                             ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-controller-approve:cert-manager-io     ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-controller-certificates                ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-controller-certificatesigningrequests  ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-controller-challenges                  ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-controller-clusterissuers              ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-controller-ingress-shim                ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-controller-issuers                     ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-controller-orders                      ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-install                                Namespace                       -    create  -       reconcile  -   -
	    | ^                     cert-manager-webhook                                MutatingWebhookConfiguration    6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-webhook                                ValidatingWebhookConfiguration  6m   update  -       reconcile  ok  -
	    | ^                     cert-manager-webhook:subjectaccessreviews           ClusterRoleBinding              6m   update  -       reconcile  ok  -
	    | cert-manager          canonical-registry-credentials                      Secret                          6m   delete  -       delete     ok  -
	    | ^                     cert-manager                                        Deployment                      6m   delete  -       delete     ok  -
	    | ^                     cert-manager                                        Service                         6m   delete  -       delete     ok  -
	    | ^                     cert-manager                                        ServiceAccount                  6m   delete  -       delete     ok  -
	    | ^                     cert-manager-cainjector                             Deployment                      6m   delete  -       delete     ok  -
	    | ^                     cert-manager-cainjector                             ServiceAccount                  6m   delete  -       delete     ok  -
	    | ^                     cert-manager-webhook                                Deployment                      6m   delete  -       delete     ok  -
	    | ^                     cert-manager-webhook                                Service                         6m   delete  -       delete     ok  -
	    | ^                     cert-manager-webhook                                ServiceAccount                  6m   delete  -       delete     ok  -
	    | ^                     cert-manager-webhook:dynamic-serving                Role                            6m   delete  -       delete     ok  -
	    | ^                     cert-manager-webhook:dynamic-serving                RoleBinding                     6m   delete  -       delete     ok  -
	    | cert-manager-install  canonical-registry-credentials                      Secret                          -    create  -       reconcile  -   -
	    | ^                     cert-manager                                        Deployment                      -    create  -       reconcile  -   -
	    | ^                     cert-manager                                        Service                         -    create  -       reconcile  -   -
	    | ^                     cert-manager                                        ServiceAccount                  -    create  -       reconcile  -   -
	    | ^                     cert-manager-cainjector                             Deployment                      -    create  -       reconcile  -   -
	    | ^                     cert-manager-cainjector                             ServiceAccount                  -    create  -       reconcile  -   -
	    | ^                     cert-manager-webhook                                Deployment                      -    create  -       reconcile  -   -
	    | ^                     cert-manager-webhook                                Service                         -    create  -       reconcile  -   -
	    | ^                     cert-manager-webhook                                ServiceAccount                  -    create  -       reconcile  -   -
	    | ^                     cert-manager-webhook:dynamic-serving                Role                            -    create  -       reconcile  -   -
	    | ^                     cert-manager-webhook:dynamic-serving                RoleBinding                     -    create  -       reconcile  -   -
	    | kube-system           cert-manager-cainjector:leaderelection              RoleBinding                     6m   update  -       reconcile  ok  -
	    | ^                     cert-manager:leaderelection                         RoleBinding                     6m   update  -       reconcile  ok  -
	    | Op:      12 create, 12 delete, 14 update, 0 noop, 0 exists
	    | Wait to: 26 reconcile, 12 delete, 0 noop
	    | 2:39:39PM: ---- applying 14 changes [0/38 done] ----
	    | 2:39:39PM: delete deployment/cert-manager (apps/v1) namespace: cert-manager
	    | 2:39:39PM: delete secret/canonical-registry-credentials (v1) namespace: cert-manager
	    # ....
        # .
        # .
        # .
        # ....
	    | 2:39:47PM: ---- waiting on 1 changes [37/38 done] ----
	    | 2:39:53PM: ok: reconcile deployment/cert-manager-webhook (apps/v1) namespace: cert-manager-install
	    | 2:39:53PM: ---- applying complete [38/38 done] ----
	    | 2:39:53PM: ---- waiting complete [38/38 done] ----
	    | Succeeded
8:09:53PM: Deploy succeeded

Succeeded
```
(_deploy output truncated_)

## Deleting an installation
`kctrl` can be used to delete an installation and associated resources created with it. `kctrl` waits for them to be deleted from the cluster.
```bash
$ kctrl package installed delete -i cert-manager -n kadras-system
Delete package install 'cert-manager' from namespace 'kadras-system'

Continue? [yN]: y

Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

8:11:53PM: Deleting package install 'cert-manager' from namespace 'kadras-system'
8:11:53PM: Waiting for deletion of package install 'cert-manager' from namespace 'kadras-system'
8:11:53PM: Waiting for generation 3 to be observed
8:11:53PM: Delete started (2s ago)
8:11:55PM: Deleting
	    | Target cluster 'https://10.96.0.1:443' (nodes: minikube)
	    | Changes
	    | Namespace             Name                                                Kind                            Age  Op      Op st.  Wait to  Rs  Ri
	    | (cluster)             cert-manager-cainjector                             ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-cainjector                             ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-cluster-view                           ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-approve:cert-manager-io     ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-approve:cert-manager-io     ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-certificates                ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-certificates                ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-certificatesigningrequests  ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-certificatesigningrequests  ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-challenges                  ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-challenges                  ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-clusterissuers              ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-clusterissuers              ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-ingress-shim                ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-ingress-shim                ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-issuers                     ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-issuers                     ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-orders                      ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-controller-orders                      ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     cert-manager-edit                                   ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-install                                Namespace                       2m   delete  -       delete   ok  -
	    | ^                     cert-manager-view                                   ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-webhook                                MutatingWebhookConfiguration    8m   delete  -       delete   ok  -
	    | ^                     cert-manager-webhook                                ValidatingWebhookConfiguration  8m   delete  -       delete   ok  -
	    | ^                     cert-manager-webhook:subjectaccessreviews           ClusterRole                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager-webhook:subjectaccessreviews           ClusterRoleBinding              8m   delete  -       delete   ok  -
	    | ^                     certificaterequests.cert-manager.io                 CustomResourceDefinition        8m   delete  -       delete   ok  -
	    | ^                     certificates.cert-manager.io                        CustomResourceDefinition        8m   delete  -       delete   ok  -
	    | ^                     challenges.acme.cert-manager.io                     CustomResourceDefinition        8m   delete  -       delete   ok  -
	    | ^                     clusterissuers.cert-manager.io                      CustomResourceDefinition        8m   delete  -       delete   ok  -
	    | ^                     issuers.cert-manager.io                             CustomResourceDefinition        8m   delete  -       delete   ok  -
	    | ^                     orders.acme.cert-manager.io                         CustomResourceDefinition        8m   delete  -       delete   ok  -
	    | cert-manager-install  canonical-registry-credentials                      Secret                          2m   delete  -       delete   ok  -
	    | ^                     cert-manager                                        Deployment                      2m   delete  -       delete   ok  -
	    | ^                     cert-manager                                        Endpoints                       2m   -       -       delete   ok  -
	    | ^                     cert-manager                                        Service                         2m   delete  -       delete   ok  -
	    | ^                     cert-manager                                        ServiceAccount                  2m   delete  -       delete   ok  -
	    | ^                     cert-manager-5647bb5894                             ReplicaSet                      2m   -       -       delete   ok  -
	    | ^                     cert-manager-5647bb5894-s76mc                       Pod                             2m   -       -       delete   ok  -
	    | ^                     cert-manager-76zrp                                  EndpointSlice                   2m   -       -       delete   ok  -
	    | ^                     cert-manager-cainjector                             Deployment                      2m   delete  -       delete   ok  -
	    | ^                     cert-manager-cainjector                             ServiceAccount                  2m   delete  -       delete   ok  -
	    | ^                     cert-manager-cainjector-6798cf9c9                   ReplicaSet                      2m   -       -       delete   ok  -
	    | ^                     cert-manager-cainjector-6798cf9c9-rqz75             Pod                             2m   -       -       delete   ok  -
	    | ^                     cert-manager-webhook                                Deployment                      2m   delete  -       delete   ok  -
	    | ^                     cert-manager-webhook                                Endpoints                       2m   -       -       delete   ok  -
	    | ^                     cert-manager-webhook                                Service                         2m   delete  -       delete   ok  -
	    | ^                     cert-manager-webhook                                ServiceAccount                  2m   delete  -       delete   ok  -
	    | ^                     cert-manager-webhook-867b876dd9                     ReplicaSet                      2m   -       -       delete   ok  -
	    | ^                     cert-manager-webhook-867b876dd9-kdbd2               Pod                             2m   -       -       delete   ok  -
	    | ^                     cert-manager-webhook-nhbwg                          EndpointSlice                   2m   -       -       delete   ok  -
	    | ^                     cert-manager-webhook:dynamic-serving                Role                            2m   delete  -       delete   ok  -
	    | ^                     cert-manager-webhook:dynamic-serving                RoleBinding                     2m   delete  -       delete   ok  -
	    | kube-system           cert-manager-cainjector:leaderelection              Role                            8m   delete  -       delete   ok  -
	    | ^                     cert-manager-cainjector:leaderelection              RoleBinding                     8m   delete  -       delete   ok  -
	    | ^                     cert-manager:leaderelection                         Role                            8m   delete  -       delete   ok  -
	    | ^                     cert-manager:leaderelection                         RoleBinding                     8m   delete  -       delete   ok  -
	    | Op:      0 create, 47 delete, 0 update, 10 noop, 0 exists
	    | Wait to: 0 reconcile, 57 delete, 0 noop
	    | 2:41:54PM: ---- applying 16 changes [0/57 done] ----
	    | 2:41:54PM: noop replicaset/cert-manager-webhook-867b876dd9 (apps/v1) namespace: cert-manager-install
	    | 2:41:54PM: noop replicaset/cert-manager-cainjector-6798cf9c9 (apps/v1) namespace: cert-manager-install
	    | 2:41:54PM: noop endpointslice/cert-manager-76zrp (discovery.k8s.io/v1) namespace: cert-manager-install
	    | 2:41:54PM: noop endpoints/cert-manager-webhook (v1) namespace: cert-manager-install
        # ....
        # .
        # .
        # .
        # ....
8:12:02PM: App 'cert-manager' in namespace 'kadras-system' deleted
8:12:03PM: packageinstall/cert-manager (packaging.carvel.dev/v1alpha1) namespace: kadras-system: DeletionSucceeded
8:12:03PM: Deleting 'ClusterRole': cert-manager-kadras-system-cluster-role
8:12:03PM: Deleting 'ClusterRoleBinding': cert-manager-kadras-system-cluster-rolebinding
8:12:03PM: Deleting 'Secret': cert-manager-kadras-system-values
8:12:03PM: Deleting 'ServiceAccount': cert-manager-kadras-system-sa

Succeeded
```
(_delete output truncated_)

## Deleting an added repository
`kctrl` deletes the PackageRepository and waits till it is deleted from the cluster.

```bash
$ kctrl package repository delete -r kadras-packages -n kadras-system
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

Deleting package repository 'kadras-packages' in namespace 'kadras-system'

Continue? [yN]: y

8:13:44PM: Waiting for package repository reconciliation for 'kadras-packages'
8:13:46PM: Package repository 'kadras-packages' in namespace 'kadras-system' deleted

Succeeded
```

## Congratulations!
You can now get up and running with published repositories and manage packages faster using `kctrl`.
