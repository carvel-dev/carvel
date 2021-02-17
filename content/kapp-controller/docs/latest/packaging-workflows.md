---
title: Packaging Workflows
---

Before jumping in, we recommend reading through the docs about the new [packaging
apis](packaging.md) to familiarize yourself with the yaml used in these
workflows.

These workflows also assume some of the other Carvel tools are installed on your
system, namely `kapp`, `imgpkg`, and `kbld`. For more info on how to install
these, see our [install section on the homepage](/#whole-suite)

## Package Authoring

This workflow walks through an example that will help a user transform a stack
of kubernetes manifests in to a Package within a PackageRepository. This will
allow them to distribute their apps in a way that is easily installable by any
consumers running a kapp-controller in their cluster.

### The Manifests

For this demo, we will be using [ytt](/ytt) templates that produce kubernetes manifests.
These manifests will install a simple greeter app with a templated hello
message. The templates consist of two files,

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

We'll need both of these, so save them somewhere on your filesystem.

### Creating the Package Contents Image

The first step in creating our package is to create the image which
contains the workload's manifests. This is can be done using
[imgpkg](/imgpkg).
To start, lets create a folder which will be our image:

```
$ mkdir package-contents-image
```

After we have our folder, lets go ahead and move the files with the above
manifests in to it:

```
$ mv <path to config.yml> package-contents-image/config.yml
$ mv <path to values.yml> package-contents-image/values.yml
```

Once these files have been added, our image is ready to be pushed:

```
$ imgpkg push -i <your repo>:v1.0.0 -f package-contents-image
dir: .
file: config.yml
file: values.yml
Pushed '<your-repo>@sha256:e6255cca205e4fb1335c6e816d6bbdd7ce13ec56cdca015966ec600bdefa93f5'
Succeeded
```

Now that we have an image which contains the workload we would like our package
to install, we can move on to creating the Package definition.

### Creating the Package

To create the package, we need to concoct a [Package CR](packaging.md#package-cr).

We will choose a name for our package, in this case `simple-app`, and
give it a valid semver version, here `v1.0.0`. We will also need a valid kubernetes
object name, which should just be the `publicName.version`.

Once the package metadata is filled in, we will need to complete the template section.
This is an App template, so take a look at the [app-spec](app-spec.md)
section to learn more about what each of the template sections are for. For this
example, we have chosen a basic setup that will fetch the image we created in
the last section, run the templates stored inside through ytt, and then
deploy the resulting manifests with kapp.

The result should end up looking something like this:

```yaml
apiVersion: package.carvel.dev/v1alpha1
kind: Package
metadata:
  name: simple-app.v1.0.0
spec:
  publicName: simple-app
  version: v1.0.0
  template:
    spec:
      fetch:
      - image:
          url: <your-repo>:v1.0.0
      template:
      - ytt:
          paths:
          - "config.yml"
          - "values.yml"
      deploy:
      - kapp: {}
```

Lets store this in a file named `simple-app.v1.0.0.yml`.

### Testing Your Package

Now that we have our Package CR defined, we can test it. To do this we will take
the role of a Package consumer. First, we need to make our package available to
the cluster, so let's apply the Package CR yaml we just created:

```
$ kapp deploy -a package -f simple-app.v1.0.0.yml
```

Secondly, to test our package, we will need a bit of [rbac
setup](security-model.md). Running this kapp command should set that all up for
us:

```
$ kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/examples/rbac/default-ns.yml
```

After that completes, we must now to tell kapp-controller we want an installed package.
For this we can apply the following InstalledPackage CR, which informs kapp
controller we would like version 1.0.0 of the simple-app package installed:

```yaml
apiVersion: install.package.carvel.dev/v1alpha1
kind: InstalledPackage
metadata:
  name: simple-app-test
  namespace: default
spec:
  serviceAccountName: default-ns-sa
  packageRef:
    publicName: simple-app
    version: 1.0.0
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
    #@data/values
    ---
    hello_msg: "hi"
```

After saving this to a file called `installedpackage.yml`, this can be applied using kapp:

```
$ kapp deploy -a simple-app-v1 -f installedpackage.yml
```

Kapp-controller should now reconcile the newly applied installed package. After
which, we will be able to see if installation succeeded or not. If not, we will
see a reconcile failed status. This can be debugged further by checking out the
App resource that was created and has a name similar to the installed package.
If the installed package has a status of `Reconcile Succeeded`, we should be
able to see a simple-app pod running:

```
$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
simple-app-58f865df65-kmhld   1/1     Running   0          2m
```

If the pod is visible, our package works and is ready to be added to a repository and consumed by
end users.

### Creating a Package Repository

Currently, the best way to create a repository is to use an imgpkg bundle. For the purpose
of this walkthrough, we will show the commands required to create a bundle with brief
explanations, but for a deeper dive on bundles, we encourage you check out the
[imgpkg workflow docs](/imgpkg/docs/latest/basic-workflow/#step-1-creating-the-bundle).

The filesystem structure of this bundle should look like this:

```
my-pkg-repo
├── .imgpkg
│   └── images.yml
└── pkgs
    └── simple-app.v1.0.0.yml
```

Lets start by creating the needed directories:

```
$ mkdir -p my-pkg-repo/.imgpkg my-pkg-repo/pkgs
```

Once the directories are created, we can copy our Package CR yaml in to the
bundle's `pkgs` directory:

```
cp simple-app.v1.0.0.yml my-pkg-repo/pkgs
```

After this, we will have to populate the `.imgpkg` dir with the needed metadata
files. Again, more details can be found in the [imgpkg docs](/imgpkg/docs/latest)

```
$ kbld -f my-pkg-repo/pkgs --imgpkg-lock-output my-pkg-repo/.imgpkg/images.yml
```

With the metadata files present, we can push our repo bundle to wherever we plan to
distribute it from:

```
$ imgpkg push -b <distribution repo>:v1.0.0 -f my-pkg-repo
```

Finally, we must create a PackageRepository CR that consumers can install in
their cluster to make our packages available:

```yaml
---
apiVersion: install.package.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: my-pkg-repo.v1.0.0
spec:
  fetch:
    bundle:
      image: <distribution repo>:v1.0.0
```

Thats it! If we publish this PackageRepository CR, users will now be able to
apply it to their cluster and start installing our simple app using familiar package
management workflows. See the next section for more details on how the
consumption workflow looks!

## Package Consumption

This workflow walks through the example contained in
the [`packaging-demo`](https://github.com/vmware-tanzu/carvel-kapp-controller/tree/dev-packaging/examples/packaging-demo).

### Setup

First, some [setup of rbac](security-model.md) is necessary and can be done using:

```
$ kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/examples/rbac/default-ns.yml
```

### Adding the Repo

Now that rbac is setup, we need to make some packages available to the cluster.
To do this, we need a PackageRepository CR:

```yaml
---
apiVersion: install.package.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: basic.test.carvel.dev
spec:
  fetch:
    bundle:
      image: k8slt/kctrl-pkg-repo-bundle:v1.0.0
```

This CR will allow kapp-controller to install any of the packages found within
the imgpkg bundle stored in a docker registry. Save this  PackageRepository to
a file named repo.yml and then apply it to the cluster using kapp:

```
$ kapp deploy -a repo -f repo.yml
```

Once the deploy has finished, we are able to list the packages and see which ones are now available:

```
$ kubectl get packages
NAME                              PUBLIC-NAME            VERSION      AGE
pkg.test.carvel.dev.1.0.0        pkg2.test.carvel.dev   1.0.0        7s
pkg.test.carvel.dev.2.0.0        pkg2.test.carvel.dev   2.0.0        7s
pkg.test.carvel.dev.3.0.0-rc.1   pkg2.test.carvel.dev   3.0.0-rc.1   7s
```

If we want, we can inspect these packages further to get more info about what they're installing:

```
$ kubectl get packages/pkg.test.carvel.dev.1.0.0 -o yaml
```

This will show us the package yaml, which will look something like this:

```yaml
---
apiVersion: package.carvel.dev/v1alpha1
kind: Package
metadata:
  name: pkg.test.carvel.dev.1.0.0
spec:
  publicName: pkg.test.carvel.dev
  version: 1.0.0
  displayName: "Test Package in repo"
  description: "Package used for testing"
  template:
    spec:
      fetch:
      - image:
          url: k8slt/kctrl-example-pkg:v1.0.0
      template:
      - ytt: {}
      deploy:
      - kapp: {}
```

This simple package will fetch the templates stored in the
`k8slt/kctrl-example-pkg:v1.0.0` image, template them using ytt, and finally
deploy them using kapp. Once deployed, there will be a basic greeter app
running in the cluster. Since this is what we want, we can now move on to installation.

### Installing the Package

Once we have the packages available for installation and know which one we'd
like to install, we need to let kapp-controller know we want it installed.
To do this, we will need to create an InstalledPackage CR (and a secret to hold
the values used by simple-app):

```yaml
---
apiVersion: install.package.carvel.dev/v1alpha1
kind: InstalledPackage
metadata:
  name: pkg-demo
  namespace: default
spec:
  serviceAccountName: default-ns-sa
  packageRef:
    publicName: pkg.test.carvel.dev
    version: 1.0.0
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
    #@data/values
    ---
    hello_msg: "hi"
```

This CR references the package we decided to install in the previous section
using the Package CR's publicName and version. The InstalledPackage also
provides the service account which will be used to install the package, as well
as values to include in the templating step in order to customize our installation.

Save the InstalledPackage above to a file named installedpkg.yml and then apply the
InstalledPackage using kapp:

```
$ kapp deploy -a pkg-demo -f installedpkg.yml
```

After the deploy has finished, kapp-controller will have installed the package in the
cluster. We can verify this by checking the pods to see that we have a workload pod
running. The output should show a single running pod which is part of simple-app:

```
$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
simple-app-58f865df65-kmhld   1/1     Running   0          2m
```

If we now use kubectl's port forwarding functionality, we can also see the our
customized hello message as been used in the workload:

```
$ kubectl port-forward service/simple-app  3000:80
```

Then, from another window:

```
$ curl localhost:3000
<h1>Hello hi!</h1>%
```

And we see that our hello_msg value is used.
