---
title: "Getting Started With ytt, Part 1"
slug: getting-started-with-ytt
date: 2022-10-12
author: Varsha Munishwar
excerpt: "Are you new to ytt and wondering where to start?
Here is an easy step-by-step tutorial that can introduce you to ytt and help you get started quickly.
"
image: /img/ytt.svg
tags: ['ytt', 'getting started', 'tutorials']
---

#### Welcome to the series of ytt getting started tutorials!

The part 1 of this series introduces you to ytt and helps you get started quickly.
It is an easy step-by-step tutorial that you can follow along and see ytt in action on the playground as well as on the CLI.

We will cover the following topics:
- Introduction to ytt
- What problems is ytt solving?
- See ytt in action on interactive playground and CLI

####  Video link - [Getting started tutorial - Part 1](https://youtu.be/DvApsPy0IrI)
{{< youtube id="DvApsPy0IrI" title="Getting started tutorial - Part 1" >}}

The key moments/timestamps are available if you watch on youtube. Please click on "more" and "view all".

Here is the YAML code to follow along on the [ytt playground](https://carvel.dev/ytt/#playground
)

#### 1) Simple Hello World!
```yaml
#! "Welcome to ytt tutorial series"
tutorials:
          title: "Hello world, welcome to ytt!"
           #! "Welcome to ytt tutorial series" 
```
#### 2) Extracting variables

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
Extract to variable
```yaml
#@ name = "frontend-service"
```
#### 3) Using functions 
```yaml
#@ def name(service_name):
#@   return service_name + "-service"
#@ end
```
Call the function as below
```yaml
name: #@ name("frontend")
```
#### 4) Loading data values
config.yml
```yaml
#@ load("@ytt:data","data")
#@ def name(name):
#@   return name+ "-service"
#@ end

apiVersion: v1
kind: Service
metadata:
  name: #@ name(data.values.name)
```
values.yml
```yaml
#@data/values
---
name: frontend
```
#### 5) Using for loop
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
#### 6) Using conditionals if/end
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

- brew tap vmware-tanzu/carvel
- brew install ytt
- Clone the examples repo -
  git clone https://github.com/vmware-tanzu/carvel-ytt
- cd carvel-ytt/examples
- ytt -f playground/basics/example-plain-yaml

Stay tuned for upcoming tutorials in this series where we will cover Schemas and Overlays!

Happy Templating :)


## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:
* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
