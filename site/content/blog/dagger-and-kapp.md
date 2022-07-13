---
title: Kapp and Dagger
slug: kapp-and-dagger
date: 2022-07-30
author: Renu Yarday
excerpt: "In this article, we will explore how to leverage kapp in a Dagger pipeline."
image: /img/kapp.svg
tags: ['kapp', 'dagger']
---

# Running kapp in a Dagger pipeline

In this article, we will explore how to leverage kapp in a Dagger pipeline.

### What is Dagger?
[Dagger]((https://dagger.io/)) is a portable devkit to build powerful CI/CD pipelines quickly and run them anywhere.

### Introducing kapp package for Dagger
Do you want to deploy your Kubernetes configuration from your Dagger pipeline? Along with applying changes safely and predictably, watching resources as they converge. Then we highly recommend trying out [kapp deploy](https://github.com/dagger/dagger/tree/main/pkg/universe.dagger.io/alpha/kubernetes/kapp). Kapp is available as an alpha package with Dagger and can be easily consumed in your CI/CD.

Below are the steps that one could use to add kapp to a dagger pipeline.

### The micro services demo project
Leveraging the well known [microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo) to create dagger plan to deploy. The cloned and updated project to run in a local kind cluster is present [here](https://github.com/renuy/microservices-demo).

This project's deployment manifest(configuration) for Kubernetes is available at `./release/kubernetes-manifests.yaml`

### Build and run locally using dagger plan
We need to have a dagger plan in place to deploy the application in the cluster. Since the project is already created and build is available as an image, we will extend it using the dagger plan to deploy it to a cluster [(kind cluster)](https://kind.sigs.k8s.io/docs/user/quick-start/#installation). Please ensure your cluster is up and running:
```
$ kind create cluster
```

#### Writing our dagger plan
The dagger plan is written in cue allowing it to be simple and readable. Lets look at the anatomy of the plan.

File: deploy.cue
```cue
import (
    "dagger.io/dagger"
    "universe.dagger.io/alpha/kubernetes/kapp"
)

dagger.#Plan & {
	actions: {
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

The plan consists of a list of actions we want to perform. Each action represents the commands that we want to run and has the parameters that are required to run the command.
The required resources - kube-config and deployment manifest - are provided via the client. 

Initialize the project
```
$ dagger project init
```
Install the required Dagger packages:
```
$ dagger project update
```
Once kapp package is installed, we can list the available actions using the following command:
```
$ dagger do --help
Usage: 
  dagger do [flags]

Options


Available Actions:
 deploy  
 ls      
 inspect 
 delete  

```
Dagger will list out the actions available as defined by your plan. 

#### Execute the dagger plan
In our case, we want to deploy the application locally using the Dagger pipeline. To do the same use:

``` 
$ dagger do deploy --log-format plain
# output
12:10PM INFO  actions.deploy._image.build._dag."0"._pull | computing
12:10PM INFO  client.commands.kc | computing
12:10PM INFO  client.filesystem."./".read | computing
12:10PM INFO  client.filesystem."./".read | completed    duration=100ms
12:10PM INFO  client.commands.kc | completed    duration=300ms
12:10PM INFO  actions.deploy._image.build._dag."0"._pull | completed    duration=1.4s
12:10PM INFO  actions.deploy._image.build._dag."1"._copy | computing
12:10PM INFO  actions.deploy._image.build._dag."1"._copy | completed    duration=0s
12:10PM INFO  actions.deploy.container._exec | computing
12:10PM INFO  actions.deploy.container._exec | #6 0.350 Target cluster 'https://127.0.0.1:61389' (nodes: kind-control-plane)
12:10PM INFO  actions.deploy.container._exec | #6 0.456
12:10PM INFO  actions.deploy.container._exec | #6 0.456 Changes
12:10PM INFO  actions.deploy.container._exec | #6 0.456
12:10PM INFO  actions.deploy.container._exec | #6 0.456 Namespace  Name                   Kind        Conds.  Age  Op      Op st.  Wait to    Rs  Ri
12:10PM INFO  actions.deploy.container._exec | #6 0.456 default    adservice              Deployment  -       -    create  -       reconcile  -   -
12:10PM INFO  actions.deploy.container._exec | #6 0.456 ^          adservice              Service     -       -    create  -       reconcile  -   -
12:10PM INFO  actions.deploy.container._exec | #6 0.456 ^          cartservice            Deployment  -       -    create  -       reconcile  -   -
...snip...
12:10PM INFO  actions.deploy.container._exec | #6 0.458 Op:      24 create, 0 delete, 0 update, 0 noop, 0 exists
12:10PM INFO  actions.deploy.container._exec | #6 0.458 Wait to: 24 reconcile, 0 delete, 0 noop
12:10PM INFO  actions.deploy.container._exec | #6 0.484
12:10PM INFO  actions.deploy.container._exec | #6 0.484 6:40:05AM: ---- applying 24 changes [0/24 done] ----
12:10PM INFO  actions.deploy.container._exec | #6 0.528 6:40:06AM: create service/currencyservice (v1) namespace: default
12:10PM INFO  actions.deploy.container._exec | #6 0.558 6:40:06AM: create service/recommendationservice (v1) namespace: default
12:10PM INFO  actions.deploy.container._exec | #6 0.575 6:40:06AM: create service/adservice (v1) namespace: default
...snip...
12:11PM INFO  actions.deploy.container._exec | #6 107.5 6:41:52AM:  ^ Waiting for 1 unavailable replicas
12:11PM INFO  actions.deploy.container._exec | #6 107.5 6:41:52AM:  L ok: waiting on replicaset/recommendationservice-8897f4647 (apps/v1) namespace: default
12:11PM INFO  actions.deploy.container._exec | #6 107.5 6:41:52AM:  L ongoing: waiting on pod/recommendationservice-8897f4647-wd2bt (v1) namespace: default
12:11PM INFO  actions.deploy.container._exec | #6 107.5 6:41:52AM:     ^ Condition Ready is not True (False)
12:11PM INFO  actions.deploy.container._exec | #6 107.5 6:41:52AM: ---- waiting on 4 changes [20/24 done] ----
12:11PM INFO  actions.deploy.container._exec | #6 111.6 6:41:57AM: ok: reconcile deployment/recommendationservice (apps/v1) namespace: default
12:11PM INFO  actions.deploy.container._exec | #6 111.6 6:41:57AM: ---- waiting on 3 changes [21/24 done] ----
...snip...
12:12PM INFO  actions.deploy.container._exec | #6 142.2 6:42:27AM: ---- waiting on 1 changes [23/24 done] ----
12:12PM INFO  actions.deploy.container._exec | completed    duration=2m45.7s
12:12PM INFO  actions.deploy.container._exec | #6 165.6 6:42:51AM: ok: reconcile deployment/loadgenerator (apps/v1) namespace: default
12:12PM INFO  actions.deploy.container._exec | #6 165.6 6:42:51AM: ---- applying complete [24/24 done] ----
12:12PM INFO  actions.deploy.container._exec | #6 165.6 6:42:51AM: ---- waiting complete [24/24 done] ----
12:12PM INFO  actions.deploy.container._exec | #6 165.7
12:12PM INFO  actions.deploy.container._exec | #6 165.7 Succeeded
```
Was happy to see the good old `Succeeded` as part of kapp deploy. Now on to next steps.

Since this is a local deployment use port-forwarding to access the application:
```
$ kubectl port-forward service/frontend-external 8081:80
```

And that's it! Go ahead and access your application on http://localhost:8081/. It's simple and nothing cloak and dagger about it!

#### Clean up
Delete the boutique app locally, using Dagger:
```
$ dagger do test delete
```


## Join the Carvel Community

Thanks for following along! We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how and when to attend.


