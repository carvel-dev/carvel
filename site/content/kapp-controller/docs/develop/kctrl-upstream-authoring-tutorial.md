---
title: Packaging upstream artifacts with CLI
---
This tutorial explores how `kctrl` allows us to create Carvel packages using existing artifacts like manifests released as a part of a GitHub release or a Helm chart.
For this tutorial we will package a release of `cert-manager` as a Carvel package.

## Getting started

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

## Releasing packages

Now that `kctrl` knows what it is dealing with, we can use the release command to make a publish Package and PackageMetadata resources.

We just provide a image registry that `kctrl` can push OCI images to. Ensure that your host is authorised to push to the registry.

![Package Release for Cert Manager](/images/kctrl/pkg-release-certman.png)

`kctrl` first tries to build any images that are necessary, however, in our case we do not have any images that need to be built as we are consuming a released artifact.

It then creates the required artifact in the `carvel-artifacts` directory.
```bash
$ ls carvel-artifacts/packages/certmanager.carvel.dev
metadata.yml package.yml

$ cat carvel-artifacts/packages/certmanager.carvel.dev/package.yaml
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

$ cat carvel-artifacts/packages/certmanager.carvel.dev/metadata.yaml
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

Congratulations! You have packaged a released artifact as a Carvel package.

## FAQs

### How can we add ytt overlays and values schema for upstream release artifacts?
Overlays can be created in a separate folder in the project directory. `kctrl` can be made aware of any additional folders by updating `package-build.yml` manually,
If the project directory looks something like this,
```bash
.
├── package-build.yml
├── package-resources.yml
├── upstream
│   └── cert-manager.yaml
├── overlays
│   └── overlay.yaml
│   └── values-schema.yaml
├── vendir.lock.yml
└── vendir.yml
```
Where, the directory overlays containing `ytt` is created by the user. The fields `includePaths` and the `template` section of the App `spec` needs to be updated in `package-build.yml` like this,
```
apiVersion: kctrl.carvel.dev/v1alpha1
kind: PackageBuild
metadata:
  name: certmanager.carvel.dev
spec:
  release:
  - resource: {}
  template:
    spec:
      app:
        spec:
          deploy:
          - kapp: {}
          template:
          - ytt:
              paths:
              - upstream
              - overlays
          - kbld: {}
      export:
      - imgpkgBundle:
          image: 100mik/certman-carvel-package
          useKbldImagesLock: true
        includePaths:
        - upstream
        - overlays
```
This is to ensure that the package is aware of the additional files, while `includePaths` ensures that the folder is a part of the `imgpkg` bundle created by `kctrl`.

The template section in `package-resources.yml` should be updated in a similar fashion to ensure that `kctrl dev deploy` yields similar results.

`kctrl` generates the OpenAPI schema for a package if a values schema is provided.

### How can packages be tested without releasing them?
`kctrl` creates a "mock" Package and PackageMetadata resources in the file `package-resources.yml`. This enables users to run `kctrl dev deploy` to deploy resources a package installation would create without having to release the package or installing `kapp-controller` on the cluster.
