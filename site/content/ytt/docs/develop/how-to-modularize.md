---
title: Getting started
---

## Overview

Configuration authors looking for examples of how to use functions and variables, [modules](/ytt/docs/develop/lang-ref-load/#files), [data values schema](/ytt/docs/develop/how-to-write-schema/), or a [custom library](/ytt/docs/develop/lang-ref-ytt-library/), will see concrete examples in this guide. Language reference introduces concepts of basic syntax like ytt directives and ytt annotations [definitions](/ytt/docs/develop/faq/#when-should-i-include-a-space-in-my-ytt-comment-does-it-matter-is-it-load-or--load-overlaymatch-or--overlaymatch) (ie:`#@`). See the ytt playground ['getting started'](/ytt/#example:example-hello-world) section for additional examples.

## Variable and function reuse

A foundational concept in ytt is using Starlark code to create variables or functions. Inside a YAML file, prefix Starlark code with a ytt annotation `#@ ` (including a space afterwards) to use it inline.

### Starlark variables
In the code block below there are duplicated values for `name: frontend`, and other values that we may want to modify often.

```yaml
#! config.yml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: default
  labels:
    app.kubernetes.io/version: 0.1.0
    app.kubernetes.io/name: frontend
spec:
  selector:
    matchLabels:
      app: frontend
  replicas: 1
  template:
    spec:
      containers:
        - name: frontend
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  labels:
    app.kubernetes.io/version: 0.1.0
    app.kubernetes.io/name: frontend
spec:
  type: ClusterIP
  ports:
    - port: 80
```

_(This is a ytt comment `#!`, use these instead of YAML comments `#` which are [discouraged](/ytt/docs/develop/faq/#why-is-ytt-complaining-about-unknown-comment-syntax-cant-i-write-standard-yaml-comments-) to ensure that all comments are intentional. Comments will be consumed during execution.)_

Using Starlark's Python-like syntax, extract these values into Starlark variables. All the code defined here can be used in the same file.

```yaml
#! config.yml

#@ name = "frontend"
#@ namespace = "default"
#@ version = "0.1.0"
#@ replicas = 1

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ name + "-deployment"
  namespace: #@ namespace
  labels:
    app.kubernetes.io/version: #@ version
    app.kubernetes.io/name: #@ name
spec:
  selector:
    matchLabels:
      app: #@ name
  replicas: #@ replicas
  template:
    spec:
      containers:
        - name: #@ name
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
---
apiVersion: v1
kind: Service
metadata:
  name: #@ name + "-service"
  labels:
    app.kubernetes.io/version: #@ version
    app.kubernetes.io/name: #@ name
spec:
  type: ClusterIP
  ports:
    - port: 80
```
Execute this template by running `ytt -f config.yml`.

The result is identical to our original template, and now we can be sure all our repeated values will be consistent and easier to modify.

### Functions
[Functions](lang-ref-def.md) provide a way to extract common code into a separate fragment or code snippet.

There are two ways to define a function in ytt: as a Starlark function; as a YAML fragment function.

[Starlark functions](https://github.com/google/starlark-go/blob/master/doc/spec.md#functions) make use of a `return` statement. Because of this they can be great for returning a value that must be transformed in some way.

[YAML fragment functions](lang-ref-yaml-fragment/#docs) differ in that they are YAML structure wrapped in a Starlark function definition. Everything inside the function will be the return value. They can be great when needing to return nested YAML structure, or key and value pairs.

Going back to the previous solution, we can see each `labels` key is duplicated YAML, like `app.kubernetes.io/version: #@ version`. There is also some duplicated string manipulation in the `metadata.name` key.
```yaml
#! config.yml

#@ name = "frontend"
#@ namespace = "default"
#@ version = "0.1.0"
#@ replicas = 1

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ name + "-deployment"
  namespace: #@ namespace
  labels:
    app.kubernetes.io/version: #@ version
    app.kubernetes.io/name: #@ name
spec:
  selector:
    matchLabels:
      app: #@ name
  replicas: #@ replicas
  template:
    spec:
      containers:
        - name: #@ name
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
---
apiVersion: v1
kind: Service
metadata:
  name: #@ name + "-service"
  labels:
    app.kubernetes.io/version: #@ version
    app.kubernetes.io/name: #@ name
spec:
  type: ClusterIP
  ports:
    - port: 80
```

Move the duplicated `labels` keys into a YAML fragment function, and move name formatting into a Starlark function.

```yaml
#! config.yml

#@ name = "frontend"
#@ namespace = "default"
#@ version = "0.1.0"
#@ replicas = 1

#! Starlark function
#@ def fmt(name, type):
#@   return "{}-{}".format(name, type)
#@ end

#! YAML fragment function 
#@ def labels(name, version):
app.kubernetes.io/version: #@ version
app.kubernetes.io/name: #@ name
#@ end

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ fmt(name, "deployment")
  namespace: #@ namespace
  labels: #@ labels(name, version)
spec:
  selector:
    matchLabels:
      app: #@ name
  replicas: #@ replicas
  template:
    spec:
      containers:
        - name: #@ name
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
---
apiVersion: v1
kind: Service
metadata:
  name: #@ fmt(name, "service")
  labels: #@ labels(name, version)
spec:
  type: ClusterIP
  ports:
    - port: 80
```
Execute this template by running `ytt -f config.yml`.
Again, the result is identical to our original template, and we can be sure all our repeated sections of YAML will be consistent.

---
## Externalize a value with data values schema

Use [Data values schema](how-to-write-schema.md) to externalize a configuration value. When externalizing a value, you can also set a default value for it, and provide implicit type validation. Data values schema are used by configuration authors to declare a data value as an input to templates by naming it in a schema file. It can then be used in templates, and configuration consumers can modify it by providing a separate [Data Value](how-to-use-data-values.md) file.

Building on the previous solution, `name`, `namespace`, `version`, and `replicas` are values we want as data values input, so that we can easily change them for different applications or environments.

```yaml
#! schema.yml
#@data/values-schema
---
name: "frontend"     #! ensures that any value for 'name' must be a string
namespace: "default" #! ensures that any value for 'namespace' must be a string
version: "0.1.0"     #! ensures that any value for 'version' must be a string
replicas: 1          #! ensures that any value for 'replicas' must be a int
```
```yaml
#! config.yml

#@ load("@ytt:data", "data")

#@ def fmt(name, type):
#@   return "{}-{}".format(name, type)
#@ end

#@ def labels(name, version):
app.kubernetes.io/version: #@ version
app.kubernetes.io/name: #@ name
#@ end

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ fmt(data.values.name, "deployment")
  namespace: #@ data.values.namespace
  labels: #@ labels(data.values.name, data.values.version)
spec:
  selector:
    matchLabels:
      app: #@ data.values.name
  replicas: #@ data.values.replicas
  template:
    spec:
      containers:
        - name:  #@ data.values.name
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
---
apiVersion: v1
kind: Service
metadata:
  name: #@ fmt(data.values.name, "service")
  labels: #@ labels(data.values.name, data.values.version)
spec:
  type: ClusterIP
  ports:
    - port: 80
```

Execute ytt via `ytt -f config.yml -f schema.yml`.
The result is identical to our original template.

## Extract code into modules

Modules contain code in a file that can be imported and used in templates. 

Starlark modules have the `.star` extension.

YAML modules have the `.lib.yml` extension. 

These two files are imported identically. The main difference is that Starlark modules contain only Starlark code, and YAML modules are YAML structures with Starlark code contained in `#@` annotations, just like the code we have seen thus far.

### Starlark module
Following the last solution, move the `fmt()` function to a separate Starlark file.
```python
#! format.star

def fmt(name, type):
  return "{}-{}".format(name, type)
end
```
Import the module by loading it `#@ load("format.star", "fmt")`.

### YAML module
Move the `labels()` function to a separate YAML file.

```yaml
#! labels.lib.yml

#@ def labels(name, version):
app.kubernetes.io/version: #@ version
app.kubernetes.io/name: #@ name
#@ end
```
Import the module by loading it `#@ load("labels.lib.yml", "labels")`.

The load function takes a module file path, and secondly the name of the function or variable to export from the module. For multiple symbols, use a comma separated list of strings. If your module has many symbols that are usually all exported together, consider putting them in a [struct](faq/#can-i-load-multiple-functions-without-having-to-name-each-one), and load that struct.

```yaml
#! config.yml

#@ load("@ytt:data", "data")
#@ load("labels.lib.yml", "labels")
#@ load("format.star", "fmt")

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ fmt(data.values.name, "deployment")
  namespace: #@ data.values.namespace
  labels: #@ labels(data.values.name, data.values.version)
spec:
  selector:
    matchLabels:
      app: #@ data.values.name
  replicas: #@ data.values.replicas
  template:
    spec:
      containers:
        - name:  #@ data.values.name
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
---
apiVersion: v1
kind: Service
metadata:
  name: #@ fmt(data.values.name, "service")
  labels: #@ labels(data.values.name, data.values.version)
spec:
  type: ClusterIP
  ports:
    - port: 80
```

```yaml
#@data/values-schema
---
name: "frontend"
namespace: "default"
version: "0.1.0"
replicas: 1
```
```shell
$ tree .
.
├── config.yml
├── schema.yml
├── format.star
└── labels.lib.yml
```

Execute ytt via `ytt -f .` to include all files in this directory.

## Extract functionality into custom library
You can extract a whole set of input files (i.e. templates, overlays, data values, etc.) into a "Library" in the `_ytt_lib/` folder. A library can be thought of as a separate self-contained ytt invocation. Libraries are _not_ automatically included in `ytt` output. They must be programmatically imported using the [`library` module](/ytt/docs/develop/lang-ref-ytt-library/), configured, evaluated, and inserted into a template that is part of the output.

### Uses of a custom library
Libraries are helpful when
* importing 3rd party configuration into one combined piece of configuration. Such as from a division of responsibility or shared configuration.
  * For example, having a library that provides helpful functions that needs to be used across multiple teams. Authors may use a tool to ensure these stay in sync.
* A template is needed by two distinct applications like frontend and backend.
* There is a need to update one application with an evaluated value from the other. [Playground example here](/ytt/#example:example-ytt-library-module).

All the previous section's files have moved to `_ytt_lib/resources`:

```shell
config/
$ tree .
├── _ytt_lib/
│   └── resources/
│       ├── config.yml
│       ├── schema.yml
│       ├── labels.lib.yml
│       └── format.star
├── config.yml
└── values.yml
```
In this example we want the resources from the library for a frontend application, and also for a backend application. We will use this library to create both of these.

Focusing on only the two top level files, `config.yml`, and `values.yml`, we import the custom library, provide it data values for a frontend and separately for a backend, and use `#@ template.replace()` to insert it inline so it shows in the output.

```yaml
#! config.yml
#@ load("@ytt:data", "data")
#@ load("@ytt:library", "library")
#@ load("@ytt:template", "template")

#@ resources_lib = library.get("resources")
#@ backend = resources_lib.with_data_values(data.values.backend)
#@ frontend = resources_lib.with_data_values(data.values.frontend)

--- #@ template.replace(backend.eval())
--- #@ template.replace(frontend.eval())
```
Provide the values that we pass to the library.
```yaml
#@data/values-schema
---
frontend:
  name: "frontend"
  namespace: "dev"
  replicas: 1
  version: "0.5.0"
backend:
  name: "backend"
  namespace: "dev"
  replicas: 1
  version: "0.2.0"
```

Run ytt with `.` to include all files in this directory.

```shell
$ ytt -f .
```
The result is the similar to  our original template with resources configured for two different applications.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: dev
  labels:
    app.kubernetes.io/version: 0.2.0
    app.kubernetes.io/name: backend
spec:
  selector:
    matchLabels:
      app: backend
  replicas: 1
  template:
    spec:
      containers:
        - name: backend
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  labels:
    app.kubernetes.io/version: 0.2.0
    app.kubernetes.io/name: backend
spec:
  type: ClusterIP
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: dev
  labels:
    app.kubernetes.io/version: 0.5.0
    app.kubernetes.io/name: frontend
spec:
  selector:
    matchLabels:
      app: frontend
  replicas: 1
  template:
    spec:
      containers:
        - name: frontend
          image: index.docker.io/k14s/image@sha256:6ab29951e0207fde6760f6db227f218f20e875f45b22e8ca0ee06c0c8cab32cd
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  labels:
    app.kubernetes.io/version: 0.5.0
    app.kubernetes.io/name: frontend
spec:
  type: ClusterIP
  ports:
    - port: 80
```

