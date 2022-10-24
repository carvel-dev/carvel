---
aliases: [/kapp-controller/docs/latest/packaging-gitops]
title: Package Management with GitOps
---

As you begin working with the [package management APIs](packaging.md) for kapp-controller, you may 
be wondering how to use kapp-controller's gitops features to manage kapp-controller packages. This 
section will cover an example gitops workflow using kapp-controller's package management resources.

### GitOps Scenario

An example gitops scenario with kapp-controller could be that a user wants to install a subset of 
[Packages](packaging.md#package) from a [PackageRepository](packaging.md#package-repository). The 
user wants to define which PackageRepository and Packages to install by defining these resources in 
a git repository. With this approach, a user can manage resources in a declarative fashion and track 
the history of changes to a Kubernetes cluster. 

After making changes to the main branch of the git repository, the user expects that kapp-controller 
will sync these resources to the Kubernetes cluster where kapp-controller is installed. The user also 
expects kapp-controller to sync these resources based on updates (e.g. PackageRepository or Package version upgrades) 
to the main branch of the git repository.

### Package Management GitOps Example

To start, a user should already have kapp-controller installed on a Kubernetes cluster and have 
a git repository available. 

First, a user can start by defining an [App custom resource](app-overview.md) like below. **NOTE:** 
A user will also need to create a serviceaccount with associated RBAC permissions for the App to use.

```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: pkg-gitops-example
  namespace: pkg-gitops
  annotations:
    kapp.k14s.io/change-rule.create-order: "upsert after upserting rbac"
    kapp.k14s.io/change-rule.delete-order: "delete before deleting rbac"
spec:
  serviceAccountName: pkg-gitops-app-sa
  fetch:
  - git:
      url: https://github.com/user/my-pkg-gitops-repo
      ref: origin/main
      subPath: packaging

  template:
  - ytt: {}

  deploy:
  - kapp: {}
```

The App will be pointed at the git repository branch where kapp-controller resources 
(e.g. PackageRepository and Packages) will be defined. Read more on setting the App 
up with a private git repository [here](app-overview.md#git-authentication).

By default, an App custom resource will sync the cluster with its fetch source every 
30 seconds to prevent the cluster state from drifting from its source of truth, which 
is a git repository in this case. 

**NOTE:** The App should be managed separately from any additional kapp-controller resources 
stored in a git repository for a gitops workflow. One potential example could be storing the 
App definition and associated RBAC in the same git repository it is fetching from and have a 
CI/CD process redeploy only the App when a change is made to the App itself versus other resourcees 
in the repository. For simplicity in the example above, the user is deploying the App with 
`kubectl` or `kapp` manually. 

After creating the App, a user can define a PackageRepository like below:

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: tce-repository
  namespace: pkg-gitops
  annotations:
    kapp.k14s.io/change-group: "tce-repo"
spec:
  fetch:
    imgpkgBundle:
      image: projects.registry.vmware.com/tce/main:0.10.0
```

This PackageRepository will install the [Tanzu Community Edition](https://tanzucommunityedition.io/) 
packages on the cluster where kapp-controller is installed. 

Next, a user can pick which Packages to install on the cluster by defining [PackageInstall](packaging.md#packageinstall) 
resources. The Tanzu Community Edition repository offers several Packages that are documented 
[here](https://tanzucommunityedition.io/docs/latest/package-management/). 

For our gitops example, let's say the user is installing [cert-manager](https://cert-manager.io/docs/) 
and [contour](https://projectcontour.io/) on the cluster. To do this, a user could define the following 
PackageInstall along with associated RBAC. **NOTE:** The example below gives cluster admin permissions 
to the serviceaccount. Make sure to assess appropriate RBAC needed for your specific PackageInstalls. 

RBAC: 

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pkg-gitops-pkgi-sa
  namespace: pkg-gitops
  annotations:
    kapp.k14s.io/change-group: "packageinstall-setup"
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-admin-cluster-role
  annotations:
    kapp.k14s.io/change-group: "packageinstall-setup"
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-admin-cluster-role-binding
  annotations:
    kapp.k14s.io/change-group: "packageinstall-setup"
subjects:
- kind: ServiceAccount
  name: pkg-gitops-pkgi-sa
  namespace: pkg-gitops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin-cluster-role
```

PackageInstalls:

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: cert-manager
  namespace: pkg-gitops
  annotations:
    kapp.k14s.io/change-group: "cert-manager"
    kapp.k14s.io/change-rule.create-order: "upsert after upserting packageinstall-setup"
    kapp.k14s.io/change-rule.delete-order: "delete before deleting packageinstall-setup"
spec:
  serviceAccountName: pkg-gitops-pkgi-sa
  packageRef:
    refName: cert-manager.community.tanzu.vmware.com
    versionSelection:
      constraints: 1.5.4
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: contour
  namespace: pkg-gitops
  annotations:
    kapp.k14s.io/change-rule.create-order: "upsert after upserting cert-manager"
    kapp.k14s.io/change-rule.delete-order: "delete before deleting packageinstall-setup"
spec:
  serviceAccountName: pkg-gitops-pkgi-sa
  packageRef:
    refName: contour.community.tanzu.vmware.com
    versionSelection:
      constraints: 1.17.1
```

The structure of the git repository might look like the example below. In this structure, 
the App definition is stored under a folder called app. The App definition above uses a 
property called `subPath` to tell kapp-controller to only fetch and sync resources found 
under the packaging folder of this git repository. The packaging folder will contain the 
PackageRepository, PackageInstalls, and associated RBAC.

```
.
├── app
│   ├── app.yml
│   ├── rbac.yml
└── packaging
    ├── packageinstalls.yml
    ├── rbac.yml
    └── repo.yml
```

The user can then check in and commit the App, PackageRepository, RBAC, and PackageInstalls to 
the main branch of the git repository and push up the resources. 

To deploy the PackageRepository, RBAC, and PackageInstalls, create the App by running the following 
commands:

```shell
# Use kubectl
kubectl apply -f app/
# Use kapp
kapp deploy -a pkg-gitops -f app/
```

Once committed, the App custom resource created will create the PackageRepository, RBAC, and PackageInstalls 
on the cluster.

The user can view the status of the deployment through the App as well by running the following:

```shell
kubectl get apps/pkg-gitops-example -n pkg-gitops
```

When the App's status is `Reconcile succeeded`, cert-manager and contour should be installed on the 
cluster. This can be verified by running the following command:

```shell
kubectl get pkgi -n pkg-gitops
```

### Making an Update

When it's time to make an update to Packages installed on your cluster, a user can simply 
open a pull request to the main branch of the git repositoy, make necessary changes in the 
pull request review, and then merge when ready to introduce the change to the cluster.

To expand on the example above, a user may want to upgrade contour to a later version (e.g. 1.17.2). 
To do this, check out the git repository, edit the version used for the PackageInstall like below, 
and then commit the change to the main branch.

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: contour
  namespace: pkg-gitops
  annotations:
    kapp.k14s.io/change-rule.create-order: "upsert after upserting cert-manager"
    kapp.k14s.io/change-rule.delete-order: "delete before deleting packageinstall-setup"
spec:
  serviceAccountName: pkg-gitops-pkgi-sa
  packageRef:
    refName: contour.community.tanzu.vmware.com
    versionSelection:
      constraints: 1.17.2
```

Once committed, the App custom resource will eventually sync in the changes. The change can be 
verified by running the following command and checking in the kubectl output that the contour 
PackageInstall is now using version 1.17.2:

```shell
kubectl get pkgi/contour -n pkg-gitops
```
