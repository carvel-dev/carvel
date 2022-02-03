---
title: "Continuous delivery using a Carvel ytt Argo CD plugin"
slug: argocd-carvel-plugin
date: 2022-02-02
author: Cari Lynn
excerpt: "Use your favorite Carvel templating tool in your GitOps continuous deployment using the Carvel ytt Argo CD plugin."
image: /img/logo.svg
tags: ['ytt', 'argocd', 'gitops']
---

Argo CD is a declarative, GitOps, continuous delivery tool for kubernetes. It follows the GitOps philosophy of using Git as a single source of truth for the desired application state. ytt templates are one way you can store desired application state. Here's how you can use ytt templates with Argo CD.

At a high level a deployment using Argo CD starts with a configuration change. A commit with a change is made to the application repository, causing the Argo CD controller to notice the desired state has changed. It processes the manifests from the application repository through built-in templating engines like helm, or what we will be using today, a Carvel Argo CD plugin. Finally, it applies the manifests to the cluster via kubectl.

## You will need these to start your journey:
- [argocd cli](https://argo-cd.readthedocs.io/en/stable/getting_started/#2-download-argo-cd-cli)
- kubernetes cluster (I'm using [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager))
- [kapp](https://github.com/vmware-tanzu/carvel-kapp) or [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [ytt](https://github.com/vmware-tanzu/carvel-ytt)

## Create the Carvel Plugin
To make the Carvel plugin available to the application we want to deploy, we need to make a couple patches to the Argo CD cluster configuration. We can do this with ytt overlays!

### Adding carvel-ytt binary to `argocd-repo-server`
This overlay will copy the binary for ytt to the `argocd-repo-server` pod. Adding this configuration to the existing deployment creates an `initContainer` using an image we publish that contains the Carvel tools. The container copies the ytt binary via volume mounts, as explained further in the [Argo docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/custom_tools/#adding-tools-via-volume-mounts).

```yaml
#! repo-server-overlay.yml
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.subset({"kind":"Deployment", "metadata":{"name":"argocd-repo-server"}}), expects=1
---
spec:
  template:
    spec:
      #! 1. Define an emptyDir volume which will hold the custom binaries
      volumes:
        - name: custom-tools
          emptyDir: {}
      #! 2. Use an init container to download/copy custom binaries into the emptyDir
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
        #@overlay/match by=overlay.subset({"name": "argocd-repo-server"}), expects=1
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
#@overlay/match by=overlay.subset({"kind":"ConfigMap", "metadata":{"name":"argocd-cm"}})
---
#@overlay/match missing_ok=True
data:
  #! TODO append instead of overwrite this
  configManagementPlugins: |
    - name: carvel-ytt
      generate:                      # Command to generate manifests YAML
        command: ["sh", "-c"]
        args: ["ytt -f ."]
```

### Apply the changes to the cluster
Since these files need to patch the Argo CD configuration, we can apply the ytt overlay when installing Argo CD directly, or as a separate continuous deployment as an exercise left to the reader.

Now, lets install Argo CD Core. To keep setup simple we are using the core version that does not include the UI. The manifests are available [here](https://argo-cd.readthedocs.io/en/stable/getting_started/#1-install-argo-cd): `https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml`. 

We can run this command to apply the ytt overlays to the Argo CD core manifests, then apply that to the cluster using kapp (or modify for kubectl, if you prefer). The `-y` continues deployment without confirmation. 

```shell
$ ytt -f argocd-cm-overlay.yml -f  repo-server-overlay.yml -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml  | kapp deploy --app argo --namespace argocd --file - -y
```

## Create and template an Application with the ytt plugin
Now, we're going to create an Application resource that watches the git repo directory `config-step-2-template/` containing simple ytt templates and data values. If you want to see updates automatically deployed when you make changes, fork this repo. Add `spec.source.plugin` to tell Argo to use the ytt plugin. 

```yaml
# simple-app-application.yml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: simple-app
  namespace: argocd
spec:
  project: default
  # this sync policy will deploy the app when changes are detected
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
```
Deploy it to the cluster and see that ytt was used to render the templates. 
```shell
$ kapp deploy --namespace argocd --app argo-app --file simple-app-application.yml
```
Inspect the Application using `argocd` cli
```shell
$ kubectl config set-context --current --namespace=argocd
$ argocd login --core
$ argocd app get simple-app
```
For fun, you can view the app at `127.0.0.1:8080`. Visiting the site you should see a message that shows the data values stored in the repository were substituted into the ytt templates properly by the ytt plugin.
```shell
$ kubectl port-forward svc/simple-app 8080:80 --namespace default
```

## Join us on Slack and GitHub

We are excited about this new adventure and we want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.

We look forward to hearing from you and hope you join us in building a strong packaging and distribution story for applications on Kubernetes!
