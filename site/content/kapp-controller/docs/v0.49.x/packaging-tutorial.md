---
aliases: [/kapp-controller/docs/latest/packaging-tutorial]
title: "Tutorial: Create and Install a Package"
---

## Getting Started
Note the below steps are from a former katacoda tutorial (RIP katacoda) so your environment may differ slightly.

Available kubernetes playground options include [killercoda](https://killercoda.com/playgrounds),
or local installations such as [minikube](https://minikube.sigs.k8s.io/docs/) or [kind](https://kind.sigs.k8s.io/).

## Installing kapp-controller dependencies

We'll be using [Carvel](https://carvel.dev/) tools throughout this tutorial, so first we'll install
[ytt](https://carvel.dev/ytt/), [kbld](https://carvel.dev/kbld/),
[kapp](https://carvel.dev/kapp/), [imgpkg](https://carvel.dev/imgpkg/), and [vendir](https://carvel.dev/vendir/).

Install the tools with the scripts below:

```bash
wget https://raw.githubusercontent.com/carvel-dev/kapp-controller/83fffcfe99a65031b4170813acf94f8d5058b346/hack/dependencies.yml
wget https://raw.githubusercontent.com/carvel-dev/kapp-controller/83fffcfe99a65031b4170813acf94f8d5058b346/hack/install-deps.sh
chmod a+x ./install-deps.sh
./install-deps.sh
```


## Optional: explore kapp

Before we install kapp-controller with [kapp](https://carvel.dev/kapp/), you may be interested in seeing
a different example of how kapp works.

You can skip this step if you want to get straight to kapp-controller.

First pull down the yaml for this example:

```bash
wget https://raw.githubusercontent.com/carvel-dev/kapp/5886f388900ce66e4318220025ca77d16bfaa488/examples/jobs/cron-job.yml
```

Then deploy a CronJob to the Kubernetes cluster in this environment:

```bash
kapp deploy -a hellocron -f cron-job.yml -y
```

Now take a look at the Kubernetes resources being managed by kapp:

```bash
kapp ls
```

```bash
kapp inspect -a hellocron --tree
```

We scheduled our CronJob to output a hello message every minute, so if you're
patient you'll see new messages appended to the logs:

```bash
kapp logs -f -a hellocron
```

When you're done watching the logs you can use control-c (`^C`) to quit.

Because this was an optional interlude, we can use kapp to uninstall the CronJob before proceeding:
```bash
kapp delete -a hellocron -y
```
## I believe I was promised kapp-controller?

Use kapp to install kapp-controller (reconciliation may take a moment, which you
could use to read about [kubernetes controller reconciliation loops](https://kubernetes.io/docs/concepts/architecture/controller/)):

```bash
kapp deploy -a kc -f https://github.com/carvel-dev/kapp-controller/releases/download/v0.32.0/release.yml -y
```

Gaze upon the splendor! 

```bash
kubectl get all -n kapp-controller
```

The kapp deployment is managing a replicaset which owns a service and a pod. The
pod is running kapp-controller, which is a kubernetes controller
running its own reconciliation loop.

kapp-controller introduces new Custom Resource (CR) types we'll use throughout this
tutorial, including PackageRepositories and PackageInstalls.

```bash
kubectl api-resources --api-group packaging.carvel.dev
```

You can see other kapp-controller CRs in other groups:

```bash
kubectl api-resources --api-group data.packaging.carvel.dev
```

```bash
kubectl api-resources --api-group kappctrl.k14s.io
```
## Creating a Package: Templating our config

We will be using [ytt](https://carvel.dev/ytt/) templates that describe a simple Kubernetes Deployment and Service.
These templates will install a simple greeter app with a templated hello message.

Create a config.yml:

```bash
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

and put our schema into values.yml:

```bash
cat > values.yml <<- EOF
#@data/values-schema
---
#@schema/desc "Port number for the service."
svc_port: 80
#@schema/desc "Target port for the application."
app_port: 80
#@schema/desc "Name used in hello message from app when app is pinged."
hello_msg: stranger
EOF
```

## Creating a Package: Structuring our contents
We'll create an [imgpkg bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle)
that contains the package contents: the configuration (config.yml and values.yml from the previous step) and a reference to the greeter app image (docker.io/dkalinin/k8s-simple-app@sha256:...).

The [package bundle format](https://carvel.dev/kapp-controller/docs/latest/packaging-artifact-formats/#package-contents-bundle) describes the purpose of each directory 
used in this section of the tutorial as well as general recommendations.

Let's create a directory with our configuration files:
```bash
mkdir -p package-contents/config/
cp config.yml package-contents/config/config.yml
cp values.yml package-contents/config/values.yml
```

Once we have the configuration figured out, let’s use kbld to record which container images are used:
```bash
mkdir -p package-contents/.imgpkg
kbld -f package-contents/config/ --imgpkg-lock-output package-contents/.imgpkg/images.yml
```

For more on using kbld to populate the .imgpkg directory with an ImagesLock, and why it is useful, see the [imgpkg docs on the subject](https://carvel.dev/imgpkg/docs/latest/resources/#imageslock-configuration).

Once these files have been added, our package contents bundle is ready to be pushed!

For the purpose of this tutorial, we will run an unsecured local docker
registry. In the real world please be safe and use appropriate security
measures.

```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

From the terminal we can access this registry as `localhost:5000` but within the
cluster we'll need the IP Address. To emphasize that you would
normally use a repo host such as dockerhub or harbor we will store the IP
address in a variable:

```bash
export REPO_HOST="`ifconfig | grep -A1 docker | grep inet | cut -f10 -d' '`:5000"
```

Now we can publish our bundle to our registry:

```bash
imgpkg push -b ${REPO_HOST}/packages/simple-app:1.0.0 -f package-contents/
```


You can verify that we pushed something called `packages/simple-app` by checking the Docker registry catalog:

```bash
curl ${REPO_HOST}/v2/_catalog
```

## Creating the Custom Resources

To finish creating a package, we need to create two CRs. The first CR is the PackageMetadata CR, which will contain high level information and descriptions about our package.

When creating this CR, the api will validate that the PackageMetadata’s name is a fully qualified name: It must have at least three segments separated by `.` and cannot have a trailing `.`.

We'll make a conformant `metadata.yml` file:

```bash
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

In order to create the Package CR with our OpenAPI Schema, we will export from
our ytt schema:

```bash
ytt -f package-contents/config/values.yml --data-values-schema-inspect -o openapi-v3 > schema-openapi.yml
```

That command creates an OpenAPI document, from which we really only need the
`components.schema` section for our Package CR.


```bash
cat > package-template.yml << EOF
#@ load("@ytt:data", "data")  # for reading data values (generated via ytt's data-values-schema-inspect mode).
#@ load("@ytt:yaml", "yaml")  # for dynamically decoding the output of ytt's data-values-schema-inspect
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: #@ "simple-app.corp.com." + data.values.version
spec:
  refName: simple-app.corp.com
  version: #@ data.values.version
  releaseNotes: |
        Initial release of the simple app package
  valuesSchema:
    openAPIv3: #@ yaml.decode(data.values.openapi)["components"]["schemas"]["dataValues"]
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: #@ "${REPO_HOST}/packages/simple-app:" + data.values.version
      template:
      - ytt:
          paths:
          - "config/"
      - kbld:
          paths:
          - ".imgpkg/images.yml"
          - "-"
      deploy:
      - kapp: {}
EOF
```

This Package contains some metadata fields specific to the version, such as releaseNotes and a valuesSchema. The valuesSchema shows what configurable properties exist for the version. This will help when users want to install this package and want to know what can be configured.

The other main component of this CR is the template section.
This section informs kapp-controller of the actions required to install the packaged software, so take a look at the [app-spec](https://carvel.dev/kapp-controller/docs/latest/app-spec/) section to learn more about each of the template sections. For this example, we have chosen a basic setup that will fetch the imgpkg bundle we created in the previous section, run the templates stored inside through ytt, apply kbld transformations, and then deploy the resulting manifests with kapp.

There will also be validations run on the Package CR, so ensure that spec.refName and spec.version are not empty and that metadata.name is `<spec.refName>.<spec.version>`.
These validations are done to encourage a naming scheme that keeps package version names unique.
## Creating a Package Repository

A [package repository](https://carvel.dev/kapp-controller/docs/latest/packaging/#package-repository)
is a collection of packages (more specifically a collection of Package and PackageMetadata CRs).
Our recommended way to make a package repository is via an [imgpkg bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle).

The [PackageRepository bundle format](https://carvel.dev/kapp-controller/docs/latest/packaging-artifact-formats/#package-repository-bundle) describes purpose of each directory and general recommendations.

Lets start by creating the needed directories:

```bash
mkdir -p my-pkg-repo/.imgpkg my-pkg-repo/packages/simple-app.corp.com
```

we can copy our CR YAMLs from the previous step in to the proper packages
subdirectory. Note that we are declaring the version and the openAPI schema file
to ytt.

```bash
ytt -f package-template.yml  --data-value-file openapi=schema-openapi.yml -v version="1.0.0" > my-pkg-repo/packages/simple-app.corp.com/1.0.0.yml
cp metadata.yml my-pkg-repo/packages/simple-app.corp.com
```

Next, let’s use kbld to record which package bundles are used:

```bash
kbld -f my-pkg-repo/packages/ --imgpkg-lock-output my-pkg-repo/.imgpkg/images.yml
```

With the bundle metadata files present, we can push our bundle to whatever OCI
registry we plan to distribute it from, which for this tutorial will just be our
same REPO_HOST.

```bash
imgpkg push -b ${REPO_HOST}/packages/my-pkg-repo:1.0.0 -f my-pkg-repo
```

The package repository is pushed!

You can verify by checking the Docker registry catalog:

```bash
curl ${REPO_HOST}/v2/_catalog
```

In the next steps we'll act as the package consumer, showing an example of adding and using a PackageRepository with kapp-controller.

## Adding a PackageRepository

kapp-controller needs to know which packages are available to install.
One way to let it know about available packages is by creating a package repository.
To do this, we need a PackageRepository CR:

```bash
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
[demo video](https://www.youtube.com/watch?v=PmwkicgEKQE) and [website](https://carvel.dev/kapp-controller/docs/latest/private-registry-auth) for more typical usage with an external repository.)

This PackageRepository CR will allow kapp-controller to install any of the
packages found within the `${REPO_HOST}/packages/my-pkg-repo:1.0.0` imgpkg bundle, which we
stored in our docker OCI registry previously.

We can use kapp to apply it to the cluster:
```bash
kapp deploy -a repo -f repo.yml -y
```

Check for the success of reconciliation to see the repository become available:
```bash
watch kubectl get packagerepository
```

Once the simple-package-repository has a "**Reconcile succeeded**" description,
we're ready to continue! You can exit the watch by hitting control-c or
clicking: `^C`

Once the deploy has finished, we are able to list the package metadatas to see, at a high level, which packages are now available within our namespace:
```bash
kubectl get packagemetadatas
```

If there are numerous available packages, each with many versions, this list can become a bit unwieldy, so we can also list the packages with a particular name using the --field-selector option on kubectl get.
```bash
kubectl get packages --field-selector spec.refName=simple-app.corp.com
```

From here, if we are interested, we can further inspect each version to discover
information such as release notes, installation steps, licenses, etc. For
example:
```bash
kubectl get package simple-app.corp.com.1.0.0 -o yaml
```


## Installing a Package

Once we have the packages available for installation (as seen via `kubectl get packages`), 
we need to let kapp-controller know which package we want to install.
To do this, we will need to create a PackageInstall CR (and a secret to hold the values used by our package):

```bash
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
    hello_msg: "to all my internet friends"
EOF
```


This CR references the Package we created in the previous sections using the package’s `refName` and `version` fields (see yaml from step 7).
Do note, the `versionSelection` property has a constraints subproperty to give more control over which versions are chosen for installation.
More information on PackageInstall versioning can be found [here](https://carvel.dev/kapp-controller/docs/latest/packaging/#versioning-packageinstalls).

This yaml snippet also contains a Kubernetes secret, which is referenced by the PackageInstall. This secret is used to provide customized values to the package installation’s templating steps. Consumers can discover more details on the configurable properties of a package by inspecting the Package CR’s valuesSchema.

Finally, to install the above package, we will also need to create `default-ns-sa` service account (refer to [Security model](https://carvel.dev/kapp-controller/docs/latest/security-model/)
for explanation of how service accounts are used) that give kapp-controller privileges to create resources in the default namespace:
```bash
kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/carvel-dev/kapp-controller/develop/examples/rbac/default-ns.yml -y
```

Apply the PackageInstall using kapp:
```bash
kapp deploy -a pkg-demo -f pkginstall.yml -y
```

After the deploy has finished, kapp-controller will have installed the package in the cluster. We can verify this by checking the pods to see that we have a workload pod running. The output should show a single running pod which is part of simple-app:
```bash
kubectl get pods
```

Once the pod is ready, you can use kubectl’s port forwarding to verify the customized hello message has been used in the workload:
```bash
kubectl port-forward service/simple-app 3000:80 &
```

Now if we make a request against our service, we can see that our `hello_msg`
values is being used:
```bash
curl localhost:3000
```
## Congratulations!

Visit [carvel.dev](https://carvel.dev/) to learn more about Carvel tools.

See the full docs for [Package Management with kapp-controller](https://carvel.dev/kapp-controller/docs/latest/packaging/)
