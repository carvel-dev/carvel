---
title: Data Values
---

## Overview

A `ytt` run can be configured by supplying custom Data Values.

_(For a high-level overview of `ytt`, see [How it works](how-it-works.md).)_

## Declaring Data Values

Typically, Data Values are declared in a schema file. See the [Using Data Values](how-to-use-data-values.md) guide for more details.

Note: `ytt` continues to support declaring Data Values without schema for backwards-compatibility. However, due to the significantly improved support for catching configuration errors that schema brings, it is the recommended method for doing so.

## Configuring Data Values

Data Values can be configured in one of two ways:

- on the command-line via the family of [command-line `--data-value...` flags](#configuring-data-values-via-command-line-flags),
- in a ["Data Values Overlay" document](#configuring-data-values-via-data-values-overlays) and included via the `--file` flag,


### Configuring Data Values via command line flags

The `--data-value...` family of command-line flags provides a means of configuring Data Values from:
- the command-line, itself;
- OS environment variables;
- "data values file"s — plain YAML files containing values for multiple Data Values 

Those flags are:

`--data-value [@lib:]key=value` — sets a Data Value to a _string_ value
- `key` — name of Data Value. Use dot notation for nested values (e.g. `key2.nested=val`)
- `value` — value to set (always interpreted as a string)
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- examples: `instance.count=123`, `key=string`, `input=true`, all set to strings

`--data-value-yaml [@lib:]key=value`) — sets a Data Value to a YAML-parsed value
- `key` — name of Data Value.
- `value` — value to set (decoded as a YAML value)
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- examples: `instance.count=123` sets as integer, `key=string` as string, `input=true` as bool
    
`--data-value-file [@lib:]key=file-path` — sets a single Data Value to the _contents_ of a given file.
- `key` — name of Data Value.
- `file-path` — file-system path to a file whose contents will become the value of `key`.
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- particularly useful for loading multi-line string values from files such as private and public key files, certificates, etc.
- not to be confused with `--data-values-file` (described below).

`--data-values-env [@lib:]PREFIX` — sets one or more Data Values to _string_ values from OS environment variables that start with the given prefix.
- `PREFIX` — the literal prefix used to select the set of environment variables from which to configure Data Values.
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- for nested values, use double-underscore (i.e. `__`) in environment variable names to denote a "dot".
- example: \
    with environment variables...
    ```shell
    DVAL_key1=blue
    DVAL_key2__nested=1337
    ```
    ... and the parameter ...
    ```console
    $ ytt ... --data-values-env DVAL ...
    ```
    ... would set two Data Values: \
    `key1=blue` and \
    `key2.nested="1337"`. (both as _strings_)
    
`--data-values-env-yaml [@lib:]PREFIX` — sets one or more Data Values to the YAML-parsed values from OS environment variables that start with the given prefix.
- `PREFIX` — the literal prefix used to select the set of environment variables from which to configure Data Values.
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- for nested values, use double-underscore (i.e. `__`) in environment variable names to denote a "dot".
- example: \
  with environment variables...
    ```shell
    DVAL_key1=blue
    DVAL_key2__nested=1337
    ```
  ... and the parameter ...
    ```console
    $ ytt ... --data-values-env DVAL ...
    ```
  ... would set two Data Values: \
  `key1=blue` (a string value) and \
  `key2.nested=1337` (an integer value).


`--data-values-file [@lib:]file-path` — sets one or more Data Values from a plain YAML file.
- `file-path` — file-system path to a file which will be parsed as YAML structured identically to expected Data Values.
  - file must be plain YAML (i.e. not a `ytt` template or Data Values Overlay); it cannot contain YAML comments starting with `#@`.
  - if there are more than one YAML documents in such a file, they are merged from top to bottom (last wins)
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- example: \
  with the file `prod-values.yml`
  ```yaml
  domain: example.com
  client_opts:
    timeout: 10
    retry: 5
  ```
  ... and the parameter ...
  ```console
  $ ytt ... --data-values-file prod-values.yml ...
  ```
  ... would set all three Data Values: \
  `domain=example.com` (a string value) \
  `client_opts.timeout=10` (an integer value) \
  `client_opts.retry=5` (an integer value).
 
Notes:
- As of v0.34.0+ Data Values passed via `--data-value...` flags do not _necessarily_ need to be declared beforehand. In prior versions of `ytt`, a Data Value _must_ be declared (back then, specified in a `@data/values` overlay, typically), before it could be configured through a flag.
- the `--data-value...` flags can be repeated multiple times and used in any combination. See [Data Values merge order](#data-values-merge-order) for details on how they combine.
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


### Configuring Data Values via Data Values Overlays

Data Values can also be configured via a specific kind of `ytt` Overlay.

A Data Values Overlay is a YAML document annotated with `@data/values`.

```yaml
#@data/values
---
key1: val1
key2:
  nested: val2
key3: val3
key4:
```

Note:
- `data.values` is a [`struct`](lang-ref-structs.md).
 
#### Splitting Data Values Overlays into multiple files

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


### Data Values merge order

Data values are merged in following order (latter one wins):

- default values from `@data/values-schema` files
- `@data/values` overlays (same ordering as [overlays](lang-ref-ytt-overlay.md#overlay-order))
- `--data-values-file` specified files (left to right)
- `--data-values-env` specified values (left to right)
- `--data-values-env-yaml` specified values (left to right)
- `--data-value` specified value (left to right)
- `--data-value-yaml` specified value (left to right)
- `--data-value-file` specified value (left to right)

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
  --data-values-file @lib6:/path
```
