---
title: Package Consumption
---

Before jumping in, we recommend reading through the docs about the new [packaging
apis](packaging.md) to familiarize yourself with the YAML configuration used in these
workflows.

## Prerequisites

If you'd rather use a canned environment, you can follow our [katacoda tutorial](https://katacoda.com/carvel/scenarios/kapp-controller-package-management).

* You will need to [install the latest release](install.md) of kapp-controller on a
  Kubernetes cluster to go through the examples.
* The instructions below assume [`kapp`](/kapp) and `kubectl` are installed.
* The instructions assume you are targeted at the default namespace

## Adding package repository

kapp-controller needs to know which packages are available to install. One way
to let it know about available packages is by creating a package repository.
To do this, we need a PackageRepository CR:

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
packages found within the `k8slt/kctrl-pkg-repo:1.0.0` imgpkg bundle, which is
stored in an OCI registry. Save this PackageRepository to a file named repo.yml
and then apply it to the cluster using kapp:

```bash
$ kapp deploy -a repo -f repo.yml -y
```

Once the deploy has finished, we are able to list the package metadatas to see,
at a high level, which packages are now available within our namespace:

```bash
$ kubectl get packagemetadatas
NAME                  DISPLAY NAME   CATEGORIES   SHORT DESCRIPTION        AGE
simple-app.corp.com   Simple App     demo         Simple app for demoing   2s
```

If we want, we can inspect the metadata further to get more detailed, high-level
info:

```bash
$ kubectl get packagemetadata simple-app.corp.com -o yaml
```

This will show us the PackageMetadata yaml, which will look something like this:

```yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: simple-app.corp.com
spec:
  categories:
  - demo
  displayName: Simple App
  longDescription: Simple app consisting of a k8s deployment and service
  shortDescription: Simple app for demoing
```

Once we have found metadata for a package which fits what we are looking for,
we can take a look at what versions of that package are available. To do this,
we can list the Package CRs in the cluster:

```bash
$ kubectl get packages
```

If there are numerous available packages, each with many versions, this list can
become a bit unwieldy, so we can also list the packages with a particular name
using the `--field-selector` option on kubectl get.

```bash
$ kubectl get packages --field-selector spec.refName=simple-app.corp.com
NAME                             PACKAGE NAME          VERSION      AGE
simple-app.corp.com.1.0.0        simple-app.corp.com   1.0.0        8m45s
simple-app.corp.com.2.0.0        simple-app.corp.com   2.0.0        8m45s
simple-app.corp.com.3.0.0-rc.1   simple-app.corp.com   3.0.0-rc.1   8m45s
```

From here, if we are interested, we can further inspect each version to discover
information such as release notes, installation steps, licenses, etc. For
example,

```bash
$ kubectl get package simple-app.corp.com.1.0.0 -o yaml
```

will show us more details on version `1.0.0` of the `simple-app.corp.com` package:

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: simple-app.corp.com.1.0.0
spec:
  refName: simple-app.corp.com
  version: 1.0.0
  releaseNotes: |
    Initial release of the simple app package
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
      fetch:
      - imgpkgBundle:
          image: index.docker.io/k8slt/kctrl-example-pkg@sha256:8ffa7f9352149dba1d539d0006b38eda357917edcdd39b82497a61dab2c27b75
      template:
      - ytt:
          paths:
          - config/
      - kbld:
          paths:
          - '-'
          - .imgpkg/images.yml
      deploy:
      - kapp: {}
```

Here we can see this version will fetch the templates stored in the
`k8slt/kctrl-example-pkg:1.0.0` bundle, template them using ytt and kbld, and
finally deploy them using kapp. Once deployed, there will be a basic greeter app
running in the cluster. Since this is what we want, we can now move on to
installation.

## Installing a package

Once we have the packages available for installation (as seen via `kubectl get
packages`), we need to let kapp-controller know which package we want to install. 
To do this, we will need to create a PackageInstall CR (and a secret to hold the
values used by our package):

```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: pkg-demo
spec:
  serviceAccountName: default-ns-sa
  packageRef:
    refName: simple-app.corp.com
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

This CR references the Package we decided to create in the previous section
using the package's `refName` and `version` fields. Do note, the `versionSelection`
property has a `constraints` subproperty to give more control over which
versions are chosen for installation. More information on PackageInstall versioning
can be found [here](packaging#versioning-packageinstalls).

This yaml snippet also contains a Kubernetes secret, which is referenced by the
PackageInstall. This secret is used to provide customized values to the package
installation's templating steps. Consumers can discover more details on the
configurable properties of a package by inspecting the Package CR's
valuesSchema.

Finally, to install the above package, we will also need to create `default-ns-sa` service
account (refer to [Security model](security-model.md) for explanation of how
service accounts are used) that give kapp-controller privileges to create
resources in the default namespace:

```bash
$ kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/examples/rbac/default-ns.yml -y
```

Save the PackageInstall above to a file named pkginstall.yml and then apply the
PackageInstall using kapp:

```bash
$ kapp deploy -a pkg-demo -f pkginstall.yml -y
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
$ kubectl port-forward service/simple-app 3000:80
```

Then, from another window:

```bash
$ curl localhost:3000
<h1>Hello hi!</h1>%
```

And we see that our hello_msg value is used.

## Uninstalling a package

To uninstall a package, simply delete the PackageInstall CR:

```bash
$ kapp delete -a pkg-demo -y
```

Also remember to cleanup the RBAC created for the PackageInstall:

```bash
$ kapp delete -a default-ns-rbac -y
```
