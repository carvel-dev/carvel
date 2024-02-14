---
title: "Using ytt to create Crossplane Template Function"
slug: crossplane-ytt-template-function
date: 2024-02-14
author: Rohit Aggarwal
excerpt: "Using ytt to create composition functions to template Crossplane resources"
image: /img/logo.svg
tags: ['Rohit Aggarwal', 'ytt', 'crossplane']
---

In this blog, we are going to learn on how to create a [Crossplane](https://www.crossplane.io/) Composition function which will compose the Crossplane resources using [ytt](https://carvel.dev/ytt) templates.

## What is Crossplane?
[Crossplane](https://www.crossplane.io/) is an open-source Kubernetes extension that empowers organizations to manage cloud infrastructure across any cloud through standard Kubernetes APIs. It allows platform teams to declaratively define and manage the cloud infrastructure, like  databases, storage volumes, virtual machines, etc., through Kubernetes APIs. 

Crossplane has several core components referred to as '[Concepts](https://docs.crossplane.io/v1.14/concepts/)' that can work together to acheive your infrastructure goals. A few that we will use in this example are Composite Resource, Compositions, and Composition functions.

## Crossplane Composite Resource
A [composite resource](https://docs.crossplane.io/v1.14/concepts/composite-resources/) represents a set of managed resources as a single Kubernetes object. It uses Composition template to create multiple managed resources as a single Kubernetes object. 

## Crossplane Compositions
[Compositions](https://docs.crossplane.io/v1.14/concepts/compositions/) are a template for creating multiple managed resources as a single object. A Composition composes individual managed resources together into a larger, reusable solution. An example of Composition may combine a virtual machine, storage resources, and networking policies. A Composition template links all these individual resources together.

Crossplane Compositions have some limitations though:

1. Compositions don't support conditions, meaning that the transformations they provide are applied on an "all or nothing" basis.
2. They also don't support loops, which means that you cannot apply transformations iteratively.
3. Finally, advanced operations are not supported either, like checking for statuses in other systems.

To overcome this, Crossplane introduced the composition function.

## Crossplane Composition Function
[Composition functions](https://docs.crossplane.io/v1.14/concepts/composition-functions/) (or just functions, for short) are custom programs that template Crossplane resources. Crossplane calls composition functions to determine what resources it should create when you create a composite resource (XR).

## Prerequisites 
* [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) -- to create a test Kubernetes cluster. Use this [link](https://kind.sigs.k8s.io/docs/user/quick-start/#creating-a-cluster) to set up Kubernetes cluster on `kind`.
* [kubectl](https://kubernetes.io/docs/reference/kubectl/) -- to apply manifests to provision cloud resources. Use this [link](https://kubernetes.io/docs/tasks/tools/#kubectl) to install `kubectl`.
* [Helm](https://helm.sh/) -- to install Crossplane on the test cluster. Use this [link](https://helm.sh/docs/intro/quickstart/#install-helm) to install `helm`.

## Install Crossplane
Use this [link](https://docs.crossplane.io/latest/software/install/) to install Crossplane.


## Create the ytt templating composition function
[YTT](https://carvel.dev/ytt) is a tool to template and patch YAML files written in [Go](https://go.dev/). Mostly, it has been used as an executable in the form of CLI. However, in this example we will use it as a library to create Crossplane Composition function.

Read the Composition Function [documentation](https://docs.crossplane.io/knowledge-base/guides/write-a-composition-function-in-go/) for more details on how to build your own functions.

### Use ytt as a library
Crossplane has already created a template github repository (`function-template-go`) for writing `composition function` in Go. We will fork this [repo](https://github.com/crossplane/function-template-go) and setup our `Go` project by making the necessary changes as mentioned in the [README](https://github.com/crossplane/function-template-go/blob/main/README.md). 
To consume `ytt` as a library:

1. Fork the [repo](https://github.com/crossplane/function-template-go).
2. Add `ytt` as a dependency in `go.mod`:

    ```
    ...
    require  (
        ...
        github.com/vmware-tanzu/carvel-ytt v0.46.2
        ...
    )
    ```

3. Define `input.go` to contain the type for the Crossplane function. 
    ```
    type YTT struct {
        metav1.TypeMeta   `json:",inline"`
        metav1.ObjectMeta `json:"metadata,omitempty"`

        // Source specifies the different types of input sources that can be used with this function
        Source TemplateSource `json:"source"`
        // Inline is the inline form input of the templates
        Inline string `json:"inline,omitempty"`
        // FileSystem is the folder path where the templates are located
        FileSystem *TemplateSourceFileSystem `json:"fileSystem,omitempty"`
    }

    type TemplateSource string

    const (
        // InlineSource indicates that function will get its input as inline
        InlineSource TemplateSource = "Inline"

        // FileSystemSource indicates that function will get its input from a folder
        FileSystemSource TemplateSource = "FileSystem"
    )

    type TemplateSourceFileSystem struct {
        DirPath string `json:"dirPath,omitempty"`
    }
    ```
    Sample `input.go` can be found [here](https://github.com/rohitagg2020/function-ytt-templating/blob/main/input/v1beta1/input.go). 

4. Run `go generate` command.

5. create and populate an instance of the ytt template command:

    ```
    templatingOptions := yttcmd.NewOptions()
    ```

6. invoke the ytt template command to evaluate:
       
    ```
    output := templatingOptions.RunWithFiles(input, noopUI)
    ```

    Internally, we are going to convert the inline `ytt` template into a file and then pass the file as `input` to the ytt `RunWithFiles` function. Sample code and more logic can be found [here](https://github.com/rohitagg2020/function-ytt-templating/blob/main/ytt.go).

7. Add logic to the `RunFunction` in `fn.go`.

I have created 1 sample of Crossplane ytt function [here](). This sample only supports the `template` and not the `overlay` functionality of `ytt`.

### Test locally
To test the logic locally and iterate over it incrementally, use [crossplane beta render](https://docs.crossplane.io/latest/cli/command-reference/#beta-render). To test it locally, see thee example [here](https://github.com/rohitagg2020/function-ytt-templating/tree/main/example/render).

```shell
$ crossplane beta render xr.yaml composition.yaml function.yaml
```

### Build and push the function to a package registry 
Once we see that the `ytt` generates the expected `yaml` from the templated file, the next step is to build and push the function to a package registry.

You build a function in two stages. First, you build the function’s runtime. This is the Open Container Initiative (OCI) image Crossplane uses to run your function. You then embed that runtime in a package and push it to a package registry. 

```shell
# Build the function's runtime image - see Dockerfile
$ docker build . --tag=runtime
```

Use the Crossplane CLI to build a package.
```shell
# Build a function package - see package/crossplane.yaml
$ crossplane xpkg build -f package --embed-runtime-image=runtime
```

Push the function package to the repository.
```shell
$ crossplane xpkg push --package-files=package/function-ytt-templating-f58cf278b530.xpkg docker.io/rohitagg2020/function-ytt-templating
```

This function can now be used in composite resources.

{{< blog_footer >}}