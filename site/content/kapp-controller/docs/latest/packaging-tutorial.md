---
title: Package Management Tutorial
---

## Get Started With Katacoda
Make a katacoda account and take our interactive tutorial [here](https://katacoda.com/carvel/scenarios/kapp-controller-package-management)
## Or Follow Our Tutorial Below
You can spin up your favorite [playground](https://www.katacoda.com/courses/kubernetes/playground) and follow the steps below.
Note the below steps are from the linked katacoda tutorial so your environment may differ slightly.

## Installing kapp-controller dependencies

We'll be using [Carvel](https://carvel.dev/) tools throughout this tutorial, so first we'll install 
[ytt](https://carvel.dev/ytt/), [kbld](https://carvel.dev/kbld/),
[kapp](https://carvel.dev/kapp/), [imgpkg](https://carvel.dev/imgpkg/), and [vendir](https://carvel.dev/vendir/).

Install the whole tool suite with the script below:

`wget -O- https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/fc5458fe2102d67e85116c26534a35e265b28125/hack/install-deps.sh | bash`


## Optional: explore kapp

Before we install kapp-controller with [kapp](https://carvel.dev/kapp/), you may be interested in seeing
a different example of how kapp works.

You can skip this step if you want to get straight to kapp-controller.

### Using kapp to install a cronjob

First clone the GitHub repository for examples:

`git clone https://github.com/vmware-tanzu/carvel-kapp`

Then deploy a CronJob to the Kubernetes cluster in this environment:

`kapp deploy -a hellocron -f carvel-kapp/examples/jobs/cron-job.yml -y`

Now take a look at the Kubernetes resources being managed by kapp:

`kapp ls`

`kapp inspect -a hellocron --tree`

We scheduled our CronJob to output a hello message every minute, so if you're
patient you'll see new messages appended to the logs:

`kapp logs -f -a hellocron`

When you're done watching the logs you can use control-c (`^C`) to quit.

Because this was an optional interlude, we can use kapp to uninstall the CronJob before proceeding:
`kapp delete -a hellocron -y`
## I believe I was promised kapp-controller?

Use kapp to install kapp-controller (reconciliation may take a moment, which you
could use to read about [kubernetes controller reconciliation loops](https://kubernetes.io/docs/concepts/architecture/controller/)):

`kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.21.0/release.yml -y`

Gaze upon the splendor! 

`kubectl get all -n kapp-controller`

The kapp deployment is managing a replicaset which owns a service and a pod. The
pod is running kapp-controller, which is a kubernetes controller
running its own reconciliation loop.

kapp-controller introduces new Custom Resource (CR) types we'll use throughout this
tutorial, including PackageRepositories and PackageInstalls.

`kubectl api-resources --api-group packaging.carvel.dev`

You can see other kapp-controller CRs in other groups:

`kubectl api-resources --api-group data.packaging.carvel.dev`

`kubectl api-resources --api-group kappctrl.k14s.io`
## Creating a Package: Templating our config

We will be using [ytt](https://carvel.dev/ytt/) templates that describe a simple Kubernetes Deployment and Service.
These templates will install a simple greeter app with a templated hello message.

Create a config.yml:

```
cat > config.yml << EOF
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
EOF
```

and a values.yml:

```
cat > values.yml <<- EOF
#@data/values
---
svc_port: 80
app_port: 80
hello_msg: stranger
EOF
```


## Creating a Package: Structuring our contents
We'll create an [imgpkg bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle)
that contains the package contents: the configuration (config.yml and values.yml from the previous step) and a reference to the greeter app image (docker.io/dkalinin/k8s-simple-app@sha256:...).

The [package bundle format](https://carvel.dev/kapp-controller/docs/latest/packaging/#package-bundle-format) describes the purpose of each directory 
used in this section of the tutorial as well as general recommendations.

Let's create a directory with our configuration files:
```
mkdir -p package-contents/config/
cp config.yml package-contents/config/config.yml
cp values.yml package-contents/config/values.yml
```

Once we have the configuration figured out, let’s use kbld to record which container images are used:
```
mkdir -p package-contents/.imgpkg
kbld -f package-contents/config/ --imgpkg-lock-output package-contents/.imgpkg/images.yml
```

For more on using kbld to populate the .imgpkg directory with an ImagesLock, and why it is useful, see the [imgpkg docs on the subject](https://carvel.dev/imgpkg/docs/latest/resources/#imageslock-configuration).

Once these files have been added, our package contents bundle is ready to be pushed!

For the purpose of this tutorial, we will run an unsecured local docker
registry. In the real world please be safe and use appropriate security
measures.

`docker run -d -p 5000:5000 --restart=always --name registry registry:2`

From the terminal we can access this registry as `localhost:5000` but within the
cluster we'll need the IP Address. To emphasize that you would
normally use a repo host such as dockerhub or harbor we will store the IP
address in a variable:

```
export REPO_HOST="`ifconfig | grep -A1 docker | grep inet | cut -f10 -d' '`:5000"
```

Now we can publish our bundle to our registry:

`imgpkg push -b ${REPO_HOST}/packages/simple-app:1.0.0 -f package-contents/`


You can verify that we pushed something called `packages/simple-app` by checking the Docker registry catalog:

`curl ${REPO_HOST}/v2/_catalog`

## Creating the Custom Resources

To finish creating a package, we need to create two CRs. The first CR is the PackageMetadata CR, which will contain high level information and descriptions about our package.

When creating this CR, the api will validate that the PackageMetadata’s name is a fully qualified name: It must have at least three segments separated by `.` and cannot have a trailing `.`.

We'll make a conformant `metadata.yml` file:

```
cat > metadata.yml << EOF
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  # This will be the name of our package
  name: simple-app.corp.com
spec:
  displayName: "Simple App"
  longDescription: "Simple app consisting of a k8s deployment and service"
  shortDescription: "Simple app for demoing"
  categories:
  - demo
EOF
```

Now we need to create a Package CR.
This CR contains versioned instructions and metadata used to install packaged software that fits the description provided in the PackageMetadata CR we just saved in `metadata.yml`.

```
cat > 1.0.0.yml << EOF
---
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
          image: ${REPO_HOST}/packages/simple-app:1.0.0
      template:
      - ytt:
          paths:
          - "config/"
      - kbld:
          paths:
          - "-"
          - ".imgpkg/images.yml"
      deploy:
      - kapp: {}
EOF
```

This Package contains some metadata fields specific to the verison, such as releaseNotes and a valuesSchema. The valuesSchema shows what configurable properties exist for the version. This will help when users want to install this package and want to know what can be configured.

The other main component of this CR is the template section.
This section informs kapp-controller of the actions required to install the packaged software, so take a look at the [app-spec](https://carvel.dev/kapp-controller/docs/latest/app-spec/) section to learn more about each of the template sections. For this example, we have chosen a basic setup that will fetch the imgpkg bundle we created in the previous section, run the templates stored inside through ytt, apply kbld transformations, and then deploy the resulting manifests with kapp.

There will also be validations run on the Package CR, so ensure that spec.refName and spec.version are not empty and that metadata.name is `<spec.refName>.<spec.version>`.
These validations are done to encourage a naming scheme that keeps package version names unique.
## Creating a Package Repository

A [package repository bundle](https://carvel.dev/kapp-controller/docs/latest/packaging/#package-repository-bundle-format)
is a collection of packages (more specifically a collection of Package and PackageMetadata CRs).
Currently, our recommended way to make a package repository is via an [imgpkg bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle).

The [PackageRepository bundle format](https://carvel.dev/kapp-controller/docs/latest/packaging/#package-repository-bundle-format) describes purpose of each directory and general recommendations.

Lets start by creating the needed directories:

`mkdir -p my-pkg-repo/.imgpkg my-pkg-repo/packages/simple-app.corp.com`

we can copy our CR YAMLs from the previous step in to the proper packages
subdirectory:

```
cp 1.0.0.yml my-pkg-repo/packages/simple-app.corp.com
cp metadata.yml my-pkg-repo/packages/simple-app.corp.com
```

Next, let’s use kbld to record which package bundles are used:

`kbld -f my-pkg-repo/packages/ --imgpkg-lock-output my-pkg-repo/.imgpkg/images.yml`

With the bundle metadata files present, we can push our bundle to whatever OCI
registry we plan to distribute it from, which for this tutorial will just be our
same REPO_HOST.

`imgpkg push -b ${REPO_HOST}/packages/my-pkg-repo:1.0.0 -f my-pkg-repo`

The package repository is pushed!

You can verify by checking the Docker registry catalog:

`curl ${REPO_HOST}/v2/_catalog`

In the next steps we'll act as the package consumer, showing an example of adding and using a PackageRepository with kapp-controller.

## Adding a PackageRepository

kapp-controller needs to know which packages are available to install.
One way to let it know about available packages is by creating a package repository.
To do this, we need a PackageRepository CR:

```
cat > repo.yml << EOF
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: simple-package-repository
spec:
  fetch:
    imgpkgBundle:
      image: ${REPO_HOST}/packages/my-pkg-repo:1.0.0
EOF
```

(See our
[demo video](https://www.youtube.com/watch?v=PmwkicgEKQE) and [website](https://carvel.dev/kapp-controller/docs/latest/package-consumption/#adding-package-repository) examples for more typical
use-case against an external repository.)

This PackageRepository CR will allow kapp-controller to install any of the
packages found within the `${REPO_HOST}/packages/my-pkg-repo:1.0.0` imgpkg bundle, which we
stored in our docker OCI registry previously.

We can use kapp to apply it to the cluster:
`kapp deploy -a repo -f repo.yml -y`

Check for the success of reconciliation to see the repository become available:
`watch kubectl get packagerepository`

Once the simple-package-repository has a "**Reconcile succeeded**" description,
we're ready to continue! You can exit the watch by hitting control-c or
clicking: `^C`

Once the deploy has finished, we are able to list the package metadatas to see, at a high level, which packages are now available within our namespace:
`kubectl get packagemetadatas`

If there are numerous available packages, each with many versions, this list can become a bit unwieldy, so we can also list the packages with a particular name using the --field-selector option on kubectl get.
`kubectl get packages --field-selector spec.refName=simple-app.corp.com`

From here, if we are interested, we can further inspect each version to discover
information such as release notes, installation steps, licenses, etc. For
example:
`kubectl get package simple-app.corp.com.1.0.0 -o yaml`


## Installing a Package

Once we have the packages available for installation (as seen via `kubectl get packages`), 
we need to let kapp-controller know which package we want to install.
To do this, we will need to create a PackageInstall CR (and a secret to hold the values used by our package):

```
cat > pkginstall.yml << EOF
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
    hello_msg: "to all my katacoda friends"
EOF
```


This CR references the Package we created in the previous sections using the package’s `refName` and `version` fields (see yaml from step 7).
Do note, the `versionSelection` property has a constraints subproperty to give more control over which versions are chosen for installation.
More information on PackageInstall versioning can be found [here](https://carvel.dev/kapp-controller/docs/latest/packaging/#versioning-packageinstalls).

This yaml snippet also contains a Kubernetes secret, which is referenced by the PackageInstall. This secret is used to provide customized values to the package installation’s templating steps. Consumers can discover more details on the configurable properties of a package by inspecting the Package CR’s valuesSchema.

Finally, to install the above package, we will also need to create `default-ns-sa` service account (refer to [Security model](https://carvel.dev/kapp-controller/docs/latest/security-model/)
for explanation of how service accounts are used) that give kapp-controller privileges to create resources in the default namespace:
`kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/examples/rbac/default-ns.yml -y`

Apply the PackageInstall using kapp:
`kapp deploy -a pkg-demo -f pkginstall.yml -y`

After the deploy has finished, kapp-controller will have installed the package in the cluster. We can verify this by checking the pods to see that we have a workload pod running. The output should show a single running pod which is part of simple-app:
`kubectl get pods`

Once the pod is ready, you can use kubectl’s port forwarding to verify the customized hello message has been used in the workload:
`kubectl port-forward service/simple-app 3000:80 &`

Now if we make a request against our service, we can see that our `hello_msg`
values is being used:
`curl localhost:3000`
## Congratulations!

Visit [carvel.dev](https://carvel.dev/) to learn more about Carvel tools.

See the full docs for kapp-controller's Package [authoring](https://carvel.dev/kapp-controller/docs/latest/package-authoring/) and
Package
[consumption](https://carvel.dev/kapp-controller/docs/latest/package-consumption/).
