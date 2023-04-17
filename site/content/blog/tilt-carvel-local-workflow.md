---
title: "Local development workflow with Tilt and Carvel"
slug: tilt-carvel-local-workflow
date: 2022-08-17
author: Ollie Hughes
excerpt: "Building development workflows for your Carvel deployments using Tilt"
image: /img/logo.svg
tags: ['ytt', 'kapp', 'kbld', 'tilt']
---

Software development often involves a cycle of making a code change, running unit tests, building an image then deploying a container
to Docker or Kubernetes. [Tilt](https://docs.tilt.dev/index.html) is a tool that can help to automate the local workflow of
```
code -> build -> deploy -> test
```

In this article, we will take a tour of the capabilities of Tilt and demonstrate how it can be integrated with Carvel tools. 

## What is Tilt?
Tilt is a command line tool with a built-in server that continuously builds and deploys code by watching for changes.
This allows developers to make code changes and run tests without having to manually run commands to deploy the change. 
This is a great feature for reducing friction when running end-to-end tests during development. 
Tilt supports deployment to local machine, docker, kubernetes and custom targets.  

Tilt is configured using a [Starlark](https://github.com/bazelbuild/starlark) based language that will feel familiar to 
[ytt](https://github.com/carvel-dev/ytt) users. By using a flexible configuration language, Tilt can easily
be customized for individual needs and integrated with existing workflows.

## Tools you will need to run the demo
- [tilt cli](https://docs.tilt.dev/index.html)
- [go](https://go.dev/doc/install) for building the demo
- Kubernetes cluster such as [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager)
- [kapp](https://github.com/carvel-dev/kapp)
- [ytt](https://github.com/carvel-dev/ytt)
- [kbld](https://github.com/carvel-dev/kbld)

## Checkout the demo project

First, [checkout the project from GitHub](https://github.com/ojhughes/carvel-tilt-example-go)

The repository contains a simple Go webserver and a set of manifests for deploying the application to Kubernetes

```
├── Dockerfile
├── README.md
├── Tiltfile
├── build
│   └── carvel-tilt
├── cmd
│   └── carvel-tilt
│       └── main.go
├── deployments
│   ├── build.yaml
│   ├── deployment.yaml
│   ├── namespace.yaml
│   ├── service.yaml
│   └── values-schema.yml
├── go.mod
├── pkg
│   └── api
│       └── handler.go
```

## Render Kubernetes manifests with ytt
The demo uses [ytt](https://github.com/carvel-dev/ytt) to render the Kubernetes YAML, this allows variables such as HTTP port to be substituted at build time.
The YAML can be rendered with the command 
```shell
ytt -f deployments
```
A number of default values are defined in the file `deployments/values-schema.yml`, which can be easily overridden.
To change the HTTP port of the deployed webserver, use command;

```shell
ytt -f deployments --data-value-yaml port=8085
```
Note, `--data-value-yaml` is used instead of `--data-value` because port is an integer value

## Building the image with kbld
[kbld](https://github.com/carvel-dev/kbld) is used to build the image, this is a very useful tool for local development as it will automatically tag
the image and update the Kubernetes manifests. Updating the tag every build is important as it ensures Kubernetes
will use the latest image version.

In the demo, `kbld` uses [docker](https://www.docker.com) to build the image using the `Dockerfile` in the root of the project.

Build the image using the following commands. 

```shell
# Compile the Go binary locally as it will be copied to the Docker image
GOOS=linux GOARCG=amd64 go build -o build/carvel-tilt cmd/carvel-tilt/main.go

# Set REGISTRY variable to an image registry that you access to push images
export REGISTRY=docker.io/my-registry/carvel-tilt-example-go

# Build and push the image
ytt -f deployments -v registry=${REGISTRY} | kbld -f -
```
The output will show the Kubernetes yaml has been updated to use the tag of freshly built image

## Deploy to Kubernetes with kapp
Now we know how to build and tag the image, [kapp](https://github.com/carvel-dev/kapp) can deploy the application. `kapp` builds on the functionality
of `kubectl apply -f ...` by grouping resources and managing dependencies them.

The app can be deployed with the command

```shell
     ytt -f deployments -v registry=${REGISTRY}| \
      kbld -f - | \
      kapp deploy -n default -a carvel-tilt-demo -y -f -
```

## Bringing it all together with Tilt
Using Tilt, the `ytt`, `kbld` and `kapp` commands will be automated to run every time a local code change is made.
Tilt is configured using the `Tiltfile` in the root of the project. Visual Studio code has a [plugin](https://marketplace.visualstudio.com/items?itemName=tilt-dev.Tiltfile)
for editing Tiltfiles and is highly recommended.

### Build stage
First, a `local_resource` is defined to compile the Go application. A `local_resource` describes a task that runs on the local machine

```python
compile_cmd = """
    rm build/carvel-tilt || true &&
	go build \
        -o build/carvel-tilt \
        cmd/carvel-tilt/main.go &&
        echo "Go build finished\n"
"""
local_resource(
    'go-compile',
    compile_cmd,
    deps=['pkg', 'cmd', 'deployments'],
    env={'GOOS': 'linux', 'GOARCH': 'amd64'}
)

```
`compile_cmd` is a variable containing the go build command to run

`local_resouce` describes how to run the command. The `deps` argument references the files or folders that will trigger
this command to run.

### Deploy stage
To deploy the app to Kubernetes, `k8s_custom_deploy` is defined. This function runs a command that applies Kubernetes resources
and then returns the created resources as YAML. `kapp inspect` is used to return the raw objects for Tilt.
The `deps` argument is set to `build/carvel-tilt` as this forces Tilt to always run the build stage before the 
deploy stage.

```python
port = 8084
registry = os.getenv('REGISTRY','docker.io/ojhughes')

kapp_apply_cmd = """
    ytt --file deployments --data-value-yaml port=%d -v registry=%s| 
    kbld -f - | 
    kapp deploy -n default -a carvel-tilt-demo -y -f - > /dev/null &&
    kapp inspect -n default -a carvel-tilt-demo --raw --tty=false
""" % (port, registry)

kapp_delete_cmd = "kapp delete -n default -a carvel-tilt-demo -y"

k8s_custom_deploy(
    name='carvel-tilt-demo',
    deps=['build/carvel-tilt'],
    apply_cmd=kapp_apply_cmd,
    delete_cmd=kapp_delete_cmd
)
k8s_resource('carvel-tilt-demo', port_forwards=port, auto_init=False )
```
### Port forwarding
Tilt can automatically create a port forward for the application using `k8s_resource`. 
```python
k8s_resource(
    'carvel-tilt-demo', 
     port_forwards=port
 )
```
### Running Tilt

Make sure the `REGISTRY` environment variable is set and simply run `tilt up`, this will read the `Tiltfile` and start the build/deploy workflow
Once `tilt` is running, you can press the `s` key to stream the logs to the console or open [http://localhost:10350](http://localhost:10350) in your browser

```shell
# Set the variable to a registry you have push access to
export REGISTRY=docker.io/myregistry

# Build and deploy the project
tilt up

# Test the app works using the port forward created by tilt
curl localhost:8084

# Tear everything down
tilt down
```
You can see the complete Tiltfile here [https://github.com/ojhughes/carvel-tilt-example-go/blob/main/Tiltfile](https://github.com/ojhughes/carvel-tilt-example-go/blob/main/Tiltfile)

### See it in action!
![](/images/blog/tilt-animated-demo.gif)

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
