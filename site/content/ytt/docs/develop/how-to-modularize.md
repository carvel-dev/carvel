---
title: Modularity in ytt
---

## Overview

ytt offers a few approaches to code reuse: simple functions and variables, starlark modules, data values, or a private library.

## Simple variable and function reuse

A foundational concept in ytt is using Starlark code to create variables or functions. Inside a YAML file, prefix Starlark code with `#@ ` (including a space afterwards) to use it inline.

### Starlark variables
In the code block below there are duplicated values for `name: frontend`, and other values that we may want to modify often.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: default
  labels:
    - app.kubernetes.io/version: 0.1.0
    - app.kubernetes.io/name: frontend
spec:
  selector:
    matchLabels:
      app: frontend
  replicas: 1
  template:
    metadata:
      labels:
        - app.kubernetes.io/version: 0.1.0
        - app.kubernetes.io/name: frontend
    spec:
      containers:
        - name: frontend
          image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  labels:
    - app.kubernetes.io/version: 0.1.0
    - app.kubernetes.io/name: frontend
spec:
  type: ClusterIP
  ports:
    - port: 38080
      targetPort: 8080
```

Extract these values into Starlark variables. Starlark is a Python-like language. The code defined can be used in the same file.

This is a ytt comment `#!`, use these instead of YAML comments `#` which are discouraged to ensure that all comments are intentional. ytt comments will be consumed during execution.

```yaml
#! config.yml

#@ name = "frontend"
#@ namespace = "default"
#@ replicas = 1
#@ version = 0.1.0

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ name + "-deployment"
  namespace: #@ namespace
  labels:
    - app.kubernetes.io/version: #@ version
    - app.kubernetes.io/name: #@ name
spec:
  selector:
    matchLabels:
      app: #@ name
  replicas: #@ replicas
  template:
    metadata:
      labels:
        - app.kubernetes.io/version: #@ version
        - app.kubernetes.io/name: #@ name
    spec:
      containers:
        - name: #@ name
          image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
---
apiVersion: v1
kind: Service
metadata:
  name: #@ name + "-service"
  labels:
    - app.kubernetes.io/version: #@ version
    - app.kubernetes.io/name: #@ name
spec:
  type: ClusterIP
  ports:
    - port: 38080
      targetPort: 8080
```
Execute this template by running `ytt -f config.yml`.

The result is identical to our original template, and we can be sure all our repeated values will be consistent and easier to modify.

### Functions
[Functions](lang-ref-def.md) provide a way to extract common code into a separate executable fragment/code snippet.

There are two ways to define a function in ytt, a Starlark function, or a yaml fragment function. We will use both here.

Starlark functions make use of a `return` statement. Because of this they can be great for returning a value that must be transformed in some way.

YAML fragment functions differ in that they are YAML structure wrapped in a Starlark function definition. Everything inside the function will be the return value. They can be great when needing to return nested YAML structure, or key and value pairs.

Going back to the previous solution, we can see each `labels` key is duplicated YAML, like `app.kubernetes.io/version: #@ version`.
```yaml
#! config.yml

#@ name = "frontend"
#@ namespace = "default"
#@ version = 0.1.0
#@ replicas = 1

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ name + "-deployment"
  namespace: #@ namespace
  labels:
    - app.kubernetes.io/version: #@ version
    - app.kubernetes.io/name: #@ name
spec:
  selector:
    matchLabels:
      app: #@ name
  replicas: #@ replicas
  template:
    metadata:
      labels:
        - app.kubernetes.io/version: #@ version
        - app.kubernetes.io/name: #@ name
    spec:
      containers:
        - name: #@ name
          image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
---
apiVersion: v1
kind: Service
metadata:
  name: #@ name + "-service"
  labels:
    - app.kubernetes.io/version: #@ version
    - app.kubernetes.io/name: #@ name
spec:
  type: ClusterIP
  ports:
    - port: 38080
      targetPort: 8080
```

Move the duplicated `labels` keys into a YAML fragment function, and move name calculation into a Starlark function.

