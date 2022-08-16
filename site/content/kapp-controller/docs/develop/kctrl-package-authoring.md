---
title: Authoring packages with kctrl
---

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

### Relevant FAQs
- [How can we add additional configuration to an upstream release artifact?](/kapp-controller/docs/develop/kctrl-faq/#how-can-we-add-ytt-overlays-or-additional-configuration-to-upstream-release-artifacts)
- [How can we go about updating packages dependent on an upstream release?](http://localhost:1313/kapp-controller/docs/develop/kctrl-faq/#how-can-we-go-about-updating-a-package-dependent-on-an-upstream-release)

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

We will need a Deployment and a Service pointing to it to deploy this project. We can define these in `config/config.yml`.
The image defined by the `Dockerfile` must be built and pushed to an OCI registry (`100mik/simple-app` in this case).

(See [here](/kapp-controller/docs/develop/kctrl-faq/#how-can-i-build-images-while-releasing-a-package-using-kctrl) to see how
we can have `kctrl` build images while releasing)
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
        image: 100mik/simple-app
        env:
        - name: HELLO_MSG
          value: stranger
```
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

Congratulations! `simple-app`s first Carvel package has been created using `kctrl`.

### Relevant FAQs
- [How can I build images while releasing a package with `kctrl`?](/kapp-controller/docs/develop/kctrl-faq/#how-can-i-build-images-while-releasing-a-package-using-kctrl)
- [How can we add information to PackageMetadata generated by `kctrl package release`?](/kapp-controller/docs/develop/kctrl-faq/#how-can-we-add-information-to-packagemetadata-generated-by-kctrl-pacakge-release)
- [Can kctrl be used to publish packages in a CI pipeline?](/kapp-controller/docs/develop/kctrl-faq/#can-kctrl-be-used-to-publish-packages-in-a-ci-pipeline)
-[Can we provide our own ImagesLock resource?](/kapp-controller/docs/develop/kctrl-faq/#can-we-provide-our-own-imageslock-resource-instead-of-it-being-generated-when-we-run-the-pkg-release-command)


## Creating a package repository
`kctrl` can be used to release packages grouped together as a PackageRepository.
In this tutorial, let's bundle the two packages created in the previous tutorial into a PackageRepository.

Let us create a folder for out repository, in the same directory where the other two projects exist.
```bash
$ mkdir demo-repo
$ tree -L 1
.
├── certman-package
├── demo-repo
└── simple-app
```

The `--repo-output` flag can be used while releasing a package to create artifacts in the prescribed [PackageRepository bumdle](http://localhost:1313/kapp-controller/docs/develop/packaging-artifact-formats/#package-repository-bundle) format at a specified location.
Let us make releases for both these packages while creating a repo bundle in the `demo-repo` folder.
```bash
# Releasiong package for cert-manager
$ cd certmanager-package
$ kctrl package release --version 1.0.0 --repo-output ../demo-repo

# Releasing package for simple-app
$ cd ../simple-app
$ kctrl package release --version 1.0.0 --repo-output ../demo-repo
```

Let's verify that the artifacts created in the `demo-repo` folder are in the desired bundle format.
```bash
$ cd ../demo-repo
$ tree
└── packages
    ├── certmanager.carvel.dev
    │   ├── 1.0.0.yml
    │   └── metadata.yml
    └── simple-app.carvel.dev
        ├── 1.0.0.yml
        └── metadata.yml
```
`kctrl` can now be used to create a repository bundle and publish it on an OCI registry.
```bash
$ kctrl package repo release
```
`kctrl` first asks us to name our repository. We will be calling ours `demo.carvel.dev`.
![Package Release Step 1](/images/kctrl/pkg-repo-release-1.png)

We are then required to specify the OCI registry we want to push our repository bundle to.
This bundle will contain all config required by the PackageRepositopry to create the required Packages on the cluster.
![Package Release Step 2](/images/kctrl/pkg-repo-release-2.png)

Once `kctrl` has the required details it builds an `imgpkg` bundle and publishes it on an OCI registry.
![Package Release Step 3](/images/kctrl/pkg-repo-release-3.png)

Two files are created when a PackageRepository is released successfully. 

`pkgrepo-build.yml` stores some metadata generated using the user inputs during the first release.
This can be comitted to a `git` repository, if users want to do releases in their CI pipelines.

`package-repository.yml` has a PackageRepository resource that can be applied to the cluster directly.

Let's use `kctrl` to add the repository to the cluster. We can use the bundle location that we can see in the output.
This location is also stored in the `package-repository.yml` artifact.
```bash
$ kctrl package repository add -r demo-repo --url index.docker.io/100mik/demo-repo@sha256:f726d5d5264183c7cd6503237e25c641b1d5b41d5df6128174cea5931ff27df0
```
Once the repository is added successfully we should be able to see our packages on the cluster.
```bash
$ kctrl package available list
Target cluster 'https://127.0.0.1:49841' (nodes: minikube)

Available summarized packages in namespace 'default'

Name                    Display name  
certmanager.carvel.dev  certmanager  
simple-app.carvel.dev   simple-app  

Succeeded
```
Great! We have now bundled and published two of our packages together as a PackageRepository.

## Testing packages locally
`kctrl` enables users authoring Apps and Packages using `kapp-controller`'s APIs to test their resources effectively.
Let us test our `simple-app` package locally. 

This can be done by using the `dev` command, and it does not require `kapp-controller` to be installed
on the cluster. The fetch and template steps are done locally on the host running the command before
using `kapp` to deploy the resources on the cluster.

Let us take a look at the `package-resources.yml` file generated by `kctrl` while initialising the package.
```yaml
#package-resources.yml

apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  creationTimestamp: null
  name: simple-app.carvel.dev.0.0.0
spec:
  refName: simple-app.carvel.dev
  releasedAt: null
  template:
    spec:
      deploy:
      - kapp: {}
      fetch:
      - git: {}
      template:
      - ytt:
          paths:
          - config
      - kbld: {}
  valuesSchema:
    openAPIv3: null
  version: 0.0.0

---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  creationTimestamp: null
  name: simple-app.carvel.dev
spec:
  displayName: simple-app
  longDescription: simple-app.carvel.dev
  shortDescription: simple-app.carvel.dev

---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  annotations:
    kctrl.carvel.dev/local-fetch-0: .
  creationTimestamp: null
  name: simple-app
spec:
  packageRef:
    refName: simple-app.carvel.dev
    versionSelection:
      constraints: 0.0.0
  serviceAccountName: simple-app-sa
status:
  conditions: null
  friendlyDescription: ""
  observedGeneration: 0
```
The `dev` command will process these resources just like they would on the cluster.
However, we would like to build an image from source and use the configuration in the root of the directory.
We use the `--local` and `--build` flags to indicate this.

`kctrl` needs to be informed where it can find the folder `config`. This is done by using the annotation 
`kctrl.carvel.dev/local-fetch-0: .` on the PackageInstall resource. It tells `dev` that
the files `kapp-controller` would otherwise fetch, is available in the root of the project.

Let's build and deploy from source.
```bash
$ kctrl dev -f package-resources.yml
Target cluster 'https://192.168.64.10:8443' (nodes: minikube)

apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  annotations:
    kctrl.carvel.dev/local-fetch-0: .
  creationTimestamp: null
  name: simple-app
  namespace: default
spec:
  packageRef:
    refName: simple-app.carvel.dev
    versionSelection:
      constraints: 0.0.0
  serviceAccountName: cluster-admin-sa
status:
  conditions: null
  friendlyDescription: ""
  observedGeneration: 0

Reconciling in-memory app/simple-app (namespace: default) ...
==> Executing /usr/local/bin/vendir [vendir sync -f - --lock-file /dev/null]
==> Finished executing /usr/local/bin/vendir

==> Executing /usr/local/bin/ytt [ytt -f /var/folders/8n/8x1y1v2s6bs1cm5nmdmc63th0000gn/T/kapp-controller-fetch-template-deploy2431122835/0/config]
==> Finished executing /usr/local/bin/ytt

==> Executing /usr/local/bin/kbld [kbld -f -]
==> Finished executing /usr/local/bin/kbld

==> Executing /usr/local/bin/kapp [kapp deploy -f - --app-changes-max-to-keep=5 --app simple-app-ctrl --kubeconfig=/dev/null --yes]

1:56:42AM: Fetch started (14s ago)
1:56:42AM: Fetching (13s ago)
	    | apiVersion: vendir.k14s.io/v1alpha1
	    | directories:
	    | - contents:
	    |   - directory: {}
	    |     path: .
	    |   path: "0"
	    | kind: LockConfig
	    | 
1:56:42AM: Fetch succeeded (13s ago)
1:56:54AM: Template succeeded (2s ago)
1:56:54AM: Deploy started (2s ago)
1:56:56AM: Deploying 
	    | Target cluster 'https://192.168.64.10:8443' (nodes: minikube)
	    | Changes
	    | Namespace  Name        Kind        Age  Op      Op st.  Wait to    Rs  Ri
	    | default    simple-app  Deployment  -    create  -       reconcile  -   -
	    | ^          simple-app  Service     -    create  -       reconcile  -   -
	    | Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
	    | Wait to: 2 reconcile, 0 delete, 0 noop
	    | 1:56:54AM: ---- applying 2 changes [0/2 done] ----
	    | 1:56:54AM: create deployment/simple-app (apps/v1) namespace: default
	    | 1:56:54AM: create service/simple-app (v1) namespace: default
	    | 1:56:54AM: ---- waiting on 2 changes [0/2 done] ----
	    | 1:56:54AM: ok: reconcile service/simple-app (v1) namespace: default
	    | 1:56:54AM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
	    | 1:56:54AM:  ^ Waiting for generation 2 to be observed
	    | 1:56:54AM:  L ok: waiting on replicaset/simple-app-6b69449d66 (apps/v1) namespace: default
	    | 1:56:54AM: ---- waiting on 1 changes [1/2 done] ----
	    | 1:56:55AM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
	    | 1:56:55AM:  ^ Waiting for 1 unavailable replicas
	    | 1:56:55AM:  L ok: waiting on replicaset/simple-app-6b69449d66 (apps/v1) namespace: default
	    | 1:56:55AM:  L ongoing: waiting on pod/simple-app-6b69449d66-4gv8m (v1) namespace: default
	    | 1:56:55AM:     ^ Pending: ContainerCreating
	    | 1:56:57AM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
	    | 1:56:57AM: ---- applying complete [2/2 done] ----
	    | 1:56:57AM: ---- waiting complete [2/2 done] ----
	    | Succeeded
1:56:57AM: Deploy succeeded 
==> Finished executing /usr/local/bin/kapp

Succeeded
```
We can see the result of the steps `kapp-controller` would perform while creating resources when
the package is installed.

`dev` has created a `kapp` app (`simple-app-ctrl`) on the cluster.
The resources that are a part of the app can be inspected,
```bash
$ kapp inspect -a simple-app-ctrl
Target cluster 'https://192.168.64.10:8443' (nodes: minikube)

Resources in app 'simple-app-ctrl'

Namespace  Name                         Kind           Owner    Rs  Ri  Age  
default    simple-app                   Deployment     kapp     ok  -   18m  
^          simple-app                   Endpoints      cluster  ok  -   18m  
^          simple-app                   Service        kapp     ok  -   18m  
^          simple-app-6b69449d66        ReplicaSet     cluster  ok  -   18m  
^          simple-app-6b69449d66-4gv8m  Pod            cluster  ok  -   18m  
^          simple-app-shzpj             EndpointSlice  cluster  ok  -   18m  

Rs: Reconcile state
Ri: Reconcile information

6 resources

Succeeded
```
We can delete the app created once we are satisfied with the results,
```bash
$ kapp delete -a simple-app-ctrl --yes
```
Thus, we can reproduce the state that a package installation would create reliably!
