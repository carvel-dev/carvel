---
title: "Continuous delivery using a Carvel ytt Argo CD plugin"
slug: argocd-carvel-plugin
date: 2022-02-23
author: Cari Lynn
excerpt: "Use your favorite Carvel templating tool in your GitOps continuous delivery using the Carvel ytt Argo CD plugin."
image: /img/logo.svg
tags: ['ytt', 'argocd', 'gitops']
---

Argo CD is a declarative, GitOps, continuous delivery tool for Kubernetes. It's design embraces GitOps philosophy of using Git as a single source of truth for the desired state of the system. In this example we're storing desired application state in ytt templates, and extending Argo CD to template and deploy them.

At a high level a deployment using Argo CD starts with a configuration change. A commit with a change is made to the application repository, causing the Argo CD controller to notice the desired state has changed. It processes the manifests from the application repository through built-in templating engines like Helm, or what we will be using: a Carvel ytt Argo CD plugin. Finally, it applies the manifests to the cluster.

## You will need these to start your journey:
- [argocd cli](https://argo-cd.readthedocs.io/en/stable/getting_started/#2-download-argo-cd-cli)
- Kubernetes cluster (I'm using [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager))
- [kapp](https://github.com/vmware-tanzu/carvel-kapp) or [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [ytt](https://github.com/vmware-tanzu/carvel-ytt)

## Create the Carvel Plugin
To make the Carvel plugin available to the application we want to deploy, we need to make a couple patches to the Argo CD cluster configuration. We can do this with ytt overlays!

### Adding carvel-ytt binary to `argocd-repo-server`
This overlay will copy the binary for ytt to the `argocd-repo-server` pod. Adding this configuration to the existing deployment creates an `initContainer` using an [image](https://github.com/vmware-tanzu/carvel-docker-image) we publish that contains the Carvel tools. The container copies the ytt binary via a shared volume at `/custom-tools`, explained further in the [Argo docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/custom_tools/#adding-tools-via-volume-mounts).

```yaml
#! repo-server-overlay.yml
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.subset({"kind":"Deployment", "metadata":{"name":"argocd-repo-server"}})
---
spec:
  template:
    spec:
      #! 1. Define an emptyDir volume which will hold the custom binaries
      volumes:
        - name: custom-tools
          emptyDir: {}
      #! 2. Use an init container to copy custom binaries into the emptyDir
      initContainers:
        - name: download-carvel-tools
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
          command: [sh, -c]
          args:
            - cp /usr/local/bin/ytt /custom-tools/ytt
          volumeMounts:
            - mountPath: /custom-tools
              name: custom-tools
      #! 3. Volume mount the custom binary to the bin directory
      containers:
        #@overlay/match by=overlay.subset({"name": "argocd-repo-server"})
        - name: argocd-repo-server
          volumeMounts:
            - mountPath: /usr/local/bin/ytt
              name: custom-tools
              subPath: ytt
```

### Make the carvel-ytt plugin available to Applications 
Expose the plugin by patching the `argocd-cm` ConfigMap's `configManagementPlugins`. The command under `generate` is the command that will be run when using the plugin. 

```yaml
#! argocd-cm-overlay.yml
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:yaml", "yaml")

#@overlay/match by=overlay.subset({"kind":"ConfigMap", "metadata":{"name":"argocd-cm"}})
---
#@overlay/match missing_ok=True
data:
  #! Append to configManagementPlugins
  #@overlay/replace via=lambda left,right: yaml.encode(overlay.apply(yaml.decode(left), yaml.decode(right)))
  configManagementPlugins: |
    - name: carvel-ytt
      generate:                      #! Command to generate manifests YAML
        command: ["ytt"]
        args: ["-f", "."]
```
Note: Passing a plugin flags like `--data-values-file` is currently not easily doable. See the issue in Argo CD regarding this for more information, and for a workaround using environment variables.

### Apply the changes to the cluster
Since these overlays need to patch the Argo CD configuration, create the namespace and apply the overlays with the Argo CD installation manifests.

```shell
$ kubectl create namespace argocd
```

Now, lets install Argo CD Core. To keep setup simple use the core version that does not include the UI.

Run this command to apply the ytt overlays to the Argo CD core manifests and then apply that to the cluster using kapp (or modify for kubectl, if you prefer).

```shell
$ kapp deploy --app argo --namespace argocd -f <(ytt -f argocd-cm-overlay.yml -f  repo-server-overlay.yml -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.2.5/manifests/core-install.yaml)
```

## Create and template an Application with the ytt plugin
Now, create an Application resource that watches [this](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/tree/develop/config-step-2-template) git repo directory `config-step-2-template/`. This directory contains a simple ytt template and data values for a Service and Deployment.

```shell    
$ tree .
.
├── config.yml
└── values.yml

0 directories, 2 file
```

Add `spec.source.plugin` to tell Argo to use the ytt plugin. If you want to see updates automatically deployed when you make changes, fork the repo and update the `repoURL` reference below.

Additionally, create an `AppProject` resource to manually create the `default` project since there is a short delay before the one that is automatically created is available. This shouldn't be necessary outside of this example.

```yaml
# simple-app-application.yml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: simple-app
  namespace: argocd
spec:
  project: default
  # this sync policy will deploy the app without confirmation when changes are detected
  syncPolicy:
    automated: {}
  source:
    repoURL: https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes.git
    targetRevision: develop
    path: config-step-2-template

    # plugin config
    plugin:
      name: carvel-ytt
  destination:
    server: https://kubernetes.default.svc
    namespace: default
---
# this manually creates the default project
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  sourceRepos:
    - '*'
  destinations:
    - namespace: '*'
      server: '*'
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
```
Deploy it to the cluster and see that ytt was used to render the templates. 
```shell
$ kapp deploy --namespace argocd --app argo-app --file simple-app-application.yml
```
See the status of the deployed Application using the `argocd` cli
```shell
$ kubectl config set-context --current --namespace=argocd
$ argocd app get simple-app
```
For fun, after you port forward, you can view the app at `127.0.0.1:8080`. Visiting the site you should see a message that shows the data values stored in the repository were substituted into the ytt templates properly by the ytt plugin.
```shell
$ kubectl port-forward svc/simple-app 8080:80 --namespace default
```

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.

