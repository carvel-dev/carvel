---
aliases: [/ytt/docs/latest/ytt-data-values]
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

- the command-line, multiple values:
    - [`--data-values-file`](#--data-values-file) — multiple values from a file, directory, URL, or standard in.
- the command-line, directly, one at a time:
  - [`--data-value`](#--data-value) — single value as a string.
  - [`--data-value-yaml`](#--data-value-yaml) — single value decoded a YAML.
  - [`--data-value-file`](#--data-value-file) — a single value to the contents of a file, URL, or standard in.
- OS environment variables:
  - [`--data-values-env`](#--data-values-env) — all OS variables with a named prefix, all as strings.
  - [`--data-values-env-yaml`](#--data-values-env-yaml) — all OS variables with a named prefix, decoded as YAML.

**Quick Example**

```bash
export STR_VALS_key6=true
export YAML_VALS_key7=true

$ cat dev/values.yml
key1: values.yml-key1
key2:
  original: from values.yml

$ ytt \
  --data-value key1=val1-arg        \  # overrides key1 from dev/values.yml
  --data-value-yaml key2.nested=123 \  # merges into key2 from dev/values.yml
  --data-value-yaml 'key3.other={"nested": true}' \  # decoded to a map
  --data-value-file key4=client.crt \  # contains contents of client.crt
  --data-values-env STR_VALS        \  # decodes STR_VALS_key6 to a string
  --data-values-env-yaml YAML_VALS  \  # decodes YAML_VALS_key7 to a boolean
  --data-values-file dev/           \  # finds and uses dev/values.yml
  --data-values-inspect
```

yields:
```yaml
key2:
  original: from values.yml
  nested: 123
key6: "true"
key7: true
key1: val1-arg
key3:
  other:
    nested: true
key4: <contents of client.crt>
```

**Notes**
- the `--data-value...` flags can be repeated multiple times and used in any combination. The do not necessarily combine in the order supplied on the command-line; see [Data Values merge order](#data-values-merge-order) for details.
- Where schema is used, `--data-value...` flags can only _override_ values allowed by schema. Once schema is in use, _all_ Data Values must be declared in schema files.
- Where schema is _not_ used, (as of v0.34.0) Data Values can be _declared_ via `--data-value...` flags (previously, these flags could only _override_ previously declared values). This is useful for ad-hoc templating situations (usually a shell script one-liner) involving one or two Data Values — where type checks and validations are less useful.


#### `--data-values-file`

Sets one or more Data Values from a plain YAML file, a directory containing YAML files, an HTTP URL, or standard input.

```
--data-values-file [@lib:]path
```

- `path` — one of: a filesystem path; an HTTP URL; or the dash character `-`.
  - filesystem path can either be the path to a single YAML file _or_ a directory that (recursively) contains one or more files that have either the `.yaml` or `.yml` extension. If a directory is specified, all non-YAML files are ignored.
  - HTTP URL is expected to resolve to a stream of one or more YAML document(s).
  - `-` is the UNIX convention for referring to standard input. When specified, stdin is expected to contain a plain YAML document.
    - The `-` file can only be used once in a `ytt` invocation.
    - this input is given the name `stdin.yml`.
- `@lib:` — (optional) names the library whose data values to configure (details [below](#setting-library-values-via-command-line-flags)) rather than the root library.

Not to be confused with [`--data-value-file`](#--data-value-file) which sets the value of exactly one Data Value.

**Plain YAML Data Values**

Regardless the source, the inputs for this flag must be plain YAML. It must not contain `ytt` templating (i.e. comments that start with `#@`.

When multiple YAML documents are given, they are merged:
- each document is merged into the previous;
- map values are merged (values for entries that were previously defined are merged within the same key, recursively; values for new keys are added to the map);
- array values are replaced (last wins)

**Examples:**

_Example 1: Single File_

`prod-values.yml`
```yaml
domain: example.com
client_opts:
  timeout: 10
  retry: 5
```

```console
$ ytt ... --data-values-file prod-values.yml
```

sets all three Data Values:
- `domain=example.com` (a string value)
- `client_opts.timeout=10` (an integer value)
- `client_opts.retry=5` (an integer value)

_Example 2: Directory_

See https://github.com/carvel-dev/ytt/tree/develop/examples/data-values-directory for a complete example and explanation.

_Example 3: HTTP URL_

Given https://raw.githubusercontent.com/carvel-dev/ytt/develop/examples/data-values/values-file.yml

```console
$ ytt --data-values-file https://raw.githubusercontent.com/carvel-dev/ytt/develop/examples/data-values/values-file.yml --data-values-inspect
```
yields
```yaml
nothing: something
string: str
bool: true
int: 124
new_thing: new
```

(Note the merged value of `int:`)

#### `--data-value`

Sets a single Data Value to a _string_ value.

```
--data-value [@lib:]key=value
```

- `key` — name of Data Value. Use dot notation for nested values (e.g. `key2.nested=val`)
- `value` — value to set (always interpreted as a string)
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- examples: `instance.count=123`, `key=string`, `input=true`, all set to strings

#### `--data-value-yaml`

Sets a single Data Value to a YAML-parsed value.

```
--data-value-yaml [@lib:]key=value
```
- `key` — name of Data Value.
- `value` — value to set (decoded as a YAML value)
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- examples: `instance.count=123` sets as integer, `key=string` as string, `input=true` as bool

#### `--data-value-file`

Sets a single Data Value to the _contents_ of: a given file, an HTTP URL, or standard input.

```
--data-value-file [@lib:]key=path
```
- `key` — name of Data Value.
- `path` — one of: a file path; an HTTP URL; or the dash character `-`.
    - `-` is the UNIX convention for referring to standard input. The `-` file can only be used once in a `ytt` invocation.
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))

This flag is particularly useful for loading multi-line string values from files such as private and public key files, certificates, etc.

Not to be confused with [`--data-values-file`](#--data-values-file) which sets the values of multiple Data Values.


#### `--data-values-env`

Sets one or more Data Values to _string_ values from OS environment variables that start with the given prefix.

```
--data-values-env [@lib:]PREFIX
```
- `PREFIX` — the literal prefix used to select the set of environment variables from which to configure Data Values.
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))

**Setting Environment Variables**
- for nested values, use double-underscore (i.e. `__`) in environment variable names to denote a "dot".

**Examples**

_Example: With Nested Values_

```shell
$ env
...
DVAL_key1=blue
DVAL_key2__nested=1337
...
```

```console
$ ytt ... --data-values-env DVAL
```

would set two Data Values:
- `key1=blue` (the string "blue")
- `key2.nested="1337"` (the string "1337")
    
#### `--data-values-env-yaml`


Sets one or more Data Values to the YAML-decoded values from OS environment variables that start with the given prefix.

```
--data-values-env-yaml [@lib:]PREFIX
```

- `PREFIX` — the literal prefix used to select the set of environment variables from which to configure Data Values.
- `@lib:` — (optional) specify library whose data values to configure (details [below](#setting-library-values-via-command-line-flags))
- for nested values, use double-underscore (i.e. `__`) in environment variable names to denote a "dot".

**Examples**

_Example: With Nested Values_

```shell
$ env
...
DVAL_key1=blue
DVAL_key2__nested=1337
...
```

```console
$ ytt ... --data-values-env DVAL
```

would set two Data Values:
- `key1=blue` (a string value)
- `key2.nested=1337` (an integer value)


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

1. default values from `@data/values-schema` files
2. `@data/values` overlays (same ordering as [overlays](lang-ref-ytt-overlay.md#overlay-order))
3. `--data-values-file` (same ordering as [overlays](lang-ref-ytt-overlay.md#overlay-order))
4. `--data-values-env` specified values (left to right)
5. `--data-values-env-yaml` specified values (left to right)
6. `--data-value` specified value (left to right)
7. `--data-value-yaml` specified value (left to right)
8. `--data-value-file` specified value (left to right)

_(When configuring libraries, the [data values merge order](#library-data-values-merge-order), is the same, even if through different mechanisms.)_

---
## Library data values

Available in v0.28.0+

Each library may specify data values which will be evaluated separately from the root level library.

### Setting library values via files

To override library data values, add [`@library/ref`](lang-ref-ytt-library.md#libraryref) annotation to data values YAML document, like so:

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

$ ytt -f . \
   --data-value @lib1:key1=val1-arg \
   --data-value-yaml @lib2:key2.nested=123 \ # will be int 123
   --data-value-yaml '@lib3:key3.other={"nested": true}' \
   --data-value-file @lib4:key4=/path \
   --data-values-env @lib5:STR_VALS \
   --data-values-env-yaml @lib6:YAML_VALS
   --data-values-file @lib6:/path
```

```console
export STR_VALS_key6=true
export YAML_VALS_key7=true

$ cat dev/values.yml
key1: values.yml-key1
key2:
  original: from values.yml

$ ytt \
  --data-value @lib1:key1=val1-arg        \  # overrides key1 from dev/values.yml
  --data-value-yaml @lib1:key2.nested=123 \  # merges into key2 from dev/values.yml
  --data-value-yaml '@lib2:key3.other={"nested": true}' \  # decoded to a map
  --data-value-file @lib2:key4=client.crt \  # contains contents of client.crt
  --data-values-env @lib2:STR_VALS        \  # decodes STR_VALS_key6 to a string
  --data-values-env-yaml @lib1:YAML_VALS  \  # decodes YAML_VALS_key7 to a boolean
  --data-values-file @lib1:dev/              # finds and uses dev/values.yml
```
sends the following Data Values to library `lib1`:
```yaml
key2:
  original: from values.yml
  nested: 123
key7: true
key1: val1-arg
```
and the following Data Values to library `lib2`:
```yaml
key6: "true"
key3:
  other:
    nested: true
key4: <contents of client.crt>
```


### Library Data Values merge order

For a given library instance, data values are merged in following order (latter one wins):

1. default values from schema:
   1. `@data/values-schema` files within the library
   2. `@data/values-schema` files [externally referenced in](#setting-library-values-via-files).
   3. given through [`instance.with_data_values_schema()`](lang-ref-ytt-library.md#instancewith_data_values_schema)
   4. `@data/values-schema` files [externally referenced in `after_library_module=True`](#setting-library-values-via-files).
2. values from data value sources:
   1. `@data/values` overlays within the library (same ordering as [overlays](lang-ref-ytt-overlay.md#overlay-order))
   2. `@data/values` overlays [externally referenced in](#setting-library-values-via-files)
   3. specified using [`instance.with_data_values()`](lang-ref-ytt-library.md#instancewith_data_values)
   4. `@data/values` overlays [externally referenced in `after_library_module=True`](#setting-library-values-via-files)
   5. `--data-values-file` specified files [referenced in](#setting-library-values-via-command-line-flags) (same ordering as [overlays](lang-ref-ytt-overlay.md#overlay-order))
   6. `--data-values-env` specified values [referenced in](#setting-library-values-via-command-line-flags) (left to right)
   7. `--data-values-env-yaml` specified values [referenced in](#setting-library-values-via-command-line-flags) (left to right)
   8. `--data-value` specified value [referenced in](#setting-library-values-via-command-line-flags) (left to right)
   9. `--data-value-yaml` specified value [referenced in](#setting-library-values-via-command-line-flags) (left to right)

