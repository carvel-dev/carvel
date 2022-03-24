---
title: Modularity in ytt
---

## Overview

ytt offers a few approaches to code reuse: simple functions and variables, starlark modules, data values, or a private library.

When users of `ytt` need to reuse code across more than one file, a common question that arises is, “Which approach I would choose, data values, function, starlark module or a private library?” While these features do address a similar
problem space, we recommend using one feature versus the other depending on the
use case. We will detail our guidance below.

## Starlark variables and functions
### Variables
Notice how the values for `name`, `labels` are duplicated.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
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
    metadata:
      labels:
        app.kubernetes.io/version: 0.1.0
        app.kubernetes.io/name: frontend
    spec:
      containers:
        - name: frontend
          image: user/frontend
```
To improve the maintainability of this code, we extract these values in Starlark variables using ytt annotations. 

[add some details about how starlark works in ytt]

[mention that `#!` is a ytt comment, and that yaml comments won't work]

```yaml
#! config.yml
#@ name = "frontend"
#@ namespace = "default"
#@ replicas = 1

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ name
  namespace: #@ namespace
  labels:
    app.kubernetes.io/version: 0.1.0
    app.kubernetes.io/name: #@ name
spec:
  selector:
    matchLabels:
      app: #@ name
  replicas: #@ replicas
  template:
    metadata:
      labels:
        app.kubernetes.io/version: 0.1.0
        app.kubernetes.io/name: #@ name
    spec:
      containers:
        - name: #@ name
          image: user/frontend
```
Execute this template by running `ytt -f config.yml`.
The result looks like the original template.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
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
    metadata:
      labels:
        app.kubernetes.io/version: 0.1.0
        app.kubernetes.io/name: frontend
    spec:
      containers:
        - name: frontend
          image: user/frontend
```
### Starlark functions
[Functions](lang-ref-def.md) provide a way to extract common code into a seperate executable fragment/code snippet.

[we need a more complelling use case for a function, currently our example can be done with only variables. I added the `label` key for this.]

Limitation:
We have duplicated logic using starlark variables in our code. Let's place that in a function.
```yaml
#! config.yml

#@ name = "frontend"
#@ namespace = "default"
#@ replicas = 1

#@ def labels():
#@   return ["app.kubernetes.io/component: controller","app.kubernetes.io/name:"]
#@ end

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ name
  namespace: #@ namespace
  labels: #@ labels()
spec:
  selector:
    matchLabels:
      app: #@ name
  replicas: #@ replicas
  template:
    metadata:
      labels: #@ labels()
    spec:
      containers:
        - name: #@ name
          image: user/frontend
```
Execute this template by running `ytt -f config.yml`.
The result looks like the original template.

### YAML fragment functions

[[open question] I did not write this section yet. Our example doesn't have a use case for this either, but it is just another way to write a function so maybe we want to put it here]

Execute this template by running `ytt -f config.yml`.

[explain what is happening]

The result is identical to our original yaml:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: default
  labels:
    - 'app.kubernetes.io/component: controller'
    - 'app.kubernetes.io/name:'
spec:
  selector:
    matchLabels:
      app: frontend
  replicas: 1
  template:
    metadata:
      labels:
        - 'app.kubernetes.io/component: controller'
        - 'app.kubernetes.io/name:'
    spec:
      containers:
        - name: frontend
          image: user/frontend

```

---
## Externalize a value with data values schema

Use [Data values schema](how-to-write-schema.md) to externalize a configuration value. When externalizing a value, you can also set a default value for it, and provide implicit or explicit type validation. Data values schema are used by configuration authors to declare a data value it as an input to templates by naming it in a schema file. It can then be used in templates, and configuration consumers can modify it by providing a separate [Data Value](how-to-use-data-values.md) file.

In this case, `name`, `namespace` and `replicas` are values we want as data values input, so that we can easily change them for different applications.

```yaml
#! schema.yml
#@data/values-schema
---
#! implicitly ensures that any value for 'frontend' must be a string
name: "frontend"
namespace: "default"
replicas: 1
```

