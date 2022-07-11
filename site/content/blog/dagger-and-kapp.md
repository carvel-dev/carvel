---
title: Kapp and Dagger"
slug: dagger-and-cloak
date: 2022-07-30
author: Renu Yarday
excerpt: "In this article, we will explore how to leverage kapp in a Dagger pipeline."
image: /img/kapp.svg
tags: ['kapp', 'dagger']
---

# Running kapp in a Dagger pipeline

In this article we will explore how to leverage kapp in a Dagger pipeline.

### What is Dagger?
Dagger is a portable devkit to build powerful CI/CD pipelines quickly and run them anywhere. Read more about Dagger [here](https://dagger.io/).

### Introducing kapp package for Dagger
Do you want to observe your Kubernetes deployments are going smoothly in your Dagger pipeline? Then we highly recommend trying out [kapp deploy](https://github.com/dagger/dagger/tree/main/pkg/universe.dagger.io/alpha/kubernetes/kapp). Kapp is now available as an alpha package with Dagger and can be easily consumed in your CI/CD. 

Below are the steps that one could use to add kapp to a dagger pipeline.

### The micro services demo project
Leveraging the well known [microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo) to create dagger plan to deploy. The cloned and updated project to run in a local kind cluster is present [here](https://github.com/renuy/microservices-demo).

This project's deployment manifest(configuration) for kubernetes is available as ./release/kubernetes-manifests.yaml

### Build and run locally using dagger plan
We need to have a dagger plan in place to deploy the application in the cluster. In this blog since the project is already created and build available as image, we will extend the project using the dagger plan to deploy it to a cluster (kind cluster).

#### Deploy.cue
The dagger plan is written in cue allowing it to be simple and readable. Lets look at the anatomy of the plan.

``` yaml
import (
	"dagger.io/dagger"
    "universe.dagger.io/alpha/kubernetes/kapp"
)

dagger.#Plan & {
	actions: test: {
		deploy: kapp.#Deploy & {
			app:        "boutique"
			fs:         client.filesystem."./".read.contents
			kubeConfig: client.commands.kc.stdout
			file:       "./release/kubernetes-manifests.yaml"
		}
		ls: kapp.#List & {
			fs:         client.filesystem."./".read.contents
			kubeConfig: client.commands.kc.stdout
			namespace:  "default"
		}
		inspect: kapp.#Inspect & {
			app:        "boutique"
			fs:         client.filesystem."./".read.contents
			kubeConfig: client.commands.kc.stdout
		}
		delete: kapp.#Delete & {
			app:        "boutique"
			fs:         client.filesystem."./".read.contents
			kubeConfig: client.commands.kc.stdout
		}
	}

	client: {
		commands: kc: {
			name: "kubectl"
			args: ["config", "view", "--raw"]
			stdout: dagger.#Secret
		}
		filesystem: "./": read: {
			contents: dagger.#FS
			include: ["./release/kubernetes-manifests.yaml"]
		}
	}
}

```

The plan itself consisits of action you would want to perform, in this case `test`, which has four sub-actions. 
We have supplied the required resources - kube-config and deployment manifest - via the client. 
The parameters needed to run the kapp commands have been made available in each of the commands.

Initialize the project
```
$ dagger project init
```
Install the required dagger packages
```
$ dagger project update
```
Now, try out the following command:
```
$dagger do --help

$dagger do test --help
Usage: 
  dagger do test [flags]

Options


Available Actions:
 deploy  
 ls      
 inspect 
 delete  

```
Dagger will list out the actions available as defined by your plan. 

#### Dagger do
In our case, we want to deploy the application locally using the dagger pipeline. To do the same use

``` 
$dagger do test deploy  --log-format plain
# output
➜  microservices-demo git:(main) ✗ dagger do test deploy  --log-format plain
12:34PM INFO  actions.test.deploy._image.build._dag."0"._pull | computing
12:34PM INFO  client.commands.kc | computing
12:34PM INFO  client.filesystem."./".read | computing
12:34PM INFO  client.commands.kc | completed    duration=100ms
12:34PM INFO  client.filesystem."./".read | completed    duration=100ms
12:34PM INFO  actions.test.deploy._image.build._dag."0"._pull | completed    duration=1.4s
12:34PM INFO  actions.test.deploy._image.build._dag."1"._copy | computing
12:34PM INFO  actions.test.deploy._image.build._dag."1"._copy | completed    duration=0s
12:34PM INFO  actions.test.deploy.container._exec | computing
12:34PM INFO  actions.test.deploy.container._exec | #6 0.370 Target cluster 'https://127.0.0.1:58013' (nodes: kind-control-plane)
12:34PM INFO  actions.test.deploy.container._exec | #6 0.512
12:34PM INFO  actions.test.deploy.container._exec | #6 0.512 Changes
12:34PM INFO  actions.test.deploy.container._exec | #6 0.512
12:34PM INFO  actions.test.deploy.container._exec | #6 0.512 Namespace  Name                   Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
12:34PM INFO  actions.test.deploy.container._exec | #6 0.513 default    adservice              Deployment  -       -    create  -       reconcile  -   -
12:34PM INFO  actions.test.deploy.container._exec | #6 0.513 ^          adservice              Service     -       -    create  -       reconcile  -   -
12:34PM INFO  actions.test.deploy.container._exec | #6 0.513 ^          cartservice            Deployment  -       -    create  -       reconcile  -   -
.
.
.
12:35PM INFO  actions.test.deploy.container._exec | #6 67.39 7:05:49AM: ok: reconcile deployment/recommendationservice (apps/v1) namespace: default
12:35PM INFO  actions.test.deploy.container._exec | #6 67.40 7:05:49AM: ---- waiting on 8 changes [16/24 done] ----
12:35PM INFO  actions.test.deploy.container._exec | #6 74.65 7:05:56AM: ok: reconcile deployment/redis-cart (apps/v1) namespace: default
12:35PM INFO  actions.test.deploy.container._exec | #6 74.66 7:05:56AM: ---- waiting on 7 changes [17/24 done] ----
12:36PM INFO  actions.test.deploy.container._exec | #6 77.76 7:06:00AM: ok: reconcile deployment/adservice (apps/v1) namespace: default
12:36PM INFO  actions.test.deploy.container._exec | #6 77.77 7:06:00AM: ok: reconcile deployment/currencyservice (apps/v1) namespace: default
12:36PM INFO  actions.test.deploy.container._exec | #6 77.77 7:06:00AM: ---- waiting on 5 changes [19/24 done] ----
.
.
.
12:37PM INFO  actions.test.deploy.container._exec | #6 150.7 7:07:13AM:  ^ Waiting for 1 unavailable replicas
12:37PM INFO  actions.test.deploy.container._exec | #6 150.7 7:07:13AM:  L ok: waiting on replicaset/loadgenerator-64f67cd465 (apps/v1) namespace: default
12:37PM INFO  actions.test.deploy.container._exec | #6 150.7 7:07:13AM:  L ongoing: waiting on pod/loadgenerator-64f67cd465-lhp6l (v1) namespace: default
12:37PM INFO  actions.test.deploy.container._exec | #6 150.7 7:07:13AM:     ^ Pending: PodInitializing
12:37PM INFO  actions.test.deploy.container._exec | #6 162.3 7:07:24AM: ok: reconcile deployment/loadgenerator (apps/v1) namespace: default
12:37PM INFO  actions.test.deploy.container._exec | #6 162.3 7:07:24AM: ---- applying complete [24/24 done] ----
12:37PM INFO  actions.test.deploy.container._exec | #6 162.3 7:07:24AM: ---- waiting complete [24/24 done] ----
12:37PM INFO  actions.test.deploy.container._exec | completed    duration=2m42.4s
12:37PM INFO  actions.test.deploy.container._exec | #6 162.3
12:37PM INFO  actions.test.deploy.container._exec | #6 162.3 Succeeded
```
Was happy to see the good old `Succeeded` as part of kapp deploy. Now on to next steps.

Since this is a local deployment use port-forwarding to access the application
```
$ kubectl port-forward service/frontend-external 8081:80
```

And thats it! Go ahead and access your application on http://localhost:8081/. Its simple and nothing cloak and dagger about it!

#### Clean up
Delete the boutique app locally, using dagger:
```
$ dagger do test deploy
```


## Join the Carvel Community

Thanks for following along! We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how and when to attend.


