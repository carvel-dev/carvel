---
title: "Kubernetes Package Authoring with kctrl"
slug: kubernetes-package-authoring-with-kctrl
date: 2022-08-17
author: Rohit Aggarwal
excerpt: "In this blog, we will see how to leverage kctrl package authoring commands to create a Kubernetes Package."
image: /img/logo.svg
tags: ['carvel', 'package', 'author', 'kctrl']
---

In Carvel, Kubernetes manifests are distributed and consumed via the concept of a package. A package author encapsulates, version, and distributes Kubernetes manifests for package consumers to install on a Kubernetes cluster. A package author can choose to create a package by using a third party manifest, e.g. they can choose to create a package from [cert-manager](https://cert-manager.io/), [Dynatrace](https://www.dynatrace.com/) etc., or they can distribute their own project Kubernetes manifest by creating a package.

Package Authoring is an iterative process and below are the most common steps authors generally go through:
1. Authors know about the Kubernetes manifest they want to package.
2. Add/change the manifest by adding additional overlay/template and test the package. This is the iterative part where authors want to make the changes and test them quickly.
3. Once all the manifest are in place, create the [imgpkg](https://carvel.dev/imgpkg/) bundle (to be mentioned in the package) and the package itself.
4. Add the package to the package repository for distribution.

![Kctrl flow for kubernetes-package-authoring](/images/blog/kubernetes-package-authoring-kctrl-flow.png)

We wanted to introduce a set of CLI commands that guide users in performing most common packaging steps. Below are the new set of commands:

* **kctrl pkg init**: To initialize the Package and create the PackageInstall.

* **kctrl dev**: To deploy PackageInstall CR locally.

* **kctrl pkg release**: Create and upload the imgpkg bundle. Also, create the package to be released.

* **kctrl pkg repo release**: Create the repo bundle so that it can be consumed by package consumers.

In this blog, we will use the above commands to create a `Dynatrace Operator` Package.

## Create package

### Prerequisites

1. Install Carvel tools - [imgpkg](https://carvel.dev/imgpkg/docs/latest/install/), [kapp](https://carvel.dev/kapp/docs/latest/install/), [kbld](https://carvel.dev/kbld/docs/latest/install/), [vendir](https://carvel.dev/vendir/docs/latest/install/), [ytt](https://carvel.dev/ytt/docs/latest/install/).
2. Identify Kubernetes manifest which needs to be packaged. [`Dynatrace Operator`](https://github.com/Dynatrace/dynatrace-operator) releases the [`kubernetes.yaml`](https://github.com/Dynatrace/dynatrace-operator/releases) which can be packaged and be available for distribution.
3. Kubernetes cluster (I will be using [minikube](https://minikube.sigs.k8s.io/docs/)).
4. OCI registry where the package bundle and repository bundles will be pushed (I will be using my [Docker Hub](https://hub.docker.com/) account).

### kctrl pkg init

```bash
$ mkdir dynatrace 
$ cd dynatrace
$ kctrl pkg init
```

This command asks a few basic questions regarding how we want to initialize our package. Lets go through the question together:

![kubernetes package authoring - pkg init basic details](/images/blog/kubernetes-package-authoring-package-basic-details.png)

* In this question, we need to enter the package name which will be a valid DNS subdomain name.

![kubernetes package authoring - pkg init content option](/images/blog/kubernetes-package-authoring-package-content-option.png)

* Here, we need to enter from where to get the Kubernetes manifest which needs to be packages. As mentioned earlier, `dynatrace` releases `kubernetes.yaml` as part of their GitHub release artifacts. Hence, we will select `Option 2`.

![kubernetes package authoring - pkg init dynatrace repository details](/images/blog/kubernetes-package-authoring-dynatrace-repository-details.png)

* In this, few questions are being asked to enter GitHub slug, tag/release version and the manifest file names, etc.

![kubernetes package authoring - pkg init vendir sync](/images/blog/kubernetes-package-authoring-vendir-sync.png)

After entering all the above details, [`vendir`](https://carvel.dev/vendir/) will download all the mentioned manifest locally. `kctrl` will generate two files - package-build.yml and pacakge-resources.yml as output. `Package-resources.yml` file contain Package, PackageInstall and PackageMetadata while `package-build.yml` contains PackageBuild. More information on PackageBuild can be found in this [link](). All the values entered above have been recorded in these files. These files will be used by the `dev` and `pkg release` command subsequently. 

### kctrl dev

To keep the blog short, I am not going to add any additional overlay/manifest. To add them, please follow this [link]().

`kctrl dev` command is used to deploy the package locally. Local means that on the Kubernetes cluster, there is no need to install the `kapp-controller`. But still the package will be deployed in a similar manner as by the `kapp-controller` and see how the Kubernetes resources behave. This will help authors to get a quick feedback on the changes so that users can iterate over them quickly. As the `Package` and `PackageInstall` are present in the package-resources, we will provide `package-resources.yml` file to `kctrl dev`.

If we look into the `PackageInstall`, it mentions `dynatrace-sa` service account (SA). This SA needs to be created for `dev` cmd to run properly. Let's create this SA first. Also, `dynatrace` namespace needs to be created [separately](https://github.com/Dynatrace/dynatrace-operator#installation) as it is not part of the manifest (NOTE: This can be a perfect opportunity to create the additional manifest). 

```bash
$ cat sa.yml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dynatrace-sa
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dynatrace-sa-role
  namespace: default
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dynatrace-sa-role-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: dynatrace-sa
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: dynatrace-sa-role

$ kapp deploy -a sa -f sa.yml -y
Target cluster 'https://192.168.64.105:8443' (nodes: minikube)

Changes

Namespace  Name                       Kind                Age  Op      Op st.  Wait to    Rs  Ri  
(cluster)  dynatrace-sa-role          ClusterRole         -    create  -       reconcile  -   -  
^          dynatrace-sa-role-binding  ClusterRoleBinding  -    create  -       reconcile  -   -  
default    dynatrace-sa               ServiceAccount      -    create  -       reconcile  -   -  

Op:      3 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 3 reconcile, 0 delete, 0 noop

5:02:03PM: ---- applying 2 changes [0/3 done] ----
5:02:03PM: create clusterrole/dynatrace-sa-role (rbac.authorization.k8s.io/v1) cluster
5:02:03PM: create serviceaccount/dynatrace-sa (v1) namespace: default
5:02:03PM: ---- waiting on 2 changes [0/3 done] ----
...
5:02:03PM: ok: reconcile clusterrolebinding/dynatrace-sa-role-binding (rbac.authorization.k8s.io/v1) cluster
5:02:03PM: ---- applying complete [3/3 done] ----
5:02:03PM: ---- waiting complete [3/3 done] ----

Succeeded
$ kubectl create ns dynatrace
namespace/dynatrace created
```

Let's deploy with `kctrl dev`:

As all the manifest are sync'ed locally by `pkg init` command, we have to provide the `--local` flag also.

```bash
$ kctrl dev -f package-resources.yml --local
Target cluster 'https://192.168.64.105:8443' (nodes: minikube)

apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  annotations:
    kctrl.carvel.dev/local-fetch-0: .
  creationTimestamp: null
  name: dynatrace
  namespace: default
spec:
  packageRef:
    refName: dynatrace.carvel.dev
    versionSelection:
      constraints: 0.0.0
  serviceAccountName: dynatrace-sa
status:
  conditions: null
  friendlyDescription: ""
  observedGeneration: 0

Reconciling in-memory app/dynatrace (namespace: default) ...
==> Executing /usr/local/bin/vendir [vendir sync -f - --lock-file /dev/null]
==> Finished executing /usr/local/bin/vendir

==> Executing /usr/local/bin/ytt [ytt -f /var/folders/z1/czwbshk524j7t12s3tqhc_100000gn/T/kapp-controller-fetch-template-deploy3298499314/0/upstream]
==> Finished executing /usr/local/bin/ytt

==> Executing /usr/local/bin/kbld [kbld -f - --build=false]
==> Finished executing /usr/local/bin/kbld

==> Executing /usr/local/bin/kapp [kapp deploy --prev-app dynatrace-ctrl -f - --app-changes-max-to-keep=5 --app dynatrace.app --kubeconfig=/dev/null --yes]

...
	    | 5:11:27PM: ---- applying complete [23/23 done] ----
	    | 5:11:27PM: ---- waiting complete [23/23 done] ----
	    | Succeeded
5:11:27PM: Deploy succeeded 

Succeeded

$ kubectl get pods -n dynatrace
NAME                                  READY   STATUS    RESTARTS   AGE
dynatrace-operator-775fcdb79f-f79pj   1/1     Running   0          4m43s
dynatrace-webhook-6df6fc6f6c-4qbg7    1/1     Running   0          4m43s
dynatrace-webhook-6df6fc6f6c-7dqkz    1/1     Running   0          4m43s
```

As we can see that `dynatrace-operator` pod is up, it means the package is behaving as expected. Now, we will use `kctrl pkg release` to create the package which will be released.

### kctrl pkg release

```bash
$ kctrl pkg release -v 1.0.0
```

This command will create an imgpkg bundle, upload it to the OCI registry and create `package.yml` and `metadata.yml` which can be released for consumption eventually. In this command, it will ask only one question about where to push our imgpkg bundle. Also, we are versioning our package with `-v` flag.

![kubernetes package authoring - pkg release basic details](/images/blog/kubernetes-package-authoring-package-release.png)

While entering the registry URL, ensure to change the value from `docker.io/rohitagg2020/dynatrace-bundle` to `docker.io/<YOUR_DOCKERHUB_ACCOUNT>/dynatrace-bundle`. Alternatively, you can enter other valid OCI registry URL.

Now, we have created our Package and PackageMetadata. 

Let's see how the Package and PackageMetadata files look like:

```bash
$ cat carvel-artifacts/packages/dynatrace.carvel.dev/package.yml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  creationTimestamp: null
  name: dynatrace.carvel.dev.1.0.0
spec:
  refName: dynatrace.carvel.dev
  releasedAt: "2022-08-15T11:54:50Z"
  template:
    spec:
      deploy:
      - kapp: {}
      fetch:
      - imgpkgBundle:
          image: index.docker.io/rohitagg2020/dynatrace-bundle@sha256:d3fd67881ccba75134061451348130577ad0b2034d0a65b44b965b56e7d1c939
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
  version: 1.0.0

$ cat carvel-artifacts/packages/dynatrace.carvel.dev/metadata.yml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  creationTimestamp: null
  name: dynatrace.carvel.dev
spec:
  displayName: dynatrace
  longDescription: dynatrace.carvel.dev
  shortDescription: dynatrace.carvel.dev
```

Next step is to add it to package repository. 

### kctrl pkg repo release

`kctrl` can be used to release packages grouped together as a `PackageRepository`. Let’s bundle the `dynatrace` package created above into the PackageRepository.

Let's create a folder for our repository.
```bash
$ cd ../
$ mkdir pkg-repo && cd pkg-repo
```

`kctrl` will create a repo bundle from all the packages and metadata present in the `packages` folder. 
We will copy the `package.yml` and `metadata.yml` created above into the `packages` folder. We will follow the bundle format as mentioned [here](). Alternatively, while running `pkg release`, `--repo-output` flag can be used to copy the `package.yml` and `metadata.yml` in the prescribed PackageRepository bundle format at a specified location.

```bash
$ mkdir -p packages/dynatrace.carvel.dev
$ cp ../dynatrace/carvel-artifacts/packages/dynatrace.carvel.dev/package.yml packages/dynatrace.carvel.dev/1.0.0.yml
$ cp ../dynatrace/carvel-artifacts/packages/dynatrace.carvel.dev/metadata.yml packages/dynatrace.carvel.dev/
$ tree
.
└── packages
    └── dynatrace.carvel.dev
        ├── 1.0.0.yml
        └── metadata.yml
```

Now, we will run `kctrl pkg repo release` to create and release the repository bundle. This repository bundle can be distributed to the the package consumer.

```bash
$ kctrl pkg repo release -v 1.0.0
```

In this command, it will ask for package repository name and only one question about where to push our repository bundle. Also, we are versioning our package repository with `-v` flag.

![kubernetes package authoring - pkg repo release](/images/blog/kubernetes-package-authoring-package-repo-release.png)

While entering the registry URL, ensure to change the value from `docker.io/rohitagg2020/demo-repo-bundle` to `docker.io/<YOUR_DOCKERHUB_ACCOUNT>/demo-repo-bundle`. Alternatively, you can enter other valid OCI registry URL.

We have seen how to create package with the help of new set of commands. More information on package authoring can be found [here]().

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
