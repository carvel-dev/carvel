---
title: "Getting Started With ytt, Part 1"
slug: getting-started-with-ytt
date: 2022-10-12
author: Varsha Munishwar
excerpt: "Are you new to ytt and wondering where to start?
Here is an easy, step-by-step tutorial that introduces ytt and gets you started quickly."

image: /img/ytt.svg
tags: ['ytt', 'ytt getting started', 'tutorials']
---

#### Welcome to the "Getting started with ytt" tutorial series!

Part 1 of this series introduces you to [ytt](https://carvel.dev/ytt/) and helps you get started quickly.
It is an easy, step-by-step tutorial that you can follow along and see ytt in action on the playground as well as on the CLI.

We will cover the following topics:
- Introduction to ytt
- What problems is ytt solving?
- See ytt in action on interactive playground and CLI

#### [Getting started with ytt - Part 1](https://youtu.be/DvApsPy0IrI)
{{< youtube id="DvApsPy0IrI" title="Getting started tutorial - Part 1" >}}

The key moments/timestamps are available if you watch on youtube. Please click on "more" and "view all".

If you would like to follow along with the video, you can use the YAML code snippets below on the [ytt playground](https://carvel.dev/ytt/#playground).

#### 1) Hello World! 
In this example, you will learn how ytt parses input and takes care of spacing and indentation. [Jump to this section in the video](https://youtu.be/DvApsPy0IrI&t=360).

```yaml
tutorials:
  title: "Hello world, welcome to ytt!"
  #! "Welcome to ytt tutorial series" 
```
#### 2) Sample configuration file 
config.yml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app.kubernetes.io/version: 0.1.0
    app.kubernetes.io/name: frontend
spec:
  type: ClusterIP
  ports:
  - port: 80
```

#### 3) Extract variables
In this example, you will learn how to extract variables. [Jump to this section in the video](https://youtu.be/DvApsPy0IrI&t=418).

config.yml
```yaml
#@ name = "frontend-service"

apiVersion: v1
kind: Service
metadata:
  name:  #@ name
  labels:
    app.kubernetes.io/version: 0.1.0
    app.kubernetes.io/name: #@ name
spec:
  type: ClusterIP
  ports:
  - port: 80
```

#### 4) Use functions 
In this example, you will learn how to use functions. [Jump to this section in the video](https://youtu.be/DvApsPy0IrI&t=486).

```yaml
#! Function definition
#@ def name(service_name):
#@   return service_name + "-service"
#@ end

apiVersion: v1
kind: Service
metadata:
  name: #@ name("frontend")
  labels:
    app.kubernetes.io/version: 0.1.0
    app.kubernetes.io/name: #@ name("frontend")
spec:
  type: ClusterIP
  ports:
  - port: 80
```

#### 5) Load data values
In this example, you will learn how to load data values. [Jump to this section in the video](https://youtu.be/DvApsPy0IrI&t=585).

config.yml
```yaml
#@ load("@ytt:data","data")

#@ def name(service_name):
#@   return service_name + "-service"
#@ end

apiVersion: v1
kind: Service
metadata:
  name: #@ name(data.values.name)
  labels:
    app.kubernetes.io/version: 0.1.0
    app.kubernetes.io/name: #@ name(data.values.name)
spec:
  type: ClusterIP
  ports:
  - port: 80
```
values.yml
```yaml
#@data/values
---
name: frontend
```
#### 6) Use for loop
In this example, you will learn how to use for loop. [Jump to this section in the video](https://youtu.be/DvApsPy0IrI&t=706).

config.yml
```yaml
#@ load("@ytt:data","data")

#@ def name(service_name):
#@   return service_name + "-service"
#@ end

#@ for service in data.values.services:
---
apiVersion: v1
kind: Service
metadata:
  name: #@ name(service.name)
  labels:
    app.kubernetes.io/version: #@ data.values.version
    app.kubernetes.io/name: #@ name(service.name)
spec:
  ports:
  - port: 80
#@ end
```
values.yml
```yaml
#@data/values
---
version: 0.1.0
services:
- name: frontend
- name: backend
```
#### 7) Use conditionals if/end
In this example, you will learn how to use if/end. [Jump to this section in the video](https://youtu.be/DvApsPy0IrI&t=908).

config.yml
```yaml
#@ load("@ytt:data","data")

#@ def name(service_name):
#@   return service_name + "-service"
#@ end

#@ for service in data.values.services:
---
apiVersion: v1
kind: Service
metadata:
  name: #@ name(service.name)
  labels:
    app.kubernetes.io/version: #@ data.values.version
    app.kubernetes.io/name: #@ name(service.name)
spec:
  ports:
  - name: https
    protocol: TCP
    port: 443
    targetPort: 9377
  #@ if service.allowHTTP:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 9376
  #@ end
#@ end
```
values.yml
```yaml
#@data/values
---
version: 0.1.0
services:
- name: frontend
  allowHTTP: true
- name: backend
  allowHTTP: false
```

### Steps to run ytt locally:
```shell
$ brew tap carvel-dev/carvel
$ brew install ytt
$ git clone https://github.com/carvel-dev/ytt
$ cd carvel-ytt/examples
$ ytt -f playground/basics/example-plain-yaml
```

### What's next: 
Check out the [Part 2 of this tutorial series!](getting-started-with-ytt-part-2/)


Happy Templating :)


## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:
* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/carvel-dev/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
