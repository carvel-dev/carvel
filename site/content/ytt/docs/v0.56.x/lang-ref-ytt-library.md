---
aliases: [/ytt/docs/latest/lang-ref-ytt-library]
title: Library Module
---

## Overview

You can extract a whole set of input files (i.e. templates, overlays, data values, etc.) into a "Library".

For example:

```yaml
config/
├── _ytt_lib/
│   └── frontend/
│       ├── schema.yml
│       └── store.yml
└── config.yml
```
where:
- `config/_ytt_lib/frontend/` and its contents is a library named `"frontend"`

Libraries are _not_ automatically included in `ytt` output; one must programmatically load, configure, evaluate, and insert those results into a template that is part of the output.

```yaml
#! config/config.yml -- example of using a library

#@ load("@ytt:library", "library")
#@ load("@ytt:template", "template")

#! 1. Load an instance of the library
#@ app = library.get("frontend")

#! 2. Create a configured copy of the library (does not mutate original)
#@ app_with_vals = app.with_data_values({"apiDomain": "gateway.example.com"})

#! 3. Evaluate the library and include results (a document set) in the output
--- #@ template.replace(app_with_vals.eval())
```

For a complete working example, see [ytt-library-module example](/ytt/#example:example-ytt-library-module).

## What is a Library?

A `ytt` library is a directory tree contained within a specially-named directory: [`_ytt_lib/`](lang-ref-load.md#_ytt_lib-directory).
- The library's _name_ is the path relative from the `_ytt_lib/` directory.
- The library's _contents_ are those of the directory along with subdirectories, recursively.
- A library may contain libraries as well, if one of its subdirectories is `_ytt_lib/`.

The root directory of a `ytt` invocation is itself a library known as the "root library".

Libraries are evaluated in isolation: each a separate execution of the pipeline described in [How it works](how-it-works.md).
- Each library has its own data values schema.
- Overlays within a library only apply over _its_ evaluated document set.
- The final evaluated result is returned as a [YAML Fragment wrapping a document set.](lang-ref-yaml-fragment.md#yaml-document-set).

---

## Functions

There's but one function in the `@ytt:library` module: [`library.get()`](#libraryget)

### library.get()

Contructs a new [`@ytt:library.instance`](#library-instances) based on the contents from the named library.

```python
instance = library.get(name, [<kwargs>])
```

- **`name`** (`string`) — path to the base directory of the desired library: `./_ytt_lib/<name>`. Can contain slashes `/` for sub-directories (e.g. `github.com/carvel-dev/ytt-library-for-kubernetes/app`)
- keyword arguments (optional):
  - **`alias=`** (`string`) — unique name for this library instance. See [Aliases](#aliases), below.
  - **`ignore_unknown_comments=`** (`bool`) — equivalent to `ytt --ignore-unknown-comments`; see [File Marks > type detection for YAML files](file-marks.md#type-detection-for-yaml-files) for more details (default: `False`). (as of v0.31.0)
  - **`implicit_map_key_overrides=`** (`bool`) — equivalent to `ytt --implicit-map-key-overrides`; see [@yaml/map-key-override](lang-ref-annotation.md#yaml-templating-annotations) for more details.  (default: `False`). (as of v0.31.0)
  - **`strict=`** (`bool`) — equivalent to `ytt --strict` (default: `False`). (as of v0.31.0)
- **`instance`** ([`@ytt:library.instance`](#library-instances)) — a new library instance backed by the contents of the named library.

The file containing this method invocation must be a sibling of the [`_ytt_lib` directory](lang-ref-load.md#_ytt_lib-directory).

---

## Library Instances

Each library returned from a function within this module is a copy: a separate instance.

A library instance (a value of type `@ytt:library.instance`) is created from source with [`library.get()`](#libraryget).

With a library instance:
- create configured copies using:
  - [`instance.with_data_values_schema()`](#instancewith_data_values_schema)
  - [`instance.with_data_values()`](#instancewith_data_values)
- evaluate its contents via [`instance.eval()`](#instanceeval)
- fetch values from it using:
  - [`instance.data_values()`](#instancedata_values) for the final data values for the library
  - [`instance.export()`](#instanceexport) to access its functions and variables

### instance.data_values()

Calculates and returns just the Data Values configured on this library instance.

```python
dvs = instance.data_values()
```

- **`dvs`** ([`struct`](lang-ref-structs.md)) — the final data values (i.e. the net result of [all configured data values](ytt-data-values.md#library-data-values)).

### instance.eval()

Calculates the library's final data values (i.e. the net result of [all configured data values](ytt-data-values.md#library-data-values)), evaluates its templates into a document set, and applies its overlays on that document set (i.e. executes the pipeline described in [How it works](how-it-works.md) for this library instance's inputs and contents. The output of that execution — rather than rendered automatically — is returned in a variable).

```python
document_set = instance.eval()
```

- **`document_set`** ([`yamlfragment`](lang-ref-yaml-fragment.md#yaml-document-set)) — the YAML document set resulting from the evaluation of this instance.

Note: the resulting Document Set is _**not**_ automatically included in output. A common way to include this result in the output is to use [`template.replace()`](lang-ref-ytt-template.md#templatereplace):

```yaml
#@ load("@ytt:template", "template")
#@ load("@ytt:library", "library")

--- #@ template.replace(library.get("cert-manager").eval())
```

See also, [Playground: ytt library module](/ytt/#example:example-ytt-library-module) example.

### instance.export()

(As of v0.28.0)

Returns the value of an identifier declared within the library instance.

```python
value = instance.export(name, [path=])
```

- **`name`** (`string`) — the name of a function or a variable declared within some [module](lang-ref-load.md#terminology)/file in the library. (i.e. a file with the extension `.lib.yml` or `.star`).
- **`path=`** (`string`) — the path to the module/file that contains the declaration. Only required when `name` is not unique within the library.
- **`value`** (any) — a copy of the specified value.
  - if `value` is a function, it is executed within the context of _its_ library instance. For example, if the function depends on values from the [`@ytt:data`](lang-ref-ytt.md#data) module, the values provided are those of this library instance.

**Examples:**

_Example 1: Exporting a function from a library._

Assuming some module/file in the "helpers" library contains the definition:

```python
...
def wrap_name(name):
   ...
end
...
```

Can be exported and used from another library:

```python
helpers = library.get("helpers")
wrap_name = helpers.export("wrap_name")

full_name = wrap_name("app")
```

_Example 2: Disambiguating between multiple declarations of function._

Assuming two modules/files in the "helpers" library have the same name:

```python
# main/funcs.star
def wrap_name(name): ...
```
and
```python
# lib/funcs.star
def wrap_name(name): ...
```

One of which can be unambiguously referenced:

```python
helpers = library.get("helpers")
wrap_name = helpers.export("wrap_name", path="lib/funcs.star")

full_name = wrap_name("app")
```

Note: without the `path=` keyword argument, `helpers.export()` would report an error.

### instance.with_data_values()

Returns a copy of the library instance with data values overlayed with those given.

```python
new_instance = instance.with_data_values(dvs, [plain=])
```

- **`dvs`** (`struct` | [`yamlfragment`](lang-ref-yaml-fragment.md)) — data values with which to overlay (or set, if none exist).
  - only `yamlfragment`s wrapping a map or an array are supported (i.e. `yamlfragment`s wrapping document sets are not supported).
  - `yamlfragment` values _can_ contain [overlay annotations](lang-ref-ytt-overlay.md#overlay-annotations) for fine-grained overlay control.
- **`plain=`** (`bool`) — when `True` indicates that `dvs` should be "plain merged" over existing data values (i.e. the exact same behavior as [`--data-values-file`](ytt-data-values.md#configuring-data-values-via-command-line-flags)).
  - `dvs` must be plain YAML (i.e. a `struct` or a `yamlfragment` with no annotations).
- **`new_instance`** ([`@ytt:library.instance`](#library-instances)) — a copy of `instance` with `dvs` overlayed on its data values; `instance` remains unchanged.

### instance.with_data_values_schema()

(As of v0.35.0)

Returns a copy of the library instance with data values schema overlayed with that given.

```python
new_instance = instance.with_data_values_schema(schema)
```

- **`schema`** (`struct` | [`yamlfragment`](lang-ref-yaml-fragment.md)) — schema for data values with which to overlay on existing schema (or set if none exist).
  - only `yamlfragment`s wrapping a map or an array are supported (i.e. `yamlfragment`s wrapping document sets are not supported)
  - `yamlfragment` values _can_ contain [overlay annotations](lang-ref-ytt-overlay.md#overlay-annotations) for fine-grained overlay control.
- **`new_instance`** ([`@ytt:library.instance`](#library-instances)) — a copy of `instance` with a schema updated with `schema`; `instance` remains unchanged.

**Examples:**

_Example 1: Declaring a new data value (and setting it)._

```yaml
#@ def app_schema():
name: ""
#@overlay/match missing_ok=True
env_vars:
  custom_key: ""
#@ end

#@ app1_with_schema = app1.with_data_values_schema(app_schema())
---
#@ def app_vals():
name: app1
env_vars:
  custom_key: some_val
#@ end

#@ app1_with_vals = app1.with_data_values(app_vals())
```

---

## Annotations

### @library/ref

(As of v0.28.0)

Attaches a YAML document to the specified library. When the library is evaluated, the annotated document is included.
Only supported on documents annotated with `@data/values` and `@data/values-schema`.

```
@library/ref library_name
```
- **`library_name`** (`string`) — `@`-prefixed path to the base directory of the desired library: `./_ytt_lib/<name>`. Can contain slashes `/` for sub-directories (e.g. `github.com/carvel-dev/ytt-library-for-kubernetes/app`). Can also be an [alias](#aliases) for specific library instance(s).

**Examples:**

_Example 1: Change schema default for a data value in a library._

```yaml
#@data/values-schema
#@library/ref "@frontend"
---
name: "custom"
```

Overlays the default value for `name` in the "frontend" library to be "custom".

_Example 2: Target a data value overlay to a library._

```yaml
#@data/values
#@library/ref "@backend"
---
#@overlay/replace
domains:
- internal.example.com
- internal-backup.example.com
```

Sets the "backend" library's `domains` data value to be exactly the values given.

See also: [Data Values > Setting Library Values via Files](ytt-data-values.md#setting-library-values-via-files).

Note: data values may also be attached to libraries via [command line flags](ytt-data-values.md#setting-library-values-via-command-line-flags).

---

## Aliases

To facilitate configuring specific library instances, one can mark them with an alias.

An alias:
- is defined in a [`library.get()`](#libraryget) call, using the optional `alias=` keyword argument.
- is added to a library reference by prefixing it with a tilde, `~`:
  - `@~<alias-name>` refers to _any_ library instance with the alias.
  - `@<library-name>~<alias-name>` refers to any instance of the named library that _also_ has the alias.

For example, given a library known as "fruit":

```
├── apple-values.yml
├── config.yml
├── orange-values.yml
└── _ytt_lib
    └── fruit
        ├── doc.yml
        └── values.yml
```

where:
```yaml
#! _ytt_lib/fruit/doc.yml

#@ load("@ytt:data", "data")
--- #@ data.values
```
the template in the library simply returns its data values as a document, and ...
```yaml
#! _ytt_lib/fruit/values.yml

#@data/values
---
variety: ordinary
poisoned: false
```
... those are the data values in the library.

The root library can assign aliases to library instances:

```yaml
#! ./config.yml

#@ load("@ytt:library", "library")

#@ apple1 = library.get("fruit", alias="apple")
#@ apple2 = apple1.with_data_values({"variety": "jonamac"})

#@ orange = library.get("fruit", alias="orange")

---
apple:
  1: #@ apple1.eval()[0]
  2: #@ apple2.eval()[0]
orange: #@ orange.eval()[0]
```
where:
- `apple1` has the alias "apple"
- `apple2` also has the alias "apple" (part of being a copy of `apple1`)
- `orange` has the alias "orange"

These aliases can be used to target changes to specific library instance(s).

For example, our root library has these two data values overlays:

```yaml
#! ./apple-values.yml

#@data/values
#@library/ref "@~apple"
---
variety: red delicious
poisoned: true
```
... which will affect all library instances with the alias "apple", and ...

```yaml
#! ./orange-values.yml

#@data/values
#@library/ref "@~orange"
---
variety: valencia
```

... overlays on top of library instance with the alias "orange".

When the whole fileset is evaluated, the result is:

```yaml
apple:
  1:
    variety: red delicious
    poisoned: true
  2:
    variety: jonamac
    poisoned: true
orange:
  variety: valencia
  poisoned: false
```

notice:
- only the "@~orange" instance has the variety = "valencia"
- both "@~apple" library instances are poisoned; while the "orange" instance is not.
