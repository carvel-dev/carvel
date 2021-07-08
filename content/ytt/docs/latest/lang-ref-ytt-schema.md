---
title: Schema module
---

## Overview

`ytt` schemas are currently in the **experimental** phase. To use schema features, include `--enable-experiment-schema`.

Configuration Authors use Schema to declare data values' type and default value.

Supplemental data value files provided by Configuration Consumers are guaranteed to have the same types and structure as the schema. When a data value is used in a template, it is guaranteed to exist and be the proper type.

---
## Defining Schema
Configuration Authors establish a Schema by capturing the structure in a YAML document with `#@data/values-schema` at the top:
```yaml
#@data/values-schema
---
#! Schema contents
```

Notes:
- files containing Schema documents are supplied to `ytt` by `-f`.
- it's possible to split a Schema into multiple files. The final Schema will be the _merged_ result. Like [data values](ytt-data-values.md#splitting-data-values-into-multiple-files), merging is controlled via [overlay annotations](lang-ref-ytt-overlay.md) and follows same ordering as [overlays](lang-ref-ytt-overlay.md#overlay-order). 
- a file containing a Schema document must not contain other kinds of documents. This is because schema must be defined _before_ templates can be processed.

---
## Supported Types

While YAML provides for an extendable range of types, the `ytt` Schema supports a specific set.

### Types

- `bool` — `true`, `false` (and when not strict, `yes`, `no`, `Y`, `N`, etc.)
- `float` — e.g. `0.4`
- `int` — e.g. `42`
- `null` — `null`, `~`, and when value is omitted.
- `string` — e.g. `""`, `"ConfigMap"`, `"0xbeadcafe"`
- `map` — A YAML mapping that must contain exactly one item of each given key, whose value must be of the type specified.
- `array` — A YAML sequence, each item must be of the specified `type`.
- `any` — any valid YAML value is permitted. Must be set [explicitly](#schematype).

---
## Inferring Types

Structure in Schema is largely expressed by example rather than by description. Types are — by default — inferred based on the values given.

```yaml
#@data/values-schema
---
system_domain: ""

load_balancer:
  enable: true
  static_ip: ""

app_domains:
- ""

databases:
- name: ""
  adapter: postgresql
  host: ""
  port: 5432
  user: admin
  secretRef:
    name: ""
```

where:
- Data Values must consist of four top-level map items:
    - `system_domain` — whose value is a string,
    - `load_balancer` — whose value is a map containing two items:
        - `enable` — whose value is a boolean
        - `static_ip` — whose value is a string
    - `app_domains` — whose value is an array of strings (and only strings)
    - `databases` — whose values is an array of maps of a specific shape: six (6) items:
        - `name` — containing a string
        - `adapter` — containing a string
        - `host` — also holds a string
        - `port` — holds an integer
        - `user` — a string
        - `secretRef` — containing a map with one key:
            - `name` — containing a string

## Inferring Default Values

The exact values specified in Schema are the defaults (with one notable exception — arrays — which are [detailed below](#inferring-defaults-for-arrays)).

Configuration Consumers should specify in their data values file only those values which vary from the default, reducing risk of errors and generally making configuration easier to maintain.

### Inferring Defaults for Scalars

When a scalar value is specified, it is simply the default.  From the example, above:

- `system_domain` is an empty string, by default.
- `load_balancer.enable` is true by default.
- `databases[].adapter` is `"postgres"`, by default.

### Inferring Defaults for Mappings

The set of items of a map are its default: any item missing will be automatically inserted with _its_ defaults.

- if `load_balancer` is omitted from supplied Data Values, it is inserted:
    - `load_balancer.enabled` is `true`
    - `load_balancer.static_ip` is `""`
- if `load_balancer` is specified with only `static_ip`, `enabled` is `true`.

When the Configuration Consumer supplies an empty map (i.e. `{}`), all items are defaulted:

For example,

    ```yaml
    load_balancer: {} 
    ```

is defaulted to:

```yaml
load_balancer:
  enable: true
  static_ip: ""
```

### Inferring Defaults for Arrays

The default value for all arrays is an empty array. Arrays are the only type for which defaults are **not** inferred.

From the example, [above](#inferring-types),

- `app_domains` is `[]` by default
- `databases` is `[]` by default

To set a non-empty value for arrays, include a Data Values file with the array's value. When values are provided, each item in the array is defaulted based on the type specified in the schema.

Focusing on just `databases`, if the Configuration Consumer supplies this Data Value:

```yaml
#@data/values
---
databases:
- name: uaa
- name: capi
  host: capi-db.svc.cluster.local
  secretRef:
    name: capi-db-credentials
- {}
```

The resulting Data Values (i.e. that are supplied to templates), would be:

```yaml
databases:
- name: uaa
  adapter: postgresql
  host: ""
  port: 5432
  user: admin
  secretRef:
    name: ""
- name: capi
  adapter: postgresql
  host: capi-db.svc.cluster.local
  port: 5432
  user: admin
  secretRef:
    name: capi-db-credentials
- name: ""
  adapter: postgresql
  host: ""
  port: 5432
  user: admin
  secretRef:
    name: ""
```

## Defining Schema Explicitly

Configuration Authors may override inferred typing and defaults through annotations.

### @schema/type

Explicitly configures the type of the annotated node. Currently, the only supported configuration is whether to allow the "any" type or not.

```yaml
@schema/type any=True
```

- `any` (`bool`) — whether or not any and all types are permitted on this node (and its children).

### @schema/nullable

Extends the type of the node to include "null" _and_ sets the default value to be `null`.

```yaml
@schema/nullable
```

_Example: Nullable map and string_ 

```yaml
#@data/values-schema
---
#@schema/nullable
aws:
  username: admin
  password: "1234"

#@schema/nullable
name: dev
```

If evaluated without any data values, it results in `aws` and `name` null by default.
```yaml
aws: null
name: null
```

If evaluated with the following data values:

```yaml
#@data/values
---
aws:
  username: sa
```

The final values are the data values combined with the defaults provided in the schema.

```yaml
aws:
  username: sa
  password: "1234"

name: null
```
Because `username` was provided in the data values file, `aws` is no longer null, so the other default values for it were filled in.
