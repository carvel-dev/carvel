---
title: "ytt Tutorial: Converting Concourse pipeline to ytt"
slug: concourse-ytt-101
date: 2022-06-16
author: Neil Hickey
excerpt: "Tutorial: Concourse to ytt 101"
image: /img/ytt.svg
tags: ['ytt', 'concourse']
---

[Concourse](https://concourse-ci.org/) is an open source automation system written in Go. It is most commonly used for CI/CD, and is built to scale to any kind of automation pipeline, from simple to complex. Each pipeline in Concourse is a declarative YAML file which represents input, tasks and output. Concourse pipelines often grow more complex as time goes on, and you may quickly find yourself overwhelmed trying to manage these large, complex pipelines. 

Ytt is Carvel's tool of choice when it comes to managing YAML, and in this tutorial we will work through a few ways I like to think about making YAML more maintainable and readable using a simple Concourse pipeline.

## You will need these to follow along:
- ytt (https://carvel.dev/ytt/docs/latest/install/)
- concourse (https://concourse-ci.org/install.html)
- docker-compose / docker (optional)

## Getting set up

1. Install a local Concourse server (optional)

    ```console
    wget https://concourse-ci.org/docker-compose.yml && docker-compose up -d
    
    fly --target tutorial login --concourse-url http://localhost:8080 -u test -p test
    ```

1. Grab a simple pipeline to start working on

    ```console
    wget https://raw.githubusercontent.com/concourse/examples/master/pipelines/golang-lib.yml -O pipeline.yml
    ```

1. Set the pipeline

    ```console
    fly --target tutorial set-pipeline --pipeline testing-pipeline --config pipeline.yml
    ```

## What does this pipeline do?

This pipeline tests our component (https://github.com/golang/mock in this case) against various versions of GoLang. This is common task of a CI/CD system, running our tests against multiple inputs and validating that we are compatible across our supported platforms.

This pipeline is broken into two main sections, `resources` and `jobs`. See [concourse docs](https://concourse-ci.org/docs.html) for more on these.

- There are four `resources`:
  - One of these is our component under test - https://github.com/golang/mock
  - The remaining three reference a docker image that contains the platform we want to test against, Golang versions 1.11 -> 1.13

- There are three `jobs`:
  - Each of these are testing our component (https://github.com/golang/mock in this case) against a different version of Golang.

## Time to refactor

Notice that the following resources look very similar? This looks like a good place to start, let's remove some of this duplication!

```
- name: golang-1.11.x-image
  type: registry-image
  icon: docker
  source:
    repository: golang
    tag: 1.11-stretch

- name: golang-1.12.x-image
  type: registry-image
  icon: docker
  source:
    repository: golang
    tag: 1.12-stretch

- name: golang-1.13.x-image
  type: registry-image
  icon: docker
  source:
    repository: golang
    tag: 1.13-stretch
```

Let's pull this out into a function, so we can compose as many `registry-image` resources as we need.

```yaml
#@ def registry_image(repository, name, tag="latest"):
name: #@ name
type: registry-image
icon: docker
source:
  repository: #@ repository
  tag: #@ tag
#@ end
```

Now our pipeline looks like:

```yaml
#@ def registry_image(repository, name, tag="latest"):
name: #@ name
type: registry-image
icon: docker
source:
  repository: #@ repository
  tag: #@ tag
#@ end

resources:
- #@ registry_image("golang", "golang-1.11.x-image", "1.11-stretch")
- #@ registry_image("golang", "golang-1.12.x-image", "1.12-stretch")
- #@ registry_image("golang", "golang-1.13.x-image", "1.13-stretch")
...
```

Pretty neat huh? We were able to reduce 20 lines of YAML into just 3. And adding another image will be as simple as adding another call to `registry_image()`. 

### Let's run it

`fly --target tutorial set-pipeline --pipeline testing-pipeline --config <(ytt -f pipeline.yml)`

Looking good so far, now let's have a look at the `jobs` section.

Convert these YAML anchors to using ytt instead:

```yaml
jobs:
- name: golang-1.11
  public: true
  plan:
    - get: golang-mock-git
      trigger: true
    - get: golang-1.11.x-image
      trigger: true
    - task: run-tests
      image: golang-1.11.x-image
      config:
        << : *task-config
```

### Converting YAML anchors to ytt

```yaml
#@ def lint_and_test_golang_mock():
platform: linux
inputs:
  - name: golang-mock-git
    path: go/src/github.com/golang/mock
params:
  GO111MODULE: "on"
run:
  path: /bin/sh
  args:
    - -c
    - |
      GOPATH=$PWD/go

      cd go/src/github.com/golang/mock

      go vet ./...
      go build ./...
      go install github.com/golang/mock/mockgen
      GO111MODULE=off go get -u golang.org/x/lint/golint
      ./ci/check_go_fmt.sh
      ./ci/check_go_lint.sh
      ./ci/check_go_generate.sh
      ./ci/check_go_mod.sh
      go test -v ./...
#@ end

jobs:
- name: golang-1.11
  public: true
  plan:
    - get: golang-mock-git
      trigger: true
    - get: golang-1.11.x-image
      trigger: true
    - task: run-tests
      image: golang-1.11.x-image
      config: #@ lint_and_test_golang_mock()
- name: golang-1.12
  public: true
  plan:
    - get: golang-mock-git
      trigger: true
    - get: golang-1.12.x-image
      trigger: true
    - task: run-tests
      image: golang-1.12.x-image
      config: #@ lint_and_test_golang_mock()
- name: golang-1.13
  public: true
  plan:
    - get: golang-mock-git
      trigger: true
    - get: golang-1.13.x-image
      trigger: true
    - task: run-tests
      image: golang-1.13.x-image
      config: #@ lint_and_test_golang_mock()
```

Now that we have most of the jobs and resources refactored, let's draw our attention to all these version numbers: Versions 1.11 to 1.13.

The first step is to extract these out into a [ytt data value file](https://carvel.dev/ytt/docs/latest/ytt-data-values/#docs). This allows us to have a single place to configurable data.

### Values file - values.yml

```yaml
#@data/values
---
versions: ["1.11", "1.12", "1.13"]
```

Once we have our data values file, let's go ahead and import the 'data' module so we can use them in our pipeline.yml.

### Convert to using data.values

```yaml
#@ load("@ytt:data", "data")

---
resources:
#@ for/end version in data.values.versions:
- #@ registry_image("golang", "golang-" + version + ".x-image", version + "-stretch")

- name: golang-mock-git
  type: git
  icon: github
  source:
    uri: https://github.com/golang/mock.git

jobs:
#@ for/end version in data.values.versions:
- name: #@ "golang-" + version
  public: true
  plan:
    - get: golang-mock-git
      trigger: true
    - get: #@ "golang-" + version + ".x-image"
      trigger: true
    - task: run-tests
      image: #@ "golang-" + version + ".x-image"
      config: #@ lint_and_test_golang_mock()
```

### Final Pipeline 

Nice job! We have made it to the end of this refactoring; let's have a look at what we ended up with.

```yaml
#@ load("@ytt:data", "data")

#@ def registry_image(repository, name, tag="latest"):
name: #@ name
type: registry-image
icon: docker
source:
  repository: #@ repository
  tag: #@ tag
#@ end

#@ def lint_and_test_golang_mock():
platform: linux
inputs:
  - name: golang-mock-git
    path: go/src/github.com/golang/mock
params:
  GO111MODULE: "on"
run:
  path: /bin/sh
  args:
    - -c
    - |
      GOPATH=$PWD/go

      cd go/src/github.com/golang/mock

      go vet ./...
      go build ./...
      go install github.com/golang/mock/mockgen
      GO111MODULE=off go get -u golang.org/x/lint/golint
      ./ci/check_go_fmt.sh
      ./ci/check_go_lint.sh
      ./ci/check_go_generate.sh
      ./ci/check_go_mod.sh
      go test -v ./...
#@ end

---
resources:
#@ for/end version in data.values.versions:
- #@ registry_image("golang", "golang-" + version + ".x-image", version + "-stretch")

- name: golang-mock-git
  type: git
  icon: github
  source:
    uri: https://github.com/golang/mock.git

jobs:
#@ for/end version in data.values.versions:
- name: #@ "golang-" + version
  public: true
  plan:
    - get: golang-mock-git
      trigger: true
    - get: #@ "golang-" + version + ".x-image"
      trigger: true
    - task: run-tests
      image: #@ "golang-" + version + ".x-image"
      config: #@ lint_and_test_golang_mock()
```

Final Values file - values.yml

```yaml
#@data/values
---
versions: ["1.11", "1.12", "1.13"]
```
  
### Let's run it

`fly --target tutorial set-pipeline --pipeline testing-pipeline --config <(ytt -f pipeline.yml -f values.yml)`  

The final pipeline can be found in the ytt playground [here](https://carvel.dev/ytt/#gist:https://gist.github.com/neil-hickey/5ef41f1df3a4bb63962fc2d577cb32d0) / [github gist](https://gist.github.com/neil-hickey/5ef41f1df3a4bb63962fc2d577cb32d0).

### What's next?

We have refactored a simple Concourse pipeline using the [DRY principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself).

Our file has gone from 89 lines of YAML to 61. Ok not that impressive, however we have made this pipeline simple to extend, removed duplication, and set ourselves up with a solid template to build on. 

This tutorial just scratches the surface of the power of ytt, be sure to check out some of our other blogs and the ytt playground to really dig into some of the more advanced concepts:

- [Garrett's fantastic blog about paramaterizing project config using ytt](https://carvel.dev/blog/parameterizing-project-config-with-ytt/)
- [Getting started with ytt overlays](https://carvel.dev/blog/primer-on-ytt-overlays/)
- [ytt's interactive playground](https://carvel.dev/ytt/)
  
## Join the Carvel Community

Thanks for following along! We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how and when to attend.