```yaml
#! config.yml
---
#@ load("@ytt:data", "data")

#@ def labels():
#@   return ["app.kubernetes.io/component: controller","app.kubernetes.io/name:"]
#@ end

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ data.values.name
  namespace: #@ data.values.namespace
  labels: #@ labels()
spec:
  selector:
    matchLabels:
      app: frontend
  replicas: #@ data.values.replicas
  template:
    metadata:
      labels:  #@ labels()
    spec:
      containers:
        - name: frontend
          image: user/frontend
```
Execute ytt via `ytt -f config.yml -f schema.yml`.

[explain what data values are best used for]
[Limitation of this approach is function is part of same config can be externalized to use with multip[le configs]]
[mention that data values should only be used for values that should be set by a configuration consumer]

## Starlark and library modules

Starlark modules are used to extract code into a module that can be imported into templates. Starlark modules are Starlark files with `.star` extension.
Library modules use `.lib.yml` extension. These two files are imported indentically, and the main difference is that Starlark modules contain pure starlark, and library modules are YAML structures with Starlark code contained in `#@` annotations, just like the code we have seen thus far.

Now, we can move our `labels()` function to a shared file.

```yaml
#! values.star
def labels():
   return ["app.kubernetes.io/component: controller","app.kubernetes.io/name:"]
end
```
Import the function by loading it `load("values.star", "labels")` ...

[Explain how load works here. What is the first param, and what is the second?]

```yaml
#! config.yml
---
#@ load("@ytt:data", "data")
#@ load("values.star", "labels")

apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ data.values.name
  namespace: #@ data.values.namespace
  labels: #@ labels()
spec:
  selector:
    matchLabels:
      app: frontend
  replicas: #@ data.values.replicas
  template:
    metadata:
      labels:  #@ labels()
    spec:
      containers:
        - name: frontend
          image: user/frontend
```

```yaml
#! schema.yml
#@data/values-schema
---
#! implicitly ensures that any value for 'frontend' must be a string
name: "frontend"
namespace: "default"
replicas: 1
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
4. 
[This ^ section is missing some detail on how these libraries are helpful]

We want to place our function `labels()` in a library, we can add it under the `_ytt_lib` directory so that it can be easily imported using the name of the folder it is in: `library.get("helper_func")`.

[Our example is lacking of a real life reason to be used in a library here]

[Mention that in order to import a function from a file in a private library, it must be named .lib.yml or .star.]

```yaml
#! _ytt_lib/app/config.yml
#@ load("@ytt:data", "data")

#@ def app_labels():
#@ return ["app.kubernetes.io/component: controller","app.kubernetes.io/name:"]
#@ end

#@ def labels():
app: #@ data.values.name
#@ end

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: #@ data.values.name
  namespace: #@ data.values.namespace
  labels: #@ app_labels()
spec:
  selector:
    matchLabels: #@ labels()
  replicas: #@ data.values.replicas
  template:
    metadata:
      labels: #@ app_labels()
    spec:
      containers:
        - name: default
          image: #@ data.values.image
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
  selector: #@ labels()

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
The result is the same as our original template:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: default
  labels:
    - 'app.kubernetes.io/component: controller'
    - 'app.kubernetes.io/name:'
spec:
  selector:
    matchLabels:
      app: backend
  replicas: 1
  template:
    metadata:
      labels:
        - 'app.kubernetes.io/component: controller'
        - 'app.kubernetes.io/name:'
    spec:
      containers:
        - name: default
          image: user/backend
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
    - 'app.kubernetes.io/component: controller'
    - ' app.kubernetes.io/name:'
spec:
  selector:
    matchLabels:
      app: frontend
  replicas: 1
  template:
    metadata:
      labels:
        - 'app.kubernetes.io/component: controller'
        - ' app.kubernetes.io/name:'
    spec:
      containers:
        - name: default
          image: user/frontend
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

