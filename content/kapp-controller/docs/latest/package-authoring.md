---
title: Package Authoring
---

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

Once we have configuration figured out let's use `kbld` to record which container images are used:

```bash
$ mkdir -p package-contents/.imgpkg
$ kbld -f package-contents/config/ --imgpkg-lock-output package-contents/.imgpkg/images.yml
```

For more on using kbld to populate the `.imgpkg` directory with an ImageLock, and why it is useful,
see the [imgpkg docs on the subject](/imgpkg/docs/latest/resources/#imageslock-configuration)

Once these files have been added, our package contents bundle is ready to be pushed:

```bash
$ imgpkg push -b registry.corp.com/packages/simple-app:1.0.0 -f package-contents/
dir: .
file: .imgpkg/images.yml
file: config/config.yml
file: config/values.yml
Pushed 'registry.corp.com/packages/simple-app@sha256:e6255cc...'
Succeeded
```

### Creating the Package CR

Final step in creating a package is to make a [Package CR](packaging.md#package-cr) that stores metadata such as name, description, how to install, etc. For this example, we will choose `simple-app.corp.com` as a name for our package with a semantic version `1.0.0`.

Once the package metadata is filled in, we will need to complete the template section. This is an App template, so take a look at the [app-spec](app-spec.md) section to learn more about what each of the template sections are for. For this example, we have chosen a basic setup that will fetch the imgpkg bundle we created in the previous section, run the templates stored inside through ytt, apply kbld transformations, and then deploy the resulting manifests with kapp.

The result should end up looking something like this:

```yaml
apiVersion: package.carvel.dev/v1alpha1
kind: Package
metadata:
  # Kubernetes name is not used for anything specific but is still required.
  # Use ${spec.publicName}.#{spec.version} as a convetion
  name: simple-app.corp.com.1.0.0
spec:
  # publicName will be used by consumers of this package.
  # publicName should be unique across all packages, hence we
  # recommend to use fully qualified name similar to what
  # would be used as a name for a CRD.
  publicName: simple-app.corp.com
  # version will be used by consumers of this package.
  # must be a valid semantic version string.
  version: "1.0.0"
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: registry.corp.com/packages/simple-app:1.0.0
      template:
      - ytt:
          paths:
          - config/
      - kbld:
          paths:
          - -
          - .imgpkg/images.yml
      deploy:
      - kapp: {}
```

Lets store this in a file named `simple-app.corp.com.1.0.0.yml`.

---
### Testing your package

Now that we have our Package CR defined, we can test it on the cluster. We will momentarily act as a package consumer. First, we need to make our package available on the cluster, so let's apply the Package CR we just created directly to the cluster:

```
$ kapp deploy -a package -f simple-app.corp.com.v1.0.0.yml
```

Typically Package CR is made available to the cluster from a package repository, however, in this case it's useful to apply it to the cluster directly since we might need to change it a few times to get things right.

Follow [Installing a package](package-consumption.md#installing-a-package) step from Package consumption workflow to verify that your package can be successfully installed.

(TODO add more info about InstalledPackage status and associated App CR.)

---
### Creating a Package Repository

A package repository is a collection of packages (more specifically collection of Package CRs). Currently our recommended way to make a package repository is by making it an OCI image. (Note that we are actively working on making it possible for package repository to be an imgpkg bundle instead of a plain image. Stay tuned.)

The filesystem structure for package repository image should look like this:

```bash
my-pkg-repo
└── packages
    └── simple-app.corp.com.1.0.0.yml
```

Lets start by creating the needed directories:

```bash
$ mkdir -p my-pkg-repo/packages
```

Once the directories are created, we can copy our Package CR YAML in to the bundle's `packages` directory:

```bash
cp simple-app.corp.com.1.0.0.yml my-pkg-repo/packages
```

With the metadata files present, we can push our repo image to whatever OCI registry we plan to distribute it from:

```bash
$ imgpkg push -i registry.corp.com/packages/my-pkg-repo:1.0.0 -f my-pkg-repo
```

Package repository is pushed! Follow [Adding package repository](package-consumption.md#installing-a-package) step from Package consumption workflow to see how to let kapp-controller know about this repository.
