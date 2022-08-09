---
title: Authoring packages with kctrl
---

## Building packages from source
This tutorial is a walk-through of how `kctrl` can be used to build and package your project as a Carvel package.

For this tutorial we will start off with a [simple web server](https://github.com/cppforlife/simple-app).
We create resources to deploy the application on Kubernetes and then release a Carvel package for the same using `kctrl`.

First, the playground can be set up by cloning the project we are working with.
```bash
$ git clone https://github.com/cppforlife/simple-app
$ cd simple-app
```

### Putting together some configuration

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

`kctrl` builds images and resolves image references using the tool [`kbld`](/kbld) under the hood.
More details about `kbld` configuration can be found [here](/kbld/docs/latest/config/).

Great! We now have our configuration in place.

### Setting up `kctrl` 
We can get `kctrl` up and running using the `init` command.
```bash
$ kctrl package init
```

This command asks a few questions regarding how we want to build our package.
In this case, we want to build a package `simple-app.carvel.dev` from the local directory.
The configuration for the same can be found in the `config` directory. The interaction looks something like this,

![Package Init for Simple App](/images/kctrl/pkg-init-simple-app.png)

This command generates some files that tell `kctrl` how it should put the package together!

### Releasing the package

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
kapp deploy -a simple-app-package -f carvel-artifacts/packages/simple-app.carvel.dev
```
(`kubectl apply` would yield the same result)

We should now be able to see our package on the cluster
```bash
$ kctrl package available list
Target cluster 'https://127.0.0.1:62733' (nodes: minikube)

Available summarized packages in namespace 'default'

Name                    Display name  
simple-app.carvel.dev   simple-app  

Succeeded
```

We can install the package on the cluster to create the packaged resources.
```bash
$ kctrl package install -i simple-app -p simple-app.carvel.dev --version 1.0.0
```

Congratulations! `simple-app`s first Carvel package has been published using `kctrl`.

## Packaging upstream artifacts
This tutorial explores how `kctrl` allows us to create Carvel packages using existing artifacts like manifests released as a part of a GitHub release or a Helm chart.
For this tutorial we will package a release of `cert-manager` as a Carvel package.

### Getting started

To start off, let's create a directory which acts like our working directory.

```bash
$ mkdir certman-package
$ cd certman-package
```

Next we run the `init` command to set the stage!

`kctrl` asks a few quick questions to gather what it needs to know.
We know that `cert-manager` lives on the GitHub repository _cert-manager/cert-manager_ and that it's releases have a manifest `cert-manager.yaml` which let's users deploy cert-manager on cluster. Our goal would be to build a package around this artifact.

If we want to package `cert-manager v1.9.0`, we interact with package init somewhat like this:

![Package Init for Cert Manager](/images/kctrl/pkg-init-certman.png)

In the first step, we can see that the artifact could have been a helm chart or another artifact residing in the repository itself.

Once, `kctrl` knows where to find our config, it uses `vendir` to make a copy of the required artifacts in the upstream folder.
```bash
$ ls upstream
cert-manager.yaml
```

### Releasing packages

Now that `kctrl` knows what it is dealing with, we can use the release command to make a publish Package and PackageMetadata resources.

We just provide a image registry that `kctrl` can push OCI images to. Ensure that your host is authorised to push to the registry.

![Package Release for Cert Manager](/images/kctrl/pkg-release-certman.png)

`kctrl` first tries to build any images that are necessary, however, in our case we do not have any images that need to be built as we are consuming a released artifact.

It then creates the required artifacts in the `carvel-artifacts` directory.
```yaml
# carvel-artifacts/packages/certmanager.carvel.dev/package.yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  creationTimestamp: null
  name: certmanager.carvel.dev.1.9.0
spec:
  refName: certmanager.carvel.dev
  releasedAt: "2022-08-03T22:40:06Z"
  template:
    spec:
      deploy:
      - kapp: {}
      fetch:
      - imgpkgBundle:
          image: index.docker.io/100mik/certman-carvel-package@sha256:93a4e6d0577a0c56b69f7d7b24621d98bd205f69846a683a4dc5bcdd53879da5
      template:
      - ytt:
          paths:
          - upstream
      - kbld:
          paths:
          - '-'
          - .imgpkg/images.yml
  valuesSchema:
    openAPIv3:
      default: null
      nullable: true
  version: 1.9.0

# carvel-artifacts/packages/certmanager.carvel.dev/metadata.yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  creationTimestamp: null
  name: certmanager.carvel.dev
spec:
  displayName: certmanager
```
These artifacts can be used to create the necessary resources on the cluster.
```bash
$ kapp deploy -a cert-manager-package -f carvel-artifacts/packages/certmanager.carvel.dev
```
Once we have created these resources using `kapp`, we should be able to find these packages on the cluster using `kctrl`.
```bash
$ kctrl package available list
Target cluster 'https://127.0.0.1:62733' (nodes: minikube)

Available summarized packages in namespace 'default'

Name                    Display name  
certmanager.carvel.dev  certmanager  

Succeeded
```
