---
title: "Deploying Kubernetes Applications with ytt, kbld, and kapp"
slug: deploying-apps-with-ytt-kbld-kapp
date: 2020-12-13
author: Dmitriy Kalinin
excerpt: "ytt, kbld, and kapp when used together offer a powerful way to create, customize, iterate on, and deploy cloud native applications..."
image: /img/logo.svg
tags: ['Dmitriy Kalinin']
---

> TL;DR: [ytt](/ytt), [kbld](/kbld), [kapp](/kapp) tools when used together offer a powerful way to create, customize, iterate on, and deploy cloud native applications. These tools are designed to be used in various workflows such as local development, and production deployment. Each tool is designed to be single-purpose and composable, resulting in easier ways of integrating them into existing or new projects, and with other tools.

In this blog post we will focus on local application development workflow; however, tools introduced here work also well for other workflows, for example, for production GitOps deployments or manual application deploys. We plan to publish additional blog posts for other workflows. Let us know what you are most interested in!

We break down local application development workflow into the following stages:

- Source code authoring
- Configuration authoring (e.g. YAML configuration files)
- Building of source (e.g. `Dockerfile`)
- Deployment (e.g. `kubectl apply -f ...`)
- Repeat!

For each stage, we have open sourced a tool that we believe addresses that stage's challenges (sections below explore each tool in detail):

- configuration: [ytt](/ytt) for YAML configuration and templating
- building: [kbld](/kbld) for building Docker images and resolving image references
- deployment: [kapp](/kapp) for deploying Kubernetes resources

We'll use [carvel-simple-app-on-kubernetes application](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes) as our example to showcase how these tools can work together to develop and deploy a Kubernetes application.

## Preparation

Before getting too deep, let's get some basic preparations out of the way:

