---
title: "Simplifying Package Authoring"
slug: simplifying-package-authoring
date: 2022-08-16
author: Rohit Aggarwal
excerpt: "Simplifying Package Authoring with kctrl"
image: /img/logo.svg
tags: ['carvel', 'package', 'author', 'kctrl', 'create']
---

In Carvel, Kubernetes(K8s) manifest are distributed and consumed via the concept of Package. A package Author encapsulates, version, and distribute K8s manifest for others to install on a Kubernetes cluster. A package author can choose to create a package by using third party manifest e.g. they can choose to create a package from cert-manager or they want to distribute their own project configurations by creating a Package.

Package Authoring is an iterative process and below are the steps authors go through:
1. Authors know about the K8s manifest they want to package.
2. Add/change the manifest by adding ytt overlay/template and test the package. This is the iterative part where authors want to make the changes and test them quickly.
3. Once all the manifest are in place, create the imgpkg bundle(to be mentioned in the package) and package.
4. Add the package to the package repository for distribution.

Today, package authors are supposed to know all the Carvel tools as they are being used in the package authoring journey. Learning the Carvel tools before package authoring is a bit of learning curve. As part of simplifying package authoring, we wanted to reduce this learning curve so that authors can focus on package authoring. As part of this, few commands have been added to the `kctrl` cli.

![Kctrl flow for simplifying-package-authoring](/images/blog/simplifying-package-authoring-kctrl-flow.png)


**kctrl pkg init**: To initialize the App/Package and create the App/PackageInstall.

**kctrl dev**: To deploy App/PackageInstall CR locally.

**kctrl pkg release**: Create, upload the imgpkg bundle and Package to be released.

**kctrl pkg repo release**: Create the repo bundle so that it can be consumed by Package consumers.

Lets, try to create a `Dynatrace` package by using the above commands.

## Create a package

### Prerequisites

1. Install Carvel tools using [`install.sh`](https://carvel.dev/install.sh) script.
2. [`Dynatrace`](https://github.com/Dynatrace/dynatrace-operator) releases the [`kubernetes.yaml`](https://github.com/Dynatrace/dynatrace-operator/releases) which can be packaged and be available for distribution.
3. K8s cluster (I will be using minikube).
4. OCI registry where the package bundle and repository bundles will be pushed (I will be using my DockerHub account).

### kctrl pkg init - Initialize the package

```bash
$ mkdir dynatrace 
$ cd dynatrace
$ kctrl pkg init
```

This command asks a few basic questions regarding how we want to initialize our package. Lets go through the question together:

![Simplifying package authoring - pkg init basic details](/images/blog/simplifying-package-authoring-package-basic-details.png)

* In this question, we need to enter the package name which will be a valid DNS subdomain name.

![Simplifying package authoring - pkg init content option](/images/blog/simplifying-package-authoring-package-content-option.png)

* Here, we need to enter from where to get the K8s manifest which needs to be packages. As mentioned earlier, `dynatrace` releases `kubernetes.yaml` as part of their github release artifacts. Hence, we will select `Option 2`.

![Simplifying package authoring - pkg init dynatrace repository details](/images/blog/simplifying-package-authoring-dynatrace-repository-details.png)

* In this few questions are being asked to enter github slug, tag/release version and the manifest file names etc.

![Simplifying package authoring - pkg init vendir sync](/images/blog/simplifying-package-authoring-vendir-sync.png)

* After entering all the above details, tool will download all the mentioned manifest locally and create two files - package-build.yml and pacakge-resources.yml. `Package-resources.yml` file contain Package, PackageInstall and PackageMetadata while `package-build.yml` contains PackageBuild. More information on PackageBuild can be found in this [link](). All the values entered above have been recorded in these files. These files will be used by the `dev` and `pkg release` command subsequently. 

### kctrl dev - Test the package locally

To keep the blog short, I am not going to add any additional overlay/manifest. To add them, please follow this [link]().

`kctrl dev` command is used to deploy the package locally. Local means that on the K8s cluster, there is no need to install the `kapp-controller`. But still the package can be deployed and see how the K8s resources behave as if it is being deployed on the cluster with `kapp-controller` installed. This helps you to get a quick feedback on the changes so that users can iterate quickly. As the `Package` and `PackageInstall` are present in the package-resources, we will provide `package-resources.yml` file to `kctrl dev`.

If we look into the `PackageInstall`, it mention `dynatrace-sa` service account(SA). This SA needs to be created for `dev` cmd to run properly. Lets create this SA first. Also, `dynatrace` namespace needs to be created [separately](https://github.com/Dynatrace/dynatrace-operator#installation) as it is not part of the manifest (NOTE: This can be a perfect opportunity to create the additional manifest). 

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

### kctrl pkg release - Create package to release

```bash
$ kctrl pkg release -v 1.0.0
```

This command will create an imgpkg bundle, upload it to the OCI registry and create `package.yml` and `metadata.yml` which can be released for consumption eventually. In this command, it will ask only 1 question about where to push our imgpkg bundle. Also, we are versioning our package with `-v` flag.

![Simplifying package authoring - pkg release basic details](/images/blog/simplifying-package-authoring-package-release.png)

While entering the registry URL, ensure to change the value from `docker.io/rohitagg2020/dynatrace-bundle` to `docker.io/<YOUR_DOCKERHUB_ACCOUNT>/dynatrace-bundle`. Alternatively, you can enter other valid OCI registry URL.

Now, we have created our package and packageMetadata. Next step is to add it to package repository. 

### kctrl pkg repo release - Create repository bundle for consumption

`kctrl` can be used to release packages grouped together as a `PackageRepository`. Let’s bundle the `dynatrace` package created above into the PackageRepository.

Let's create a folder for our repository.
```bash
cd ../
mkdir pkg-repo && cd pkg-repo
mkdir packages && cd packages
```

`kctrl` will create a repo bundle from all the packages and metadata present in the `packages` folder. 
Now, we will copy the `package.yml` and `metadata.yml` created above into the `packages` folder. We will follow the bundle format as mentioned [here](). Alternatively, while running `pkg release`, `--repo-output` flag can be used to copy the `package.yml` and `metadata.yml` in the prescribed PackageRepository bundle format at a specified location.
