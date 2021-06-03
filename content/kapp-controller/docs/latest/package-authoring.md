---
title: Package Authoring
---

Available in [v0.17.0-alpha.1+](https://github.com/vmware-tanzu/carvel-kapp-controller/tree/dev-packaging/alpha-releases)

Before jumping in, we recommend reading through the docs about the new [packaging
APIs](packaging.md) to familiarize yourself with the YAML configuration used in these
workflows. 

This workflow walks through an example that will help a user transform a stack
of plain Kubernetes manifests in to a Package within a PackageRepository. This will
allow them to distribute their apps in a way that is easily installable by any
consumers running a kapp-controller in their cluster.

## Prerequisites

To go through the examles below, the following prerequisites are assumed:
* You will need to [install the alpha release](install-alpha.md) of kapp-controller on a Kubernetes cluster.
* These workflows also assume some of the other Carvel tools are installed on your
system, namely `kapp`, `imgpkg`, and `kbld`. For more info on how to install
these, see our [install section on the homepage](/#whole-suite).

## Creating a package

### Configuration

For this demo, we will be using [ytt](/ytt) templates that describe simple Kubernetes Deployment and Service. These templates will install a simple greeter app with a templated hello message. The templates consist of two files:

`config.yml`:

```yaml
#@ load("@ytt:data", "data")

#@ def labels():
simple-app: ""
#@ end

---
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: simple-app
spec:
  ports:
  - port: #@ data.values.svc_port
    targetPort: #@ data.values.app_port
  selector: #@ labels()
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: simple-app
spec:
  selector:
    matchLabels: #@ labels()
  template:
    metadata:
      labels: #@ labels()
    spec:
      containers:
      - name: simple-app
        image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
        env:
        - name: HELLO_MSG
          value: #@ data.values.hello_msg
```

and `values.yml`:

```yaml
#@data/values
---
svc_port: 80
app_port: 80
hello_msg: stranger
```

We'll need both of these files, so save them somewhere on your filesystem.

### Package Contents Bundle

The first step in creating our package is to create an [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) that contains package contents: above configuration (`config.yml` and `values.yml`) and a reference to greeter app image (`docker.io/dkalinin/k8s-simple-app@sha256:...`).

To start, lets create a directory with above configuration files:

```bash
$ mkdir -p package-contents/config/
$ mv <path to config.yml> package-contents/config/config.yml
$ mv <path to values.yml> package-contents/config/values.yml
```

([Package bundle format](packaging.md#package-bundle-format) describes purpose of each directory and general recommendations.)

Once we have configuration figured out let's use `kbld` to record which container images are used:

```bash
$ mkdir -p package-contents/.imgpkg
$ kbld -f package-contents/config/ --imgpkg-lock-output package-contents/.imgpkg/images.yml
```

For more on using kbld to populate the `.imgpkg` directory with an ImagesLock, and why it is useful,
see the [imgpkg docs on the subject](/imgpkg/docs/latest/resources/#imageslock-configuration)

Once these files have been added, our package contents bundle is ready to be pushed as shown below
(**NOTE:** replace `registry.corp.com/packages/` if working through example):

```bash
$ imgpkg push -b registry.corp.com/packages/simple-app:1.0.0 -f package-contents/
dir: .
file: .imgpkg/images.yml
file: config/config.yml
file: config/values.yml
Pushed 'registry.corp.com/packages/simple-app@sha256:e6255cc...'
Succeeded
```

### Creating the CRs

To finish creating a package, we need to create two CRs. The first CR is the
Package CR, which will contain high level information and descriptions about our
package. For example,

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  # This will be the name of our package
  name: simple-app.corp.com
spec:
  displayName: "Simple App"
  longDescription: "Simple app consisting of a k8s deployment and service"
  shortDescription: "Simple app for demoing"
  categories:
  - demo
```

When creating this CR, the api will validate that the Package's name is a fully
qualified name, that is it must have at least three segments separated by `.`
and cannot have a trailing `.`. For reference, the above example's Package name is
valid.

Before moving on, save this yaml snippet to a file named
`package.yml`.

Lastly, we need to create a PackageVersion CR. This CR is exactly what the name
implies: versioned metadata used to install packaged sofwtare that fits the
description provided in the Package CR we just created. An example
PackageVersion CR follows.

```yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageVersion
metadata:
  name: simple-app.corp.com.1.0.0
spec:
  packageName: simple-app.corp.com
  version: 1.0.0
  releaseNotes: |
    Initial release of the simple app package
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: registry.corp.com/packages/simple-app:1.0.0
      template:
      - ytt:
          paths:
          - "config.yml"
          - "values.yml"
      - kbld:
          paths:
          - "-"
          - ".imgpkg/images.yml"
      deploy:
      - kapp: {}
```
This PackageVersion contains some metadata fields specific to the verison, such
as releaseNotes, but the main component of it is the template section, which
informs kapp-controller of the actions required to install the packaged
software. This section is an App template, so take a look at the
[app-spec](app-spec.md) section to learn more about what each of the template
sections are for. For this example, we have chosen a basic setup that will fetch
the imgpkg bundle we created in the previous section, run the templates stored
inside through ytt, apply kbld transformations, and then deploy the resulting
manifests with kapp.

There will also be validations run on the PackageVersion CR, so ensure that
`spec.packageName` and `spec.version` are not empty and that `metadata.name`
begins with `<spec.packageName>.`. These are done to encourage a naming scheme
that keeps package version names unique.

Lets store this in a file named `1.0.0.yml`. Remember to replace
`registry.corp.com/packages/` in the YAML above with your registry and repository if
following along.

---
### Testing your package

Now that we have our Package CR defined, we can test it on the cluster. We will
momentarily act as a package consumer. First, we need to make our package
available on the cluster, so let's apply the Package CR we just created directly
to the cluster:

```
$ kapp deploy -a package -f simple-app.corp.com.yml -f simple-app.corp.com.1.0.0.yml
```

Typically Package CR is made available to the cluster from a package repository,
however, in this case it's useful to apply it to the cluster directly since we
might need to change it a few times to get things right.

Follow [Installing a package](package-consumption.md#installing-a-package) step
from Package consumption workflow to verify that your package can be
successfully installed.

While iterating on your package, it may be useful to check out the [debugging
docs](debugging.md) for help troubleshooting the package or the underlying app.

---
### Creating a Package Repository

A [package repository bundle](packaging.md#package-repository-bundle-format) is
a collection of packages (more specifically collection of Package CRs).
Currently our recommended way to make a package repository is by making it an
[imgpkg bundle](/imgpkg/docs/latest/resources/#bundle).

The filesystem structure for package repository bundle looks like this:

```bash
my-pkg-repo/
└── .imgpkg/
    └── images.yml
└── packages/
    └── simple-app.corp.com
        └── package.yml
        └── 1.0.0.yml
```

([Package Repository bundle
format](packaging.md#package-repository-bundle-format) describes purpose of each
directory and general recommendations.)

Lets start by creating the needed directories:

```bash
$ mkdir -p my-pkg-repo/.imgpkg my-pkg-repo/packages/simple-app.corp.com
```

Once the directories are created, we can copy our CR YAMLs from the previous
step in to the proper `packages` subdirectory, in this case `simple-app.corp.com`:

```bash
$ cp 1.0.0.yml my-pkg-repo/packages/simple-app.corp.com
$ cp package.yml my-pkg-repo/packages/simple-app.corp.com
```

Next, let's use `kbld` to record which package bundles are used:

```bash
$ kbld -f my-pkg-repo/packages/ --imgpkg-lock-output my-pkg-repo/.imgpkg/images.yml
```

With the metadata files present, we can push our bundle to whatever OCI registry
we plan to distribute it from:

```bash
$ imgpkg push -b registry.corp.com/packages/my-pkg-repo:1.0.0 -f my-pkg-repo
```

The package repository is pushed. Follow the [Adding package
repository](package-consumption.md#adding-package-repository) step from the
package consumption workflow to see an example of adding and using a
PackageRepository with kapp-controller.