```yaml
#! config.yml

#@ name = "frontend"
#@ namespace = "default"
#@ version = "0.1.0"
#@ replicas = 1

#! Starlark function

#@ def fmt_name(name, type):
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
  name: #@ fmt_name(name, "deployment)
  namespace: #@ namespace
  labels: #@ labels(name, version)
spec:
  replicas: #@ replicas
  template:
    spec:
      containers:
        - name: #@ name
          image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
---
apiVersion: v1
kind: Service
metadata:
  name: #@ fmt_name(name, "service")
  labels: #@ labels(name, version)
spec:
  type: ClusterIP
  ports:
    - port: 38080
      targetPort: 8080
```
Execute this template by running `ytt -f config.yml`.
Again, the result is identical to our original template, and we can be sure all our repeated sections of code will be consistent.

---
## Externalize a value with data values schema

Use [Data values schema](how-to-write-schema.md) to externalize a configuration value. When externalizing a value, you can also set a default value for it, and provide implicit or explicit type validation. Data values schema are used by configuration authors to declare a data value it as an input to templates by naming it in a schema file. It can then be used in templates, and configuration consumers can modify it by providing a separate [Data Value](how-to-use-data-values.md) file.

In this case, `name`, `namespace` and `replicas` are values we want as data values input, so that we can easily change them for different applications.

```yaml
#! schema.yml
#@data/values-schema
---
name: "frontend"
namespace: "default"
replicas: 1
version: 0.1.0
```
```yaml
#! config.yml
---
#@ load("@ytt:data", "data")

#@ def labels(name, version):
#@   return ["app.kubernetes.io/version: "+ version, "app.kubernetes.io/name: " + name]
#@ end

#@ def image(name):
#@   return ["user/"+ name]
#@ end

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ data.values.name
  namespace: #@ data.values.namespace
  labels: #@ labels(data.values.name, data.values.version)
spec:
  selector:
    matchLabels:
      app:  #@ data.values.name
  replicas: #@ data.values.replicas
  template:
    metadata:
      labels: #@ labels(data.values.name, data.values.version)
    spec:
      containers:
        - name:  #@ data.values.name
          image: #@ image(data.values.name)
```
Execute ytt via `ytt -f config.yml -f schema.yml`.
The result is identical to our original yaml.

[explain what data values are best used for]
[Limitation of this approach is that the function is part of same config can be externalized to use with multip[le configs]]
[mention that data values should only be used for values that should be set by a configuration consumer]

## Starlark and library modules

Starlark modules are used to extract code into a module that can be imported into templates. Starlark modules are Starlark files with `.star` extension.
Library modules use `.lib.yml` extension. These two files are imported indentically, and the main difference is that Starlark modules contain pure starlark, and library modules are YAML structures with Starlark code contained in `#@` annotations, just like the code we have seen thus far.

Now, we can move our `labels()` function to a shared file.

```yaml
#! values.star
def labels(name, version):
  return ["app.kubernetes.io/version: "+ version, "app.kubernetes.io/name: " + name]
end

def image(name):
  return ["user/"+ name]
end
```
Import the function by loading it `load("values.star", "labels")` ...

[Explain how load works here. What is the first param, and what is the second?]

```yaml
#! config.yml
---
#@ load("@ytt:data", "data")
#@ load("values.star", "labels", "image")

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ data.values.name
  namespace: #@ data.values.namespace
  labels: #@ labels(data.values.name, data.values.version)
spec:
  selector:
    matchLabels:
      app:  #@ data.values.name
  replicas: #@ data.values.replicas
  template:
    metadata:
      labels: #@ labels(data.values.name, data.values.version)
    spec:
      containers:
        - name:  #@ data.values.name
          image: #@ image(data.values.name)
```

```yaml
#@data/values-schema
---
#! implicitly ensures that any value for 'frontend' and `namespace`  must be a string
name: "frontend"
namespace: "default"
replicas: 1
version: 0.1.0
```
Execute ytt via `ytt -f config.yml -f values.star -f schema.yml`

[[open question] Currently this example only uses a `.star` file, do we want to also show how to use a `.lib.yml` file?]

When someone would prefer .lib.yml over .star?
1.One can only write sharable fragment functions in .lib.yml.
(There is no return statement)
2.star functions return values
functions that don't involve yaml processing


[[open question] We may want to add an example of how to export multiple functions from a module here. That is once our example has a use case for it.]

## private library
You can extract a whole set of input files (i.e. templates, overlays, data values, etc.) into a "Library" in the `_ytt_lib/` folder. A library or sometimes called a 'private library' can be thought of as a separate self-contained ytt invocation. Libraries are _not_ automatically included in `ytt` output. They must be programmatically loaded, configured, evaluated, and inserted into a template that is part of the output.