- Find a Kubernetes cluster (preferably Minikube as it better fits local development; Docker for Mac/Linux is another good option as it now includes Kubernetes)
- Check that the cluster works via `kubectl get nodes`
- Install [ytt](/ytt), [kbld](/kbld), [kapp](/kapp) by following instructions in [Install section on carvel.dev](/#install)

---
## Deploying the application

To get started with our example application, clone [carvel-simple-app-on-kubernetes](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes) locally:

```bash-plain
$ git clone https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes
$ cd carvel-simple-app-on-kubernetes
```

This directory contains a simple Go application that consists of `app.go` (an HTTP web server) and a `Dockerfile` for packaging. Multiple `config-step-*` directories contain variations of application configuration that we will use in each step.

```bash-plain
$ ls -l
Dockerfile
app.go
config-step-1-minimal
config-step-2-template
config-step-2a-overlays
config-step-2b-multiple-data-values
config-step-3-build-local
config-step-4-build-and-push
```

Typically, an application deployed to Kubernetes will include Deployment and Service resources in its configuration. In our example, [`config-step-1-minimal/` directory](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/blob/develop/config-step-1-minimal/) contains `config.yml` which contains exactly that. (Note that the Docker image is already preset and environment variable `HELLO_MSG` is hard coded. We'll get to those shortly.)

Traditionally, you can use `kubectl apply -f config-step-1-minimal/config.yml` to deploy this application. However, kubectl (1) does not indicate which resources are affected and how they are affected before applying changes, and (2) does not yet have a robust prune functionality to converge a set of resources ([GH issue](https://github.com/kubernetes/kubectl/issues/572)). kapp addresses and improves on several kubectl's limitations as it was designed from the start around the notion of a "Kubernetes Application" - a set of resources with the same label:

- kapp separates change calculation phase (diff), from change apply phase (apply) to give users visibility and confidence regarding what's about to change in the cluster
- kapp tracks and converges resources based on a unique generated label, freeing its users from worrying about cleaning up old deleted resources as the application is updated
- kapp orders certain resources so that the Kubernetes API server can successfully process them (e.g., CRDs and namespaces before other resources)
- kapp tries to wait for resources to become ready before considering the deploy a success

Let us deploy our application with kapp:

```bash-plain
$ kapp deploy -a simple-app -f config-step-1-minimal/
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)

Changes

Namespace  Name        Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  -       -    create  -       reconcile  -   -
^          simple-app  Service     -       -    create  -       reconcile  -   -

Op:      2 create, 0 delete, 0 update, 0 noop
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

8:17:44PM: ---- applying 2 changes [0/2 done] ----
8:17:44PM: create deployment/simple-app (apps/v1) namespace: default
8:17:44PM: create service/simple-app (v1) namespace: default
8:17:44PM: ---- waiting on 2 changes [0/2 done] ----
8:17:45PM: ok: reconcile service/simple-app (v1) namespace: default
8:17:45PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
8:17:45PM:  ^ Waiting for generation 2 to be observed
8:17:45PM:    ok: waiting on replicaset/simple-app-7fbc6b7c9b (apps/v1) namespace: default
8:17:45PM:    ongoing: waiting on pod/simple-app-7fbc6b7c9b-g92t7 (v1) namespace: default
8:17:45PM:     ^ Pending: ContainerCreating
8:17:45PM: ---- waiting on 1 changes [1/2 done] ----
8:17:45PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
8:17:45PM:  ^ Waiting for 1 unavailable replicas
8:17:45PM:    ok: waiting on replicaset/simple-app-7fbc6b7c9b (apps/v1) namespace: default
8:17:45PM:    ongoing: waiting on pod/simple-app-7fbc6b7c9b-g92t7 (v1) namespace: default
8:17:45PM:     ^ Pending: ContainerCreating
8:17:49PM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
8:17:49PM: ---- applying complete [2/2 done] ----
8:17:49PM: ---- waiting complete [2/2 done] ----

Succeeded
```

Our simple-app received a unique label `kapp.k14s.io/app=1557433075084066000` for resource tracking:

```bash-plain
$ kapp ls
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)

Apps in namespace 'default'

Name        Namespaces  Lcs   Lca
simple-app  default     true  23s

1 apps

Succeeded
```

Using this label, kapp tracks and allows inspection of all Kubernetes resources created for sample-app:

```bash-plain
$ kapp inspect -a simple-app --tree
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)

Resources in app 'simple-app'

Namespace  Name                              Kind        Owner    Conds.  Rs  Ri  Age
default    simple-app                        Deployment  kapp     2/2 t   ok  -   46s
default       simple-app-7fbc6b7c9b          ReplicaSet  cluster  -       ok  -   46s
default         simple-app-7fbc6b7c9b-g92t7  Pod         cluster  4/4 t   ok  -   46s
default    simple-app                        Service     kapp     -       ok  -   46s
default       simple-app                     Endpoints   cluster  -       ok  -   46s

Rs: Reconcile state
Ri: Reconcile information

5 resources

Succeeded
```

Note that it even knows about resources it did not directly create (such as ReplicaSet and Endpoints).

```bash-plain
$ kapp logs -f -a simple-app
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)

# starting tailing 'simple-app-7fbc6b7c9b-g92t7 > simple-app' logs
simple-app-7fbc6b7c9b-g92t7 > simple-app | 2020/12/14 01:17:48 Server started
```

`inspect` and `logs` commands demonstrate why it's convenient to view resources in "bulk" (via a label). For example, logs command will tail any existing or new Pod that is part of simple-app application, even after we make changes and redeploy.

Check out [kapp overview](/kapp) and [kapp docs](/kapp/docs/v0.34.0/) for further details.

---
## Accessing the deployed application

Once deployed successfully, you can access the application at `127.0.0.1:8080` in your browser with the help of kubectl port-forward command:

```bash-plain
$ kubectl port-forward svc/simple-app 8080:80
```

One downside to the kubectl command above: it has to be restarted if the application pod is recreated.

Alternatively, you can use k14s' kwt tool which exposes cluster IP subnets and cluster DNS to your machine. This way, you can access the application without requiring any restarts.

With kwt installed, run the following command

```bash-plain
$ sudo -E kwt net start
```

and open http://simple-app.default.svc.cluster.local/.

---
## Deploying configuration changes

Let's make a change to the application configuration to simulate a common occurrence in a development workflow. A simple observable change we can make is to change the value of the `HELLO_MSG` environment variable in [`config-step-1-minimal/config.yml`](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/blob/develop/config-step-1-minimal/config.yml):

```diff
         - name: HELLO_MSG
-          value: stranger
+          value: somebody
```

and re-run `kapp deploy` command:

```bash-plain
$ kapp deploy -a simple-app -f config-step-1-minimal/ --diff-changes
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)

@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
122,122           - name: HELLO_MSG
123     -           value: stranger
    123 +           value: somebody
124,124           image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
125,125           name: simple-app

Changes

Namespace  Name        Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  2/2 t   1m   update  -       reconcile  ok  -

Op:      0 create, 0 delete, 1 update, 0 noop
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y

8:19:32PM: ---- applying 1 changes [0/1 done] ----
8:19:33PM: update deployment/simple-app (apps/v1) namespace: default
8:19:33PM: ---- waiting on 1 changes [0/1 done] ----
8:19:33PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
8:19:33PM:  ^ Waiting for generation 4 to be observed
8:19:33PM:    ok: waiting on replicaset/simple-app-7fbc6b7c9b (apps/v1) namespace: default
8:19:33PM:    ok: waiting on replicaset/simple-app-6ddcb5c694 (apps/v1) namespace: default
8:19:33PM:    ok: waiting on pod/simple-app-7fbc6b7c9b-g92t7 (v1) namespace: default
8:19:33PM:    ongoing: waiting on pod/simple-app-6ddcb5c694-svtcn (v1) namespace: default
8:19:33PM:     ^ Pending: ContainerCreating
8:19:34PM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
8:19:34PM: ---- applying complete [1/1 done] ----
8:19:34PM: ---- waiting complete [1/1 done] ----

Succeeded
```

Above output highlights several kapp features:

- kapp detected a single change to simple-app Deployment by comparing given local configuration against the live cluster copy
- kapp showed changes in a git-style diff via `--diff-changes` flag
- since simple-app Service was not changed in any way, it was not "touched" during the apply changes phase at all
- kapp waited for Pods associated with a Deployment to converge to their ready state before exiting successfully

To double check that our change applied, go ahead and refresh your browser window with our deployed application.

Given that kapp does not care where application configuration comes from, one can use it with any other tools that produce Kubernetes configuration, for example, Helm's template command:

```bash-plain
$ helm template my-chart --values values.yml | kapp deploy -a my-app -f- --yes
```

---
## Templating application configuration

Managing application configuration is a hard problem. As an application matures, typically configuration needs to be tweaked for different environments, and different constraints. This leads to the desire to expose several, hopefully not too many, configuration knobs that could be tweaked at the time of the deploy.

This problem is typically solved in two ways: templating or patching. ytt supports both approaches. In this section we'll see how ytt allows to template YAML configuration, and in the next section, we'll see how it can patch YAML configuration via overlays.

Unlike many other tools used for templating, ytt takes a different approach to working with YAML files. Instead of interpreting YAML configuration as plain text, it works with YAML structures such as maps, lists, YAML documents, scalars, etc. By doing so ytt is able to eliminate a lot of problems that plague other tools (character escaping, ambiguity, etc.). Additionally ytt provides Python-like language (Starlark) that executes in a hermetic environment making it friendly, yet more deterministic compared to just using general purpose languages directly or non-familiar custom templating languages. Take a look at ytt: (TODO) The YAML Templating Tool that simplifies complex configuration management for a more detailed introduction.

To tie it all together, let's take a look at [`config-step-2-template/config.yml`](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/blob/develop/config-step-2-template/config.yml). You'll immediately notice that YAML comments (`#@ ...`) store templating metadata within a YAML file, for example:

```yaml
        env:
        - name: HELLO_MSG
          value: #@ data.values.hello_msg
```

Above snippet tells ytt that `HELLO_MSG` environment variable value should be set to the value of `data.values.hello_msg`. `data.values` structure comes from the builtin ytt data library that allows us to expose configuration knobs through a separate file, namely [`config-step-2-template/values.yml`](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/blob/develop/config-step-2-template/values.yml). Deployers of simple-app can now decide, for example, what hello message to set without making application code or configuration changes.

Let's chain ytt and kapp to deploy an update, and note `-v` flag which sets `hello_msg` value.

(You have two options how to do it: first is by piping result to kapp from ytt, or second by using process substitution. Second option is useful to be able to preserve ability to manually confirm.)

```bash-plain
$ ytt -f config-step-2-template/ -v hello_msg=friend | kapp deploy -a simple-app -c -f- --yes
...
```

```bash-plain
$ kapp deploy -a simple-app -c -f <(ytt -f config-step-2-template/ -v hello_msg=friend)
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)

@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
122,122           - name: HELLO_MSG
123     -           value: somebody
    123 +           value: friend
124,124           image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
125,125           name: simple-app

Changes

Namespace  Name        Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  2/2 t   2m   update  -       reconcile  ok  -

Op:      0 create, 0 delete, 1 update, 0 noop
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y

8:20:39PM: ---- applying 1 changes [0/1 done] ----
8:20:40PM: update deployment/simple-app (apps/v1) namespace: default
8:20:40PM: ---- waiting on 1 changes [0/1 done] ----
8:20:40PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
8:20:40PM:  ^ Waiting for generation 6 to be observed
8:20:40PM:    ok: waiting on replicaset/simple-app-7fbc6b7c9b (apps/v1) namespace: default
8:20:40PM:    ok: waiting on replicaset/simple-app-6ddcb5c694 (apps/v1) namespace: default
8:20:40PM:    ok: waiting on replicaset/simple-app-5dbf8bb678 (apps/v1) namespace: default
8:20:40PM:    ok: waiting on pod/simple-app-6ddcb5c694-svtcn (v1) namespace: default
8:20:40PM:    ongoing: waiting on pod/simple-app-5dbf8bb678-bqxvg (v1) namespace: default
8:20:40PM:     ^ Pending: ContainerCreating
8:20:41PM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
8:20:41PM: ---- applying complete [1/1 done] ----
8:20:41PM: ---- waiting complete [1/1 done] ----

Succeeded
```

We covered one simple way to use ytt to help you manage application configuration. Please take a look at examples in [ytt interactive playground](/ytt/#playground) to learn more about other ytt features which may help you manage YAML configuration more effectively.

Check out [ytt overview w/ interactive playground](/ytt) and [ytt docs](/ytt/docs/v0.30.0) for further details.

---
## Patching application configuration

ytt also offers another way to customize application configuration. Instead of relying on configuration authors (e.g. here authors of carvel-simple-app-on-kubernetes) to expose a set of configuration knobs, configuration consumers (e.g. here users that deploy carvel-simple-app-on-kubernetes) can use the ytt overlay feature to patch YAML documents with arbitrary changes.

For example, our simple app configuration templates do not make Deployment's `spec.replicas` configurable as a data value to control how may Pods are running. Instead of asking authors of simple app to expose a new data value, we can create an overlay file [`config-step-2a-overlays/custom-scale.yml`](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/blob/develop/config-step-2a-overlays/custom-scale.yml) that changes `spec.replicas` to a new value. Here is how it looks:

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment"})
---
spec:
  #@overlay/match missing_ok=True
  replicas: 3
```

Let's include it in our ytt invocation:

```bash-plain
$ kapp deploy -a simple-app -c -f <(ytt template -f config-step-2-template/ -f config-step-2a-overlays/custom-scale.yml -v hello_msg=friend)
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)

@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
108,108   spec:
    109 +   replicas: 3
109,110     selector:
110,111       matchLabels:

Changes

Namespace  Name        Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  2/2 t   5m   update  -       reconcile  ok  -

Op:      0 create, 0 delete, 1 update, 0 noop
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y

8:23:18PM: ---- applying 1 changes [0/1 done] ----
8:23:18PM: update deployment/simple-app (apps/v1) namespace: default
8:23:18PM: ---- waiting on 1 changes [0/1 done] ----
8:23:18PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
8:23:18PM:  ^ Waiting for generation 8 to be observed
8:23:18PM:    ok: waiting on replicaset/simple-app-7fbc6b7c9b (apps/v1) namespace: default
8:23:18PM:    ok: waiting on replicaset/simple-app-6ddcb5c694 (apps/v1) namespace: default
8:23:18PM:    ok: waiting on replicaset/simple-app-5dbf8bb678 (apps/v1) namespace: default
8:23:18PM:    ongoing: waiting on pod/simple-app-5dbf8bb678-lmhnq (v1) namespace: default
8:23:18PM:     ^ Pending: ContainerCreating
8:23:18PM:    ongoing: waiting on pod/simple-app-5dbf8bb678-kkx6c (v1) namespace: default
8:23:18PM:     ^ Pending
8:23:18PM:    ok: waiting on pod/simple-app-5dbf8bb678-bqxvg (v1) namespace: default
8:23:19PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
8:23:19PM:  ^ Waiting for 2 unavailable replicas
8:23:19PM:    ok: waiting on replicaset/simple-app-7fbc6b7c9b (apps/v1) namespace: default
8:23:19PM:    ok: waiting on replicaset/simple-app-6ddcb5c694 (apps/v1) namespace: default
8:23:19PM:    ok: waiting on replicaset/simple-app-5dbf8bb678 (apps/v1) namespace: default
8:23:19PM:    ongoing: waiting on pod/simple-app-5dbf8bb678-lmhnq (v1) namespace: default
8:23:19PM:     ^ Pending: ContainerCreating
8:23:19PM:    ongoing: waiting on pod/simple-app-5dbf8bb678-kkx6c (v1) namespace: default
8:23:19PM:     ^ Pending: ContainerCreating
8:23:19PM:    ok: waiting on pod/simple-app-5dbf8bb678-bqxvg (v1) namespace: default
8:23:20PM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
8:23:20PM: ---- applying complete [1/1 done] ----
8:23:20PM: ---- waiting complete [1/1 done] ----

Succeeded
```

Check out [ytt's Overlay module docs](/ytt/docs/v0.30.0/lang-ref-ytt-overlay/).

---
## Building container images locally

Kubernetes embraced use of container images to package source code and its dependencies. One way to deliver updated application is to rebuild a container when changing source code. kbld is a small tool that provides a simple way to insert container image building into deployment workflow. kbld looks for images within application configuration (currently it looks for image keys), checks if there is an associated source code, if so builds these images via Docker (could be pluggable with other builders), and finally captures built image digests and updates configuration with new references.

Before running kbld, let's change [`app.go`](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/blob/develop/app.go) by uncommenting `fmt.Fprintf(w, "<p>local change</p>")` to make a small change in our application.

[`config-step-3-build-local/build.yml`](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes/blob/develop/config-step-3-build-local/build.yml) is a new file in this config directory, which specifies that `docker.io/dkalinin/k8s-simple-app` image should be built from the current working directory where kbld runs (root of the repo).

If you are using Minikube, make sure kbld has access to Docker CLI bundled inside Minikube by running:

```bash-plain
$ eval $(minikube docker-env)
```

If you are using Docker for Mac (or related product that comes with Docker and Kubernetes), make sure that `docker ps` succeeds. If you do not have a local environment (i.e. running a remote cluster and have a local Docker daemon), read on but you may have to wait until the next section where we show how to use a remote registry.

Let's insert kbld after ytt and before kapp so that images used in our configuration are built before they are deployed by kapp:

```bash-plain
$ kapp deploy -a simple-app -c -f <(ytt -f config-step-3-build-local/ -v hello_msg=friend | kbld -f-)
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)
docker.io/dkalinin/k8s-simple-app | starting build (using Docker): . -> kbld:rand-1607909049338979000-1052013863149-docker-io-dkalinin-k8s-simple-app
docker.io/dkalinin/k8s-simple-app | Sending build context to Docker daemon  155.6kB
docker.io/dkalinin/k8s-simple-app | Step 1/8 : FROM golang:1.12
docker.io/dkalinin/k8s-simple-app | 1.12: Pulling from library/golang
docker.io/dkalinin/k8s-simple-app | dc65f448a2e2: Pulling fs layer
docker.io/dkalinin/k8s-simple-app | 346ffb2b67d7: Pulling fs layer
docker.io/dkalinin/k8s-simple-app | dea4ecac934f: Pulling fs layer
docker.io/dkalinin/k8s-simple-app | 8ac92ddf84b3: Pulling fs layer
docker.io/dkalinin/k8s-simple-app | 7ca605383307: Pulling fs layer
docker.io/dkalinin/k8s-simple-app | 020f524b99dd: Pulling fs layer
docker.io/dkalinin/k8s-simple-app | 06036b0307c9: Pulling fs layer
docker.io/dkalinin/k8s-simple-app | 8ac92ddf84b3: Waiting
docker.io/dkalinin/k8s-simple-app | 7ca605383307: Waiting
docker.io/dkalinin/k8s-simple-app | 020f524b99dd: Waiting
docker.io/dkalinin/k8s-simple-app | 06036b0307c9: Waiting
docker.io/dkalinin/k8s-simple-app | 346ffb2b67d7: Verifying Checksum
docker.io/dkalinin/k8s-simple-app | 346ffb2b67d7: Download complete
docker.io/dkalinin/k8s-simple-app | dea4ecac934f: Verifying Checksum
docker.io/dkalinin/k8s-simple-app | dea4ecac934f: Download complete
docker.io/dkalinin/k8s-simple-app | dc65f448a2e2: Verifying Checksum
docker.io/dkalinin/k8s-simple-app | dc65f448a2e2: Download complete
docker.io/dkalinin/k8s-simple-app | dc65f448a2e2: Pull complete
docker.io/dkalinin/k8s-simple-app | 346ffb2b67d7: Pull complete
docker.io/dkalinin/k8s-simple-app | dea4ecac934f: Pull complete
docker.io/dkalinin/k8s-simple-app | 8ac92ddf84b3: Verifying Checksum
docker.io/dkalinin/k8s-simple-app | 8ac92ddf84b3: Download complete
docker.io/dkalinin/k8s-simple-app | 06036b0307c9: Verifying Checksum
docker.io/dkalinin/k8s-simple-app | 06036b0307c9: Download complete
docker.io/dkalinin/k8s-simple-app | 8ac92ddf84b3: Pull complete
docker.io/dkalinin/k8s-simple-app | 7ca605383307: Verifying Checksum
docker.io/dkalinin/k8s-simple-app | 7ca605383307: Download complete
docker.io/dkalinin/k8s-simple-app | 020f524b99dd: Verifying Checksum
docker.io/dkalinin/k8s-simple-app | 020f524b99dd: Download complete
docker.io/dkalinin/k8s-simple-app | 7ca605383307: Pull complete
docker.io/dkalinin/k8s-simple-app | 020f524b99dd: Pull complete
docker.io/dkalinin/k8s-simple-app | 06036b0307c9: Pull complete
docker.io/dkalinin/k8s-simple-app | Digest: sha256:d0e79a9c39cdb3d71cc45fec929d1308d50420b79201467ec602b1b80cc314a8
docker.io/dkalinin/k8s-simple-app | Status: Downloaded newer image for golang:1.12
docker.io/dkalinin/k8s-simple-app |  ---> ffcaee6f7d8b
docker.io/dkalinin/k8s-simple-app | Step 2/8 : WORKDIR /go/src/github.com/k14s/k8s-simple-app-example/
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app |  ---> Running in e5302031b9f8
docker.io/dkalinin/k8s-simple-app | Removing intermediate container e5302031b9f8
docker.io/dkalinin/k8s-simple-app |  ---> 095be42775c9
docker.io/dkalinin/k8s-simple-app | Step 3/8 : COPY . .
docker.io/dkalinin/k8s-simple-app |  ---> 105c89c17cdf
docker.io/dkalinin/k8s-simple-app | Step 4/8 : RUN CGO_ENABLED=0 GOOS=linux go build -v -o app
docker.io/dkalinin/k8s-simple-app |  ---> Running in a5c3a7a2bc05
docker.io/dkalinin/k8s-simple-app | net
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | net/textproto
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | crypto/x509
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | internal/x/net/http/httpguts
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | internal/x/net/http/httpproxy
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | crypto/tls
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | net/http/httptrace
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | net/http
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | github.com/k14s/k8s-simple-app-example
docker.io/dkalinin/k8s-simple-app |
docker.io/dkalinin/k8s-simple-app | Removing intermediate container a5c3a7a2bc05
docker.io/dkalinin/k8s-simple-app |  ---> 0924fd031571
docker.io/dkalinin/k8s-simple-app | Step 5/8 : FROM scratch
docker.io/dkalinin/k8s-simple-app |  --->
docker.io/dkalinin/k8s-simple-app | Step 6/8 : COPY --from=0 /go/src/github.com/k14s/k8s-simple-app-example/app .
docker.io/dkalinin/k8s-simple-app |  ---> d34701670d3d
docker.io/dkalinin/k8s-simple-app | Step 7/8 : EXPOSE 80
docker.io/dkalinin/k8s-simple-app |  ---> Running in f108ebd60d03
docker.io/dkalinin/k8s-simple-app | Removing intermediate container f108ebd60d03
docker.io/dkalinin/k8s-simple-app |  ---> 86a189cb22aa
docker.io/dkalinin/k8s-simple-app | Step 8/8 : ENTRYPOINT ["/app"]
docker.io/dkalinin/k8s-simple-app |  ---> Running in 3b4c24cec6d6
docker.io/dkalinin/k8s-simple-app | Removing intermediate container 3b4c24cec6d6
docker.io/dkalinin/k8s-simple-app |  ---> f7f3662589ff
docker.io/dkalinin/k8s-simple-app | Successfully built f7f3662589ff
docker.io/dkalinin/k8s-simple-app | Successfully tagged kbld:rand-1607909049338979000-1052013863149-docker-io-dkalinin-k8s-simple-app
docker.io/dkalinin/k8s-simple-app | Untagged: kbld:rand-1607909049338979000-1052013863149-docker-io-dkalinin-k8s-simple-app
docker.io/dkalinin/k8s-simple-app | finished build (using Docker)
resolve | final: docker.io/dkalinin/k8s-simple-app -> kbld:docker-io-dkalinin-k8s-simple-app-sha256-f7f3662589ff5a746c70c5ef6c644aad7c8e5804457aec374764e71d48a69ab1

@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
  4,  4       deployment.kubernetes.io/revision: "3"
      5 +     kbld.k14s.io/images: |
      6 +       - Metas:
      7 +         - Path: /Users/dk/workspace/k14s-go/src/github.com/k14s/carvel-simple-app-on-kubernetes
      8 +           Type: local
      9 +         - Dirty: true
     10 +           RemoteURL: git@github.com:vmware-tanzu/carvel-simple-app-on-kubernetes
     11 +           SHA: 44625e5199dabaf1f90c92b78ff1dd524649136d
     12 +           Type: git
     13 +         URL: kbld:docker-io-dkalinin-k8s-simple-app-sha256-f7f3662589ff5a746c70c5ef6c644aad7c8e5804457aec374764e71d48a69ab1
  5, 14     creationTimestamp: "2020-12-14T01:17:45Z"
  6, 15     generation: 8
  ...
108,117   spec:
109     -   replicas: 3
110,118     selector:
111,119       matchLabels:
  ...
124,132             value: friend
125     -         image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
    133 +         image: kbld:docker-io-dkalinin-k8s-simple-app-sha256-f7f3662589ff5a746c70c5ef6c644aad7c8e5804457aec374764e71d48a69ab1
126,134           name: simple-app
127,135   status:

Changes

Namespace  Name        Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  2/2 t   7m   update  -       reconcile  ok  -

Op:      0 create, 0 delete, 1 update, 0 noop
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y

8:25:15PM: ---- applying 1 changes [0/1 done] ----
8:25:15PM: update deployment/simple-app (apps/v1) namespace: default
8:25:15PM: ---- waiting on 1 changes [0/1 done] ----
8:25:16PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
...

Succeeded
```

As you can see, the above output shows that kbld received ytt's produced configuration, and used the `docker build` command to build simple app image, ultimately capturing image digest reference and passing it onto kapp.

Once the deploy is successful check out application in your browser, it should have an updated response.

It's also worth showing that kbld not only builds images and updates references but also annotates Kubernetes resources with image metadata it collects and makes it quickly accessible for debugging. This may not be that useful during development but comes handy when investigating environment (staging, production, etc.) state.

```bash-plain
$ kapp inspect --tty=false -a simple-app --raw --filter-kind Deployment | kbld inspect -f-

Images

Image     kbld:docker-io-dkalinin-k8s-simple-app-sha256-f7f3662589ff5a746c70c5ef6c644aad7c8e5804457aec374764e71d48a69ab1
Metadata  - Path: /Users/dk/workspace/k14s-go/src/github.com/k14s/carvel-simple-app-on-kubernetes
            Type: local
          - Dirty: true
            RemoteURL: git@github.com:vmware-tanzu/carvel-simple-app-on-kubernetes
            SHA: 44625e5199dabaf1f90c92b78ff1dd524649136d
            Type: git
Resource  deployment/simple-app (apps/v1) namespace: default

1 images

Succeeded
```

Check out [kbld overview](/kbld) and [kbld docs](/kapp/docs/v0.27.0/) for further details.

---
## Building and pushing container images to a registry

The above section showed how to use kbld with local cluster that's backed by local Docker daemon. No remote registry was involved; however, for a production environment or in absence of a local environment, you will need to instruct kbld to push out built images to a registry accessible to your cluster.

config-step-4-build-local/build.yml specifies that docker.io/dkalinin/k8s-simple-app should be pushed to a repository as specified by `push_images_repo` data value.

Before continuing on, make sure that your Docker daemon is authenticated to the registry where image will be pushed via `docker login` command.

```bash-plain
$ kapp deploy -a simple-app -c -f <(ytt -f config-step-4-build-and-push/ -v hello_msg=friend -v push_images_repo=docker.io/your-username/your-repo | kbld -f-)

...
docker.io/dkalinin/k8s-simple-app | starting push (using Docker): kbld:docker-io-dkalinin-k8s-simple-app-sha256-268c33c1257eed727937fb22a68b91f065bf1e10c7ba23c5d897f2a2ab67f76d -> docker.io/dkalinin/k8s-simple-app
docker.io/dkalinin/k8s-simple-app | The push refers to repository [docker.io/dkalinin/k8s-simple-app]
docker.io/dkalinin/k8s-simple-app | 2c82b4929a5c: Preparing
docker.io/dkalinin/k8s-simple-app | 2c82b4929a5c: Layer already exists
docker.io/dkalinin/k8s-simple-app | latest: digest: sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0 size: 528
docker.io/dkalinin/k8s-simple-app | finished push (using Docker)
resolve | final: docker.io/dkalinin/k8s-simple-app -> index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0

@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
 30, 30             value: friend
 31     -         image: kbld:docker-io-dkalinin-k8s-simple-app-sha256-f7f3662589ff5a746c70c5ef6c644aad7c8e5804457aec374764e71d48a69ab1
     31 +         image: index.docker.io/your-username/your-repo@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
 32, 32           name: simple-app
 33, 33   status:

Changes

Namespace  Name        Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  2/2 t   7m   update  -       reconcile  ok  -

Op:      0 create, 0 delete, 1 update, 0 noop
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: y

8:25:15PM: ---- applying 1 changes [0/1 done] ----
8:25:15PM: update deployment/simple-app (apps/v1) namespace: default
8:25:15PM: ---- waiting on 1 changes [0/1 done] ----
8:25:16PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
...

Succeeded
```

As a benefit of using kbld, you will see that image digest reference (e.g. `index.docker.io/your-username/your-repo@sha256:4c8b96...`) was used instead of a tagged reference (e.g. `kbld:docker-io...`). Digest references are preferred to other image reference forms as they are immutable, hence provide a gurantee that exact version of built software will be deployed.

---
## Delete deployed application

Given that kapp tracks all resources that were deployed to Kubernetes cluster, deleting them is as easy as running `kapp delete` command:

```bash-plain
$ kapp delete -a simple-app
Target cluster 'https://192.168.99.111:8443' (nodes: minikube)

Changes

Namespace  Name                         Kind        Conds.  Age  Op      Op st.  Wait to  Rs  Ri
default    simple-app                   Deployment  2/2 t   11m  delete  -       delete   ok  -
^          simple-app                   Endpoints   -       11m  -       -       delete   ok  -
^          simple-app                   Service     -       11m  delete  -       delete   ok  -
^          simple-app-5dbf8bb678        ReplicaSet  -       8m   -       -       delete   ok  -
^          simple-app-6547879fcc        ReplicaSet  -       4m   -       -       delete   ok  -
^          simple-app-6547879fcc-tm2nj  Pod         4/4 t   4m   -       -       delete   ok  -
^          simple-app-6ddcb5c694        ReplicaSet  -       9m   -       -       delete   ok  -
^          simple-app-7fbc6b7c9b        ReplicaSet  -       11m  -       -       delete   ok  -

Op:      0 create, 2 delete, 0 update, 6 noop
Wait to: 0 reconcile, 8 delete, 0 noop

Continue? [yN]: y

...
8:30:30PM: ok: delete replicaset/simple-app-7fbc6b7c9b (apps/v1) namespace: default
8:30:30PM: ok: delete replicaset/simple-app-5dbf8bb678 (apps/v1) namespace: default
8:30:30PM: ---- waiting on 1 changes [7/8 done] ----
8:30:32PM: ok: delete pod/simple-app-6547879fcc-tm2nj (v1) namespace: default
8:30:32PM: ---- applying complete [8/8 done] ----
8:30:32PM: ---- waiting complete [8/8 done] ----

Succeeded
```

## Summary

We've seen how [ytt](/ytt), [kbld](/kbld), and [kapp](/kapp) can be used together to deploy and iterate on an application running on Kubernetes. Each one of these tools has been designed to be single-purpose and composable with other tools in the larger Kubernetes ecosystem.

We are eager to hear your thoughts and feedback in [#carvel in Kubernetes slack]({{% named_link_url "slack_url" %}}) and/or via Github issues, PRs and discussions (see {{% named_link_url "github_url" %}} for a list of associated repositories). Don't hesitate to reach out!
