---
title: Building packages from source with kctrl
---

This tutorial is a walk-through of how you use `kctrl` to build and package your project as a Carvel package.

For this tutorial we will start off with a [simple web server](https://github.com/cppforlife/simple-app).
We create resources to deploy the application on Kubernetes and then release a Carvel package for the same using `kctrl`.

First, the playground can be set up by cloning the project we are working with.
```bash
$ git clone https://github.com/cppforlife/simple-app
$ cd simple-app
```

## Putting together some configuration

We can add a `config` directory to store our Kubernetes config.
```bash
$ mkdir config
```

We will need a Deployment and a Service pointing to it to deploy this project. We can define these in `config/config.yml`
```yaml
# config/config.yml
---
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: simple-app
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    simple-app: ""
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: simple-app
spec:
  selector:
    matchLabels:
      simple-app: ""
  template:
    metadata:
      labels:
        simple-app: ""
    spec:
      containers:
      - name: simple-app
        image: simple-app
        env:
        - name: HELLO_MSG
          value: stranger
```
Here `HELLO_MSG` is an environment variable consumed by the server.

The image `simple-app` needs to be built using the Dockerfile defined in the root of the project.
`kctrl` can do this for us if we define a `kbld` Config which specifies this. Let us do this in `config/config-release.yml`
```yaml
# config/config-release.yml
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: simple-app
  path: .
destinations:
- image: simple-app
  newImage: 100mik/simple-app
```
Here, we are expressing that the image referred to as `simple-app` needs to be built from the root of the project (the path being `.`).
And pushed to container registry `100mik/simple-app`.

When `kctrl` builds images and resolves image references it uses the tool [`kbld`](/kbld) under the hood.
More details about `kbld` configuration can be found [here](/kbld/docs/latest/config/).

Great! We now have our configuration in place.

## Setting up `kctrl` 
We can get `kctrl` up and running using the `init` command.
```bash
$ kctrl package init
```

This command asks a few questions regarding how we want to build our package.
In this case, we want to build a package `simple-app.carvel.dev` from the local directory.
The configuration for the same can be found in the `config` directory. The interaction looks something like this,

![Package Init for Simple App](/images/kctrl/pkg-init-simple-app.png)

This command generates some files that tell `kctrl` how it should put the package together!

## Releasing the package

We can release the first version of our carvel package using the `release` command now!
```bash
$ kctrl package release --version 1.0.0
```
At this step we need to tell kctrl where we want to push our `imgpkg` bundle.
Which is essentially an OCI image that contains all necessary config.
The interaction looks something like this,

![Package Release for Simple App](/images/kctrl/pkg-release-simple-app.png)

This command creates the Package and PackageMetadata resources in directory `carvel-artifacts`.
```yaml
# carvel-artifacts/packages/simple-app.carvel.dev/package.yml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: simple-app.carvel.dev.1.0.0
spec:
  refName: simple-app.carvel.dev
  releasedAt: "2022-08-08T20:46:18Z"
  template:
    spec:
      deploy:
      - kapp: {}
      fetch:
      - imgpkgBundle:
          image: index.docker.io/100mik/simple-package@sha256:dbf26c20859b32c0e08711c3af28844cc3e54968c3fa39e1975912ccbbb52899
      template:
      - ytt:
          paths:
          - config
      - kbld:
          paths:
          - '-'
          - .imgpkg/images.yml
  valuesSchema:
    openAPIv3:
      default: null
      nullable: true
  version: 1.0.0
# carvel-artifacts/packages/simple-app.carvel.dev/metadata.yml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: simple-app.carvel.dev
spec:
  displayName: simple-app
# longDescription: Detailed description of package
# shortDescription: Concise description of package
# providerName: Organization/entity providing this package
# maintainers:
#   - name: Maintainer 1
#   - name: Maintainer 2
```
We can add these packages to the cluster using `kapp`.
```bash
kapp deplot -a simple-app-package -f carvel-artifacts/packages/simple-app.carvel.dev
```
(`kubectl apply` would yield the same result)

We should now be able to see our package on the cluster
```bash
$ kctrl package list
Target cluster 'https://127.0.0.1:49841' (nodes: minikube)

Installed packages in namespace 'default'

Name  Package Name           Package Version  Status  
simp  simple-app.carvel.dev  1.9.0            Reconcile succeeded  

Succeeded
```

We can install the package on the cluster to create the packaged resources.
```bash
$ kctrl package install -i simple-app -p simple-app.carvel.dev --version 1.0.0
```

Congratulations! `simple-app`s first Carvel package has been published using `kctrl`.

## FAQs

### Can `kctrl` be used to publish packages in a CI pipeline?
Yes! `kctrl` remembers the answers to questions that have been answered.
The `--yes` flag can be used to run the `release` command while using previously supplied
values if `package-resources.yml` and `package-metadata.yml` are committed to a repository with the source code.
