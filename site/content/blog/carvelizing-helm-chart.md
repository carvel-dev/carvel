---
title: "Carvelizing Helm Chart"
slug: carvelize-helm-chart
date: 2022-02-16
author: Rohit Aggarwal
excerpt: "Use Carvel to author and consume helm chart "
image: /img/logo.svg
tags: ['carvel', 'helm', 'gitops']
---

In this blog post we will first show you how to wrap and distribute [`Bitnami nginx helm chart`](https://github.com/bitnami/charts/tree/master/bitnami/nginx) as a Carvel package, and then install it on the Kubernetes cluster via PackageInstall CR (via kapp-controller).

## Why should I choose Carvel

Kubernetes configuration takes many forms – plain YAML configurations, Helm charts, ytt templates, jsonnet templates, etc. Software running on Kubernetes lives in many different places, e.g. a Git repository, an archive over HTTP, a Helm repository.

Carvel is a collection of small sharp tools that breaks up the problem into smaller building blocks with clean boundaries. This approach facilitates interoperability with other tools, giving users the option to swap out pieces with tools of their choice. Carvel declarative APIs approach provides a familiar experience for Kubernetes users. This means that package management using Carvel is about declaring desired state via a Package CR and have it be continuously reconciled to that desired state on a Kubernetes cluster.

## Prerequisites

Basic knowledge of imgpkg, kbld, kapp-controller, kapp

[`kbld`](https://carvel.dev/kbld/): kbld incorporates image building and image pushing into your development and deployment workflows.

[`imgpkg`](https://carvel.dev/imgpkg/): A tool to package, distribute and relocate your Kubernetes configuration and dependent OCI images as one OCI artifact: a bundle.

[`kapp`](https://carvel.dev/kapp/): kapp is a cli used to deploy and view groups of Kubernetes resources as “application”.

[`kapp-controller`](https://carvel.dev/kapp-controller/): kapp-controller provides declarative APIs to create, customize, install, and update your Kubernetes applications into packages. It also continuously fetches and reconciles resources to converge into their desired state.

**Installing Carvel Tools**

We'll be using Carvel tools throughout this tutorial, so first we'll install them using [`install.sh`](https://carvel.dev/install.sh) script.

```bash
$ wget -O- https://carvel.dev/install.sh > install.sh

# Inspect install.sh before running...
$ sudo bash install.sh
# Install kapp-controller
$ kubectl apply -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
```

--------------------------

## Authoring a Carvel Package

To create a package, we need to create two Custom Resources (CRs). We will go through step by step to author an nginx helm chart:

**1. Create PackageMetadata CR**: Package Metadata contains high level information and description about the package. Multiple versions of a package share same package metadata.

Save the below PackageMetadata CR to a file named `pkgMetadata.yaml`
```yaml

apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  # This will be the name of our package metadata
  name: nginx.bitnami.vmware.com
spec:
  displayName: "Bitnami Nginx Carvel Package"
  longDescription: "Proxifying Server"
  shortDescription: "Proxifying Server"
  categories:
  - proxy-server
  providerName: VMWare
  maintainers:
  - name: "Carvel"
  - name: "CarvelInd"
  - name: "Rohit Aggarwal"
```

**2. Package Helm Chart**: The Package CR is config including metadata and references to OCI artifacts that informs the package manager what software it holds and how to install itself onto a Kubernetes cluster.

Save the below Package CR to a file named `1.0.0.yaml`
```yaml

apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  # Must be of the form '<spec.refName>.<spec.version>' (Note the period)
  name: nginx.bitnami.vmware.com.1.0.0
spec:
  # The name of the PackageMetadata associated with this version
  # Must be a valid PackageMetadata name (see PackageMetadata CR for details)
  # Cannot be empty
  refName: nginx.bitnami.vmware.com
  # Package version; Referenced by PackageInstall;
  # Must be valid semver (required)
  # Cannot be empty
  version: 1.0.0
  # Version release notes (optional; string)
  releaseNotes:
    Initial release of the nginx package by wrapping helm Chart. Nginx Helm chart version is 9.5.4
  # valuesSchema can be used to show template values that
  # can be configured by users when a Package is installed.
  # These values should be specified in an OpenAPI schema format. (optional)
  # For helm chart, we can either define the configurable values here or let it be. Even if we dont define them here, we can still customize them.
  valuesSchema:
    openAPIv3:
      title: nginx.bitnami.vmware.com
      examples:
      properties:
  template:
    spec:
      fetch:
      - helmChart:
          name: nginx
          version: 9.5.4
          repository:
            # From where to pull the helm chart
            url: https://charts.bitnami.com/bitnami 
      template:
      - helmTemplate: {}
      deploy:
      - kapp: {}
```
**Note**: This is one way of packaging helm chart. Another way is to use `imgpkg` bundle to store the helm chart itself and then reference it. 

**3. Create Package Repository**: A package repository is a collection of packages and their metadata. We will use `imgpkg` bundle to create package repository.

For the purpose of this tutorial, we will run an unsecured local docker registry. In the real world please be safe and use appropriate security measures.
    
```bash
$ docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

From the terminal we can access this registry as localhost:5000 but within the cluster we'll need the IP Address. We will store the IP address in a variable:

```bash 
$ export REPO_HOST="`ifconfig | grep inet | grep -E '\b10\.' | awk '{ print $2}'`:5000"
```

Confirm that REPO_HOST is set to <IP_ADDRESS:PORT>

```bash
$ echo $REPO_HOST
  10.104.40.33:5000
```

`imgpkg` has a pre-defined bundle format which allows it to perform recursive image relocation. https://carvel.dev/kapp-controller/docs/v0.32.0/packaging-artifact-formats/#package-repository-bundle

Lets start by creating the directories as required by `imgpkg`:

```bash
$ mkdir -p nginx-bitnami-repo nginx-bitnami-repo/.imgpkg nginx-bitnami-repo/packages/nginx.bitnami.vmware.com
```

We can copy our CR YAMLs from the previous step in to the proper packages subdirectory. 

```bash
$ cp 1.0.0.yaml nginx-bitnami-repo/packages/nginx.bitnami.vmware.com
$ cp pkgMetadata.yaml nginx-bitnami-repo/packages/nginx.bitnami.vmware.com
```

Now, let’s use kbld to record which package bundles are used:

```bash
$ kbld -f nginx-bitnami-repo/packages/ --imgpkg-lock-output nginx-bitnami-repo/.imgpkg/images.yml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: nginx.bitnami.vmware.com.1.0.0
spec:
  refName: nginx.bitnami.vmware.com
  releaseNotes: Initial release of the nginx package by wrapping helm Chart. Nginx
    Helm chart version is 9.5.4
  template:
    spec:
      deploy:
      - kapp: {}
      fetch:
      - helmChart:
          name: nginx
          repository:
            url: https://charts.bitnami.com/bitnami
          version: 9.5.4
      template:
      - helmTemplate: {}
  valuesSchema:
    openAPIv3:
      examples: null
      properties: null
      title: nginx.bitnami.vmware.com
  version: 1.0.0
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: nginx.bitnami.vmware.com
spec:
  categories:
  - proxy-server
  displayName: Bitnami Nginx Carvel Package
  longDescription: Proxifying Server
  maintainers:
  - name: Carvel
  - name: CarvelInd
  - name: Rohit Aggarwal
  providerName: VMWare
  shortDescription: Proxifying Server

Succeeded
```

We will push the bundle into the repository using `imgpkg`.

```bash
$ imgpkg push -b ${REPO_HOST}/packages/nginx-bitnami-repo:1.0.0 -f nginx-bitnami-repo
dir: .
dir: .imgpkg
file: .imgpkg/images.yml
dir: packages
dir: packages/nginx.bitnami.vmware.com
file: packages/nginx.bitnami.vmware.com/1.0.0.yaml
file: packages/nginx.bitnami.vmware.com/pkgMetadata.yaml
Pushed '10.104.40.33:5000/packages/nginx-bitnami-repo@sha256:706aa0174d9ab0d30414ec074458f8a45c5c12bf348440ffc22b58c5036e73dd'
Succeeded
```

We can verify by checking the Docker registry catalog:

```bash
$ curl ${REPO_HOST}/v2/_catalog
{"repositories":["packages/nginx-bitnami-repo"]}
```

--------------------------

## Consuming Carvel Helm Package:

**1. Install Package Repository**: Before installing the package, we have to make it visible to kapp-controller by using a PackageRepository CR. A PackageRepository is a collection of packages which are available to install. 

Save the below PackageRepository CR to a file named `repo.yaml`
```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: simple-package-repository
spec:
  fetch:
    imgpkgBundle:
      image: ${REPO_HOST}/packages/nginx-bitnami-repo:1.0.0
```

Replace the ${REPO_HOST} in `repo.yaml` file with the actual value you got above.

```bash
$ kapp deploy -a repo -f repo.yaml -y
Target cluster 'https://192.168.64.32:8443' (nodes: minikube)

Changes

Namespace  Name                       Kind               Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-package-repository  PackageRepository  -       -    create  -       reconcile  -   -

Op:      1 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

12:35:17PM: ---- applying 1 changes [0/1 done] ----
12:35:17PM: create packagerepository/simple-package-repository (packaging.carvel.dev/v1alpha1) namespace: default
12:35:17PM: ---- waiting on 1 changes [0/1 done] ----
12:35:17PM: ongoing: reconcile packagerepository/simple-package-repository (packaging.carvel.dev/v1alpha1) namespace: default
12:35:17PM:  ^ Waiting for generation 1 to be observed
12:35:18PM: ok: reconcile packagerepository/simple-package-repository (packaging.carvel.dev/v1alpha1) namespace: default
12:35:18PM: ---- applying complete [1/1 done] ----
12:35:18PM: ---- waiting complete [1/1 done] ----

Succeeded
```

After deploying, wait for the packageRepository description to become `Reconcile succeeded`. 

```bash 
$ kubectl get packagerepository
NAME                        AGE   DESCRIPTION
simple-package-repository   40s   Reconcile succeeded
```

Now, we can see the list of package metadata's available

```bash
$ kubectl get packagemetadatas
NAME                       DISPLAY NAME                   CATEGORIES     SHORT DESCRIPTION   AGE
nginx.bitnami.vmware.com   Bitnami Nginx Carvel Package   proxy-server   Proxifying Server   56s
```

**2. List Packages**:
We can see the list of packages and their version's available for install 

```bash 
$ kubectl get packages
NAME                             PACKAGEMETADATA NAME       VERSION   AGE
nginx.bitnami.vmware.com.1.0.0   nginx.bitnami.vmware.com   1.0.0     1m29s
```

As we can see, our published nginx helm package is available for us to install.

**3. Create Service Account**: To install the above package, we need to create default-ns-sa service account that give PackageInstall CR privileges to create resources in the default namespace

```bash
$ kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/examples/rbac/default-ns.yml -y
Target cluster 'https://192.168.64.32:8443' (nodes: minikube)

Changes

Namespace  Name                     Kind            Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    default-ns-role          Role            -       -    create  -       reconcile  -   -
^          default-ns-role-binding  RoleBinding     -       -    create  -       reconcile  -   -
^          default-ns-sa            ServiceAccount  -       -    create  -       reconcile  -   -

Op:      3 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 3 reconcile, 0 delete, 0 noop

12:37:16PM: ---- applying 2 changes [0/3 done] ----
12:37:16PM: create role/default-ns-role (rbac.authorization.k8s.io/v1) namespace: default
12:37:16PM: create serviceaccount/default-ns-sa (v1) namespace: default
12:37:16PM: ---- waiting on 2 changes [0/3 done] ----
12:37:16PM: ok: reconcile serviceaccount/default-ns-sa (v1) namespace: default
12:37:16PM: ok: reconcile role/default-ns-role (rbac.authorization.k8s.io/v1) namespace: default
12:37:16PM: ---- applying 1 changes [2/3 done] ----
12:37:17PM: create rolebinding/default-ns-role-binding (rbac.authorization.k8s.io/v1) namespace: default
12:37:17PM: ---- waiting on 1 changes [2/3 done] ----
12:37:17PM: ok: reconcile rolebinding/default-ns-role-binding (rbac.authorization.k8s.io/v1) namespace: default
12:37:17PM: ---- applying complete [3/3 done] ----
12:37:17PM: ---- waiting complete [3/3 done] ----

Succeeded
```

**4. Install the Package**: To install a carvel Package, we need to create PackageInstall Kubernetes resource. A Package Install will install the nginx helm package and its underlying resources on a Kubernetes cluster. A `PackageInstall` references a `Package`. Thus, we can create the `PackageInstall` yaml from the `Package`.

We are providing our custom values via secret. 

**NOTE**: If you are using minikube, for nginx service to be in `ACTIVE` state, start `minikube tunnel` in another window as services of LoadBalancer types do not come up otherwise in minikube.  

Save the below PackageInstall CR to a file named `pkgInstall.yaml`
```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: nginx-pkg
spec:
  serviceAccountName: default-ns-sa
  packageRef:
    refName: nginx.bitnami.vmware.com
    versionSelection:
      constraints: 1.0.0
  values:
  - secretRef:
      name: nginx-values

---
apiVersion: v1
kind: Secret
metadata:
  name: nginx-values
stringData:
  values.yml: |
    ---
    image:
      pullPolicy: Always
    serverBlock: |-
      server {
        listen 0.0.0.0:8080;
        location / {
          return 200 "Response from Custom Server";
        }
      }
```

```bash
$ kapp deploy -a pkg-demo -f pkgInstall.yaml -y
Target cluster 'https://192.168.64.32:8443' (nodes: minikube)

Changes

Namespace  Name          Kind            Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    nginx-pkg     PackageInstall  -       -    create  -       reconcile  -   -
^          nginx-values  Secret          -       -    create  -       reconcile  -   -

Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

12:38:14PM: ---- applying 1 changes [0/2 done] ----
12:38:14PM: create secret/nginx-values (v1) namespace: default
12:38:14PM: ---- waiting on 1 changes [0/2 done] ----
12:38:14PM: ok: reconcile secret/nginx-values (v1) namespace: default
12:38:14PM: ---- applying 1 changes [1/2 done] ----
12:38:14PM: create packageinstall/nginx-pkg (packaging.carvel.dev/v1alpha1) namespace: default
12:38:14PM: ---- waiting on 1 changes [1/2 done] ----
12:38:14PM: ongoing: reconcile packageinstall/nginx-pkg (packaging.carvel.dev/v1alpha1) namespace: default
12:38:14PM:  ^ Waiting for generation 1 to be observed
12:38:15PM: ongoing: reconcile packageinstall/nginx-pkg (packaging.carvel.dev/v1alpha1) namespace: default
12:38:15PM:  ^ Reconciling
12:39:15PM: ---- waiting on 1 changes [1/2 done] ----
12:39:16PM: ongoing: reconcile packageinstall/nginx-pkg (packaging.carvel.dev/v1alpha1) namespace: default
12:39:16PM:  ^ Reconciling
12:39:31PM: ok: reconcile packageinstall/nginx-pkg (packaging.carvel.dev/v1alpha1) namespace: default
12:39:31PM: ---- applying complete [2/2 done] ----
12:39:31PM: ---- waiting complete [2/2 done] ----

Succeeded
```

After the deploy has finished, kapp-controller will have installed the package in the cluster. We can verify this by doing the `kapp inspect` and checking the pods to see that we have a workload pod running.
```bash
$ kapp inspect -a pkg-demo
Target cluster 'https://192.168.64.32:8443' (nodes: minikube)

Resources in app 'pkg-demo'

Namespace  Name          Kind            Owner  Conds.  Rs  Ri  Age
default    nginx-pkg     PackageInstall  kapp   1/1 t   ok  -   7m
^          nginx-values  Secret          kapp   -       ok  -   7m

Rs: Reconcile state
Ri: Reconcile information

2 resources

Succeeded
$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
nginx-pkg-6db5c6978d-tt8k4   1/1     Running   0          8m
```

Once the pod is ready, you can use kubectl’s port forwarding to verify the customized response used in the workload.

```bash
$ kubectl port-forward service/nginx-pkg 3000:80 &
```

Now if we make a request against our service, we can see that server response is ```Response from Custom Server```

```bash 
$ curl localhost:3000
Response from Custom Server
```

## Conclusion

This completes how we can wrap, distribute and install an existing Helm chart as a Carvel package.


## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.
