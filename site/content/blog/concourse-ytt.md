---
title: "YTT Tutorial: Converting Concourse pipeline to YTT"
slug: concourse-ytt-101
date: 2022-03-08
author: Neil Hickey
excerpt: "Tutorial: Concourse to YTT 101"
tags: ['ytt', 'concourse']
---

Concourse is an automation system written in Go. It is most commonly used for CI/CD, and is built to scale to any kind of automation pipeline, from simple to complex. Each pipeline in Concourse is a declarative YAML file which represents input, tasks and output. Concourse pipelines often grow more complex as time goes on, and you may quickly find yourself overwhelmed trying to manage these large, complex pipelines. 

Ytt is Carvel's tool of choice when it comes to managing YAML, and in this tutorial we will work through a few ways I like to think about making YAML more maintainable and readable using a simple Concourse pipeline.

## You will need these to follow along:
- ytt (https://carvel.dev/ytt/docs/latest/install/)
- concourse (https://concourse-ci.org/install.html)
- docker-compose / docker (optional)

## Getting set up

1. Install a local Concourse server (optional)

```
wget https://concourse-ci.org/docker-compose.yml && docker-compose up -d

fly --target tutorial login --concourse-url http://localhost:8080 -u test -p test
```

1. Grab a simple pipeline to start working on

```
wget https://raw.githubusercontent.com/concourse/examples/master/pipelines/golang-lib.yml -O pipeline.yml
```

1. Set the pipeline

`fly --target tutorial set-pipeline --pipeline testing-pipeline --config pipeline.yml`

## What does this pipeline do?



## Time to refactor

1. Notice the follow resources look very similar! Let's remove some of this duplication

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

Let's pull this out into a function, so we can compose as many `registry-image` resources as we need

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

Now our pipeline.yml looks like:

```yaml
#@ def registry_image(name, repository, tag="latest"):
name: #@ name
type: registry-image
icon: docker
source:
  repository: #@ repository
  tag: #@ tag
#@ end

resources:
- #@ registry_image("golang-1.11.x-image", "golang", "1.11-stretch")
- #@ registry_image("golang-1.12.x-image", "golang", "1.12-stretch")
- #@ registry_image("golang-1.13.x-image", "golang", "1.13-stretch")
...
```

Pretty neat huh? We were able to reduce 20 lines of YAML into just 3. And adding another image will be as simple as adding another call to `registry_image()`. 

2. Let's have a look at the `jobs` section

   Convert these YAML anchors to using YTT.

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

<details>
<summary>Converting YAML anchors to YTT</summary>

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
</details>

   Now that we have most of the jobs and resources refactored, let's draw our attention to all these version numbers. Versions 1.11 to 1.13.

   The first step is to extract these out into a [ytt data value file](https://carvel.dev/ytt/docs/latest/ytt-data-values/#docs). This allows us to have a single place to configurable data.

<details>
<summary>Values file - values.yml</summary>

```yaml
#@data/values
---
versions: ["1.11", "1.12", "1.13"]
```
</details>

   Once we have our data values file, let's go ahead and import the 'data' module so we can use them in our pipeline.yml

<details>
<summary>Convert to using data.values</summary>

```yaml
#@ load("@ytt:data", "data")

---
resources:
#@ for/end version in data.values.versions:
- #@ registry_image("golang-" + version + ".x-image", "golang", version + "-stretch")

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
</details>

### Final Pipeline 

Original pipeline 

<details>
<summary>YTT template for our pipeline</summary>

```yaml
#@ load("@ytt:data", "data")

#@ def registry_image(name, repository, tag="latest"):
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
- #@ registry_image("golang-" + version + ".x-image", "golang", version + "-stretch")

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