The directory structure may look like:

```shell
config/
$ tree .
├── _ytt_lib/
│   └── helper_func/
│       └── config.lib.yml
├── config.yml
└── schema.yml
```

Libraries can be helpful 
* to import configuration 3rd party sources, into one combined piece of configuration. Such as having one library per subproject. 
* Libraries can also be helpful for sharing configuration across multiple codebases. For example, having a generic library that provides helpful functions that needs to be used across multiple teams. (advanced detail: these libraries can be vendir'd into a project from one common place.)
* When you have a shared template used by two different applications like frontend and backend, a library can be used...
* Also it can provide additional capabilities like dynamically updating values in one template there is a need to update one application with an evaluated value from the other. [Playground example here](https://carvel.dev/ytt/#example:example-ytt-library-module).

1. more than 1 instance of collection of files 
more than 1 apps with common stuff similar template
2. overlays applying to certain set of files..pull files and overlays in private library so that they would be evaluated seperately.
3. In order to collect set of yamls that are about one component in a system of multiple components

[This ^ section is missing some detail on how these libraries are helpful]

We want to place our function `labels()` in a library, we can add it under the `_ytt_lib` directory so that it can be easily imported using the name of the folder it is in: `library.get("helper_func")`.

[Our example is lacking of a real life reason to be used in a library here]

[Mention that in order to import a function from a file in a private library, it must be named .lib.yml or .star.]

```yaml
#! _ytt_lib/app/config.yml
#@ load("@ytt:data", "data")

#@ def labels(name, version):
#@   return ["app.kubernetes.io/version: "+ version, "app.kubernetes.io/name: " + name]
#@ end

#@ def app_labels(name):
app: #@ name
#@ end

#@ def image(name):
#@   return ["user/"+ name]
#@ end
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ data.values.name
  namespace: #@ data.values.namespace
  labels: #@ labels(data.values.name, data.values.version)
spec:
  selector:
    matchLabels: #@ app_labels(data.values.name)
  replicas: #@ data.values.replicas
  template:
    metadata:
      labels: #@ labels(data.values.name, data.values.version)
    spec:
      containers:
        - name: default
          image: #@ image(data.values.name)
---
apiVersion: v1
kind: Service
metadata:
  name: #@ data.values.name
  namespace: #@ data.values.namespace
spec:
  ports:
    - port: #@ data.values.port
      protocol: TCP
  selector: #@ app_labels(data.values.name)
```
```yaml
#! _ytt_lib/app/schema.yml
#@data/values-schema
---
namespace: default
#@schema/nullable
name: app
replicas: 1
port: 80
#@schema/nullable
image: ""
version: 0.1.0
```
```yaml
#! config.yml
#@ load("@ytt:template", "template")
#@ load("@ytt:library", "library")
#@ load("@ytt:data", "data")

#@ default_app = library.get("app")

#@ def backend():
name: backend
image: user/backend
#@ end

#@ backend = default_app.with_data_values(backend())

#@ def frontend():
name: frontend
image: user/frontend
#@ end

#@ frontend = default_app.with_data_values(frontend())

--- #@ template.replace(backend.eval())
--- #@ template.replace(frontend.eval())
```
Run ytt with `.` to include all files in this directory.

```shell
$ ytt -f .
```
The result is the similar to  our original template with two different apps frontend and backend updated through library :
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: default
  labels:
    - 'app.kubernetes.io/version: 0.1.0'
    - 'app.kubernetes.io/name: backend'
spec:
  selector:
    matchLabels:
      app: backend
  replicas: 1
  template:
    metadata:
      labels:
        - 'app.kubernetes.io/version: 0.1.0'
        - 'app.kubernetes.io/name: backend'
    spec:
      containers:
        - name: default
          image:
            - user/backend
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: default
spec:
  ports:
    - port: 80
      protocol: TCP
  selector:
    app: backend
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: default
  labels:
    - 'app.kubernetes.io/version: 0.1.0'
    - 'app.kubernetes.io/name: frontend'
spec:
  selector:
    matchLabels:
      app: frontend
  replicas: 1
  template:
    metadata:
      labels:
        - 'app.kubernetes.io/version: 0.1.0'
        - 'app.kubernetes.io/name: frontend'
    spec:
      containers:
        - name: default
          image:
            - user/frontend
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: default
spec:
  ports:
    - port: 80
      protocol: TCP
  selector:
    app: frontend
```

