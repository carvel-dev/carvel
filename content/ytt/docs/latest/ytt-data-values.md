---
title: ytt @data/values
---

## Overview

The standard way to externalize configuration values is to declare them as "Data Values"
and then reference those values in templates.

_(For a high-level overview of `ytt`, see [How it works](how-it-works.md).)_

## Declaring and Using Data Values

A Data Values file is a YAML document annotated with `@data/values`.

```yaml
#@data/values
---
key1: val1
key2:
  nested: val2
key3: val3
key4:
```

`ytt` processes all Data Values files prior to rendering templates.

Templates can access those processed values via the `@ytt:data` module:

```yaml
#@ load("@ytt:data", "data")

first: #@ data.values.key1
second: #@ data.values.key2.nested
third: #@ data.values.key3
fourth: #@ data.values.key4
```

Resulting in

```yaml
first: val1
second: val2
third: val3
fourth: null
```

Note:
- Data Values keys must be strings.
- we recommend using snake-case for keys (e.g. `db_conn.secure`) — keys that contain a `-` (dash)
  cannot be accessed via the dot expression (the dash is the subtraction operator).
- if dashes cannot be avoided, use the Starlark built-in [`getattr()`](https://github.com/google/starlark-go/blob/master/doc/spec.md#getattr)
  to access the value:
    ```python
    secure: #@ getattr(data.values, "db-conn").secure
    ```
  _(as of v0.31.0)_ the same can be done with [index notation](lang-ref-structs.md#attributes):
    ```python
    secure: #@ data.values["db-conn"].secure
    ```
- `data.values` is a [`struct`](lang-ref-structs.md).
 
## Splitting data values into multiple files

Available in v0.13.0.

It's possible to split data values into multiple files (or specify multiple data values in the same file). `@ytt:data` library provides access to the _merged_ result. Merging is controlled via [overlay annotations](lang-ref-ytt-overlay.md) and follows same ordering as [overlays](lang-ref-ytt-overlay.md#overlay-order). Example:

`values-default.yml`:

```yaml
#@data/values
---
key1: val1
key2:
  nested: val2
key3:
key4:
```

`values-production.yml`:

```yaml
#@data/values
---
key3: new-val3
#@overlay/remove
key4:
#@overlay/match missing_ok=True
key5: new-val5
```

Note that `key4` is being removed, and `key5` is marked as `missing_ok=True` because it doesn't exist in `values-default.yml` (this is a safety feature to prevent accidental typos in keys).

`config.yml`:

```yaml
#@ load("@ytt:data", "data")

first: #@ data.values.key1
third: #@ data.values.key3
fifth: #@ data.values.key5
```

Running `ytt -f .` (or `ytt -f config.yml -f values-default.yml -f values-production.yml`) results in:

```yaml
first: val1
third: new-val3
fifth: new-val5
```

See [Multiple data values example](/ytt/#example:example-multiple-data-values) in the online playground.

## Overriding data values via command line flags

(As of v0.17.0+ `--data-value` parses value as string by default. Use `--data-value-yaml` to get previous behaviour.)

ytt CLI allows to override input data via several CLI flags:

- `--data-value` (format: `key=val`, `@lib:key=val`) can be used to set a specific key to string value
  - dotted keys (e.g. `key2.nested=val`) are interpreted as nested maps
  - examples: `key=123`, `key=string`, `key=true`, all set to strings
- `--data-value-yaml` (format: `key=yaml-encoded-value`, `@lib:key=yaml-encoded-value`) same as `--data-value` but parses value as YAML
  - examples: `key=123` sets as integer, `key=string` as string, `key=true` as bool
- `--data-value-file` (format: `key=/file-path`, `@lib:key=/file-path`) can be used to set a specific key to a string value of given file contents
  - dotted keys (e.g. `key2.nested=val`) are interpreted as nested maps
  - this flag can be very useful when loading multine line string values from files such as private and public key files, certificates
- `--data-values-env` (format: `DVAL`, `@lib:DVAL`) can be used to pull out multiple keys from environment variables based on a prefix
  - given two environment variables `DVAL_key1=val1-env` and `DVAL_key2__nested=val2-env`, ytt will pull out `key1=val1-env` and `key2.nested=val2-env` variables
  - interprets values as strings
- `--data-values-env-yaml` (format: `DVAL`, `@lib:DVAL`) same as `--data-values-env` but parses values as YAML

These flags can be repeated multiple times and used together. Flag values are merged into data values last.

Note that for override to work data values must be defined in at least one `@data/values` YAML document.

```bash
export STR_VALS_key6=true # will be string 'true'
export YAML_VALS_key6=true # will be boolean true

ytt -f . \
  --data-value key1=val1-arg \
  --data-value-yaml key2.nested=123 \ # will be int 123
  --data-value-yaml 'key3.other={"nested": true}' \
  --data-value-file key4=/path \
  --data-values-env STR_VALS \
  --data-values-env-yaml YAML_VALS
```

---
## Library data values

Available in v0.28.0+

Each library may specify data values which will be evaluated separately from the root level library.

### Setting library values via files

To override library data values, add `@library/ref` annotation to data values YAML document, like so:

```yaml
#@library/ref "@lib1"
#@data/values
---
key1: val1
key2: val2

#@library/ref "@lib1"
#@data/values after_library_module=True
---
key3: val3
```

The `@data/values` annotation also supports a keyword argument `after_library_module`. If this keyword argument is specified, given data values will take precedence over data values passed to the `.with_data_values(...)` function when evaluating via the [library module](./lang-ref-ytt-library.md).

### Setting library values via command line flags

Data value flags support attaching values to libraries for use during [library module](./lang-ref-ytt-library.md) evaluation:

```bash
export STR_VALS_key6=true # will be string 'true'
export YAML_VALS_key6=true # will be boolean true

ytt -f . \
  --data-value @lib1:key1=val1-arg \
  --data-value-yaml @lib2:key2.nested=123 \ # will be int 123
  --data-value-yaml '@lib3:key3.other={"nested": true}' \
  --data-value-file @lib4:key4=/path \
  --data-values-env @lib5:STR_VALS \
  --data-values-env-yaml @lib6:YAML_VALS
```
