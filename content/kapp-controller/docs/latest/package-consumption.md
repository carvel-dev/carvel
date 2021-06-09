---
title: Package Consumption
---

Available in [v0.17.0-alpha.1+](https://github.com/vmware-tanzu/carvel-kapp-controller/tree/dev-packaging/alpha-releases)

Before jumping in, we recommend reading through the docs about the new [packaging
apis](packaging.md) to familiarize yourself with the YAML configuration used in these
workflows.

This workflow walks through the example contained in
the [`packaging-demo`](https://github.com/vmware-tanzu/carvel-kapp-controller/tree/dev-packaging/examples/packaging-demo).

## Prerequisites

* You will need to [install the alpha release](install-alpha.md) on a Kubernetes cluster to go through the examples.
* The instructions below assume [`kapp`](/kapp) and `kubectl` are installed.

## Adding package repository

kapp-controller needs to know which packages are available to install. One way to let it know about available packages is by registering a package repository. To do this, we need a PackageRepository CR:

```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: simple-package-repository
spec:
  fetch:
    imgpkgBundle:
      image: k8slt/corp-com-pkg-repo:1.0.0
```

If the registry containing the repository is private, a secret ref will
need to be added to the fetch stage. For example,

```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: simple-package-repository
spec:
  fetch:
    imgpkgBundle:
      image: k8slt/corp-com-pkg-repo:1.0.0
      secretRef:
        name: my-registry-creds
```

This secret will need to be located in the namespace where the PackageRepository 
is created and be in the format described in the [fetch docs](config.md#image-authentication).

This PackageRepository CR will allow kapp-controller to install any of the
packages found within the `k8slt/kctrl-pkg-repo:v1.0.0` imgpkg bundle, which is
stored in an OCI registry. Save this PackageRepository to a file named repo.yml
and then apply it to the cluster using kapp:

```bash
$ kapp deploy -a repo -f repo.yml
```

Once the deploy has finished, we are able to list the packages and see which ones are now available:

```bash
$ kubectl get packages
NAME                  DISPLAY NAME   CATEGORIES   SHORT DESCRIPTION        AGE
simple-app.corp.com   Simple App     demo         Simple app for demoing   2s
```

If we want, we can inspect the package further to get more detailed high level
info:

```bash
$ kubectl get package simple-app.corp.com -o yaml
```

This will show us the package yaml, which will look something like this:

```yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: simple-app.corp.com
spec:
  categories:
  - demo
  displayName: Simple App
  longDescription: Simple app consisting of a k8s deployment and service
  shortDescription: Simple app for demoing
```

Once we have found a package which fits what we are looking for, we can take a
look at what versions of that package are available. To do this, we can list the
PackageVersion CRs in the cluster:

```bash
$ kubectl get packageversions
```

If there are numerous available packages, each with many versions, this list can
become a bit unwieldy, so we can also list the package versions specific to
particular package using the `--field-selector` option on kubectl get.

```bash
$ kubectl get packageversions --field-selector spec.packageName=simple-app.corp.com
NAME                             PACKAGE NAME          VERSION      AGE
simple-app.corp.com.1.0.0        simple-app.corp.com   1.0.0        8m45s
simple-app.corp.com.2.0.0        simple-app.corp.com   2.0.0        8m45s
simple-app.corp.com.3.0.0-rc.1   simple-app.corp.com   3.0.0-rc.1   8m45s
```

From here, if we are interested, we can further inspect each version to discover
information such as release notes, installation steps, licenses, etc. For
example,

```bash
$ kubectl get packageversions/simple-app.corp.com.2.0.0 -oyaml
```

will show us more details on version `2.0.0` of the `simple-app.corp.com` package:

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageVersion
metadata:
  name: simple-app.corp.com.2.0.0
spec:
  packageName: simple-app.corp.com
  version: 2.0.0
  releaseNotes: |
    Adds overlays to control the number of pods
  valuesSchema:
    openAPIv3:
      title: simple-app.corp.com values schema
      examples:
      - svc_port: 80
        app_port: 80
        hello_msg: stranger
      properties:
        svc_port:
          type: integer
          description: Port number for the service.
          default: 80
          examples:
          - 80
        app_port:
          type: integer
          description: Target port for the application.
          default: 80
          examples:
          - 80
        hello_msg:
          type: string
          description: Name used in hello message from app when app is pinged.
          default: stranger
          examples:
          - stranger
  template:
    spec:
      deploy:
      - kapp: {}
      fetch:
      - imgpkgBundle:
          image: index.docker.io/k8slt/kctrl-example-pkg@sha256:73713d922b5f561c0db2a7ea5f4f6384f7d2d6289886f8400a8aaf5e8fdf134a
      template:
      - ytt:
          paths:
          - config-step-2-template
          - config-step-2a-overlays
      - kbld:
          paths:
          - '-'
          - .imgpkg/images.yml
```

Here we can see this version will fetch the templates stored in the
`k8slt/kctrl-example-pkg:v1.0.0` bundle, template them using ytt and kbld, and
finally deploy them using kapp. Once deployed, there will be a basic greeter app
running in the cluster. Since this is what we want, we can now move on to
installation.

## Installing a package

Once we have the packages available for installation (as seen via `kubectl get package`) we need to let kapp-controller know what we want to install. To do this, we will need to create an InstalledPackage CR (and a secret to hold the values used by our package):

```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: InstalledPackage
metadata:
  name: pkg-demo
  namespace: default
spec:
  serviceAccountName: default-ns-sa
  packageVersionRef:
    packageName: simple-app.corp.com
    versionSelection:
      constraints: 1.0.0
  values:
  - secretRef:
      name: pkg-demo-values
---
apiVersion: v1
kind: Secret
metadata:
  name: pkg-demo-values
stringData:
  values.yml: |
    ---
    hello_msg: "hi"
```

This CR references the PackageVersion we decided to install in the previous
section using the PackageVersion's `packageName` and `version` fields. 
The `versionSelection` property has a `constraints` subproperty to specify what 
PackageVersion kapp-controller should install. More information on InstalledPackage 
versioning can be found [here](packaging#versioning-installedpackages).

The InstalledPackage also references the service account which will be used to
install the package, as well as values to include in the templating step in
order to customize our installation.

As part of installing this PackageVersion, another thing you will notice is 
that a Kubernetes secret will be created. This secret contains a values.yml 
file where configurable properties defined in the PackageVersion valuesSchema 
can be specified. The InstalledPackage references these configurable values via 
a values property and a secretRef can be used to reference the secret with the 
configured values.

To install above package, we will also need to create `default-ns-sa` service account (refer to [Security model](security-model.md) for explanation of how service accounts are used) that give kapp-controller privileges to create resources in the default namespace:

```bash
$ kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/examples/rbac/default-ns.yml
```

Save the InstalledPackage above to a file named installedpkg.yml and then apply the
InstalledPackage using kapp:

```bash
$ kapp deploy -a pkg-demo -f installedpkg.yml
```

After the deploy has finished, kapp-controller will have installed the package in the
cluster. We can verify this by checking the pods to see that we have a workload pod
running. The output should show a single running pod which is part of simple-app:

```bash
$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
simple-app-58f865df65-kmhld   1/1     Running   0          2m
```

If we now use kubectl's port forwarding functionality, we can also see the our
customized hello message as been used in the workload:

```bash
$ kubectl port-forward service/simple-app  3000:80
```

Then, from another window:

```bash
$ curl localhost:3000
<h1>Hello hi!</h1>%
```

And we see that our hello_msg value is used.

## Uninstalling a package

To uninstall a package, simply delete the InstalledPackage CR:

```bash
$ kapp delete -a pkg-demo
```
