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
Notice how the values for `name` and `environment` are duplicated in `deployment_name`. 
```yaml
name: frontend
environment: dev
deployment_name: frontend_dev
```

To improve the maintainability of this code, we extract these values in Starlark variables using ytt annotations. 

[add some details about how starlark works in ytt]

[mention that `#!` is a ytt comment, and that yaml comments won't work]

```yaml
#! config.yml
#@ name = frontend
#@ env = dev
name: #@ name
environment: #@ env
deployment_name: #@ name + "_" + env
label: #@ name + "_" + env
```

### Starlark functions
[Functions](lang-ref-def.md) provide a way to extract common code into a data into a template. 

[we need a more complelling use case for a function, currently our example can be done with only variables. I added the `label` key for this.]

We have duplicated logic in our code: `#@ name + "_" + env` appears multiple times. Let's place that in a function.
```yaml
#! config.yml
#@ def calc_name(name, env):
#@   return name + "_" + env
#@ end

#@ name = "frontend"
#@ env = "dev"
name: #@ name
env: #@ env
deployment_name: #@ calc_name(name, env)
label: #@ calc_name(name, env)
```

### YAML fragment functions

[[open question] I did not write this section yet. Our example doesn't have a use case for this either, but it is just another way to write a function so maybe we want to put it here]

Execute this template by running `ytt -f config.yml`.

[explain what is happening]

The result is identical to our original yaml:
```yaml
name: frontend
env: dev
deployment_name: frontend_dev
```

---
## Externalize a value with data values schema

Use [Data values schema](how-to-write-schema.md) to externalize a configuration value. When externalizing a value, you can also set a default value for it, and provide implicit or explicit type validation. Data values schema are used by configuration authors to declare a data value it as an input to templates by naming it in a schema file. It can then be used in templates, and configuration consumers can modify it by providing a separate [Data Value](how-to-use-data-values.md) file.

In this case, `name` and `env` are values we want as data values input, so that we can easily change them for different environments.

```yaml
#! schema.yml
#@data/values-schema
---
name: "frontend" #! implicitly ensures that any value for 'name' must be a string
env: "dev"       #! implicitly ensures that any value for 'env' must be a string
```

```yaml
#! config.yml
#@ load("@ytt:data", "data")
---
name: #@ data.values.name
env: #@ data.values.env
deployment_name: #@ calc_name(data.values.name, data.values.env)
label: #@ calc_name(data.values.name, data.values.env)
```
Execute ytt via `ytt -f config.yml -f schema.yml`.

[explain what data values are best used for]

[mention that data values should only be used for values that should be set by a configuration consumer]

## Starlark and library modules

Starlark modules are used to extract code into a module that can be imported into templates. Starlark modules are Starlark files with `.star` extension. Library modules use `.lib.yml` extension. These two files are imported indentically, and the main difference is that Starlark modules contain pure starlark, and library modules are YAML structures with Starlark code contained in `#@` annotations, just like the code we have seen thus far.

Now, we can move our `calc_name()` function to a shared file. 

```yaml
#! values.star
def calc_name(name, env):
  return name + "_" + env
end
```
Import the function by loading it `load("values.star", "calc_name")` ...

[Explain how load works here. What is the first param, and what is the second?]

```yaml
#! config.yml
#@ load("values.star", "calc_name")
#@ load("@ytt:data", "data")
---
name: #@ data.values.name
env: #@ data.values.env
deployment_name: #@ calc_name(data.values.name, data.values.env)
label: #@ calc_name(data.values.name, data.values.env)
```

```yaml
#! schema.yml
#@data/values-schema
---
name: "frontend" #! implicitly ensures that any value for 'name' must be a string
env: "dev"       #! implicitly ensures that any value for 'env' must be a string
```
Execute ytt via `ytt -f config.yml -f values.star -f schema.yml`

[[open question] Currently this example only uses a `.star` file, do we want to also show how to use a `.lib.yml` file?]

[[open question] We may want to add an example of how to export multiple functions from a module here. That is once our example has a use case for it.]

## Built-in ytt library module
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
* When you have a shared template used by two different applications like frontend and backend, there is a need to update one application with an evaluated value from the other. [Playground example here](https://carvel.dev/ytt/#example:example-ytt-library-module).

[This ^ section is missing some detail on how these libraries are helpful]

We want to place our function `calc_name()` in a library, we can add it under the `_ytt_lib` directory so that it can be easily imported using the name of the folder it is in: `library.get("helper_func")`.

[Our example is lacking of a real life reason to be used in a library here]

[Mention that in order to import a function from a file in a private library, it must be named .lib.yml or .star.]

```yaml
#! _ytt_lib/helper_func/config.lib.yml 

#@ def calc_name(name, env):
#@   return name + "_" + env
#@ end
```

```yaml
#! config.yml
#@ load("@ytt:library", "library")
#@ load("@ytt:data", "data")
---
#@ default_app = library.get("helper_func")

name: #@ data.values.name
env: #@ data.values.env
deployment_name: #@ default_app.export("calc_name")(data.values.name, data.values.env)
label: #@ default_app.export("calc_name")(data.values.name, data.values.env)
```
```yaml
#! schema.yml
#@data/values-schema
---
name: "frontend"
env: "dev"
```
Run ytt with `.` to include all files in this directory.

```shell
$ ytt -f .
```
The result is:
```yaml
name: frontend
env: dev
deployment_name: frontend_dev 
```

