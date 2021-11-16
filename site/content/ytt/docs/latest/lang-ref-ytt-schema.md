---
title: Data Values Schema Reference
---

## Overview

This reference covers details of Data Values Schema: supported types and annotations.

For an introduction of Data Values, see [Using Data Values](how-to-use-data-values.md). \
For details on writing Schema, see [Writing Schema](how-to-write-schema.md).

## The Schema Document

Schema is written in YAML. 

```yaml
#@data/values-schema
---
...
```
where:
- the document must be annotated as `@data/values-schema`
- each item in the document [declares a Data Value](#data-value-declarations) (i.e. an item in the [data.values](lang-ref-ytt.md#data) struct).
- (optionally) types and default values can be explicitly specified through [annotations](#annotations).
- a file containing a Schema document must not contain any other kind of document.

### Multiple Schema Documents

In some cases, it is useful to separate Schema into multiple YAML documents (typically in separate files).

When doing so, it becomes relevant to know that Schema Documents are [`ytt` Overlays](ytt-overlays.md):
- they merge in [the same order as overlays](lang-ref-ytt-overlay.md#overlay-order), and
- one controls that merge via [overlay annotations](lang-ref-ytt-overlay.md#overlay-annotations).

---
## Data Value Declarations

Each item in a Schema Document declares a Data Value.

A Data Value declaration has three (3) parts:
- the **name** of the data value,
- its **default** value, and
- the **type** of the value.

---
### Names

A Data Value is referred to by its name (aka "key" or "attribute"). \
A Data Value name must be a string.

When using multi-word names, it is recommended to employ snake-case (e.g. `database_connection`). This principally because:
- the underlying programming language in `ytt` — Starlark — is Pythonic in which identifiers are snake-cased, by convention
- as in most modern languages, the dash (i.e. `-`) is not allowed for identifier names in Starlark (allow characters are: Unicode letters, decimal digits, and underscores `_`, per the [Starlark spec](https://github.com/google/starlark-go/blob/master/doc/spec.md#lexical-elements)).

Where disallowed characters in names cannot be avoided, references will need to employ either:
- the Starlark built-in [`getattr()`](https://github.com/google/starlark-go/blob/master/doc/spec.md#getattr)
    ```python
    secure: #@ getattr(data.values, "db-conn").secure
    ```
- _(as of v0.31.0)_ or [index notation](lang-ref-structs.md#attributes):
    ```python
    secure: #@ data.values["db-conn"].secure
    ```

---
### Default Values

The default value for a Data Value is specified in schema, directly:

- the default value for a **scalar** is the value given;
- the default value for a **map** are all of the items specified in the schema (with _their_ defaults, recursively);
- the default value for an **array** is an empty list (i.e. `[]`).
  - the default value for _an item_ in an array are the contents of the item specified in schema (with _their_ defaults, recursively).

#### Defaults for Scalars

When a [scalar value](#types-of-scalars) is specified, the default is merely that value.

For example,
```yaml
#@data/values-schema
---
system_domain: ""

load_balancer:
  enabled: true
  
databases:
- name: ""
  adapter: postgresql
```

- `system_domain` is `""` (i.e. an empty string), by default.
- `load_balancer.enabled` is `true` by default.
- `databases[].adapter` is the string `"postgres"`, by default.

#### Defaults for Mappings

The set of items of a map are its default: any missing item will be automatically added with _its_ defaults.

For example,
```yaml
#@data/values-schema
---
load_balancer:
  enabled: true
  static_ip: ""
```

if `load_balancer` were omitted from supplied Data Values, entirely, it would default to:
- `load_balancer.enabled` is `true`
- `load_balancer.static_ip` is `""`
  
if `load_balancer` is _partially_ specified...

```yaml
#@data/values
---
load_balancer:
  static_ip: 10.0.101.1
```

the missing item (here, `enabled`) is defaulted:
- `load_balancer.static_ip` is `"10.0.101.1"`
- `load_balancer.enabled` is `true`


#### Defaults for Arrays

The default value for all arrays is always an empty array.

This is different from all other types where the default value is literally what is specified in schema. For arrays, it is always `[]` (i.e. an empty array).

This means that the value given for the element is _only_ used to infer the type of the array's _elements_.

```yaml
#@data/values-schema
---
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

- `app_domains` is `[]` by default. Each item in the array must be a **string**.
- `databases` is `[]` by default. Each item in the array must be a **map**. When an item is added to the array:
  - its key must be one of those named in this schema: `name`, `adapter`, `host`, etc.
  - if it lacks any of the six keys, they will be added with their default values.

---
### Types

`ytt` Schema can infer the type of the Data Value from the following...

#### Types of Scalars

`ytt` recognizes the following scalar types:

- **strings** — e.g. `""`, `"ConfigMap"`, `"0xbeadcafe"`
- **integers** — e.g. `42`
- **booleans** — `true`, `false` (and when not strict, `yes`, `no`, `Y`, `N`, etc.)
- **floats** — e.g. `0.4`

#### Types of Maps

A map is a collection of map items, each a key/value pair.

The schema of a map is inferred from that collection. Each item declares a nested Data Value of the type inferred from the given map item's value.

For example,
```yaml
load_balancer:
  enabled: true
  static_ip: ""
```

where:
- `load_balancer` has a type of a map that has two items:
  - one item has a key `enabled` whose type is a **boolean**.
  - the other item has a key of `static_ip` and is a **string**.

#### Types of Arrays

An array is a sequence of array items.

The schema of an array must contain _exactly_ one (1) item. The type inferred from that item becomes the type of _all_ items in that array. That is, arrays in `ytt` are homogenous.

For example,
```yaml
app_domains:
- ""
```
where:
- `app_domains` has a type of an array. Each element in that array will be a **string**.
- note that the default value for `app_domains` is an empty list as explained in [Defaults for Arrays](#defaults-for-arrays), above.

#### `null` Type

The `null` value means the absence of a value.

In `ytt` schema, a default value is not permitted to be `null` (with one exception described in [`any` Type](#any-type), below). This is because no useful type can be inferred from the value `null`.

Instead, one provides a non-null default value and annotates the Data Value as "nullable".

This results in a Data Value whose default value is `null`, but when set to a non-null value has an explicit type.  See [`@schema/nullable`](#schemanullable) for details.

#### `any` Type

In certain cases, it may be necessary to relax all restrictions on the type or shape of a Data Value:

- the Data Value is a pass-through, where template(s) using it merely insert its value, but care not about the actual contents;
- a heterogeneous array is required;
- there are multiple possible allowed types for a given Data Value.

This is done by annotating the Data Value as having "any" type. See [`@schema/type`](#schematype) for details.

---
## Annotations

`ytt` determines the type of each Data Value by _inferring_ it from the value specified in the schema file (as described in [Types](#types), above). Currently, there is no way to _explicitly_ set the type of a Data Value.

Configuration Authors can explicit specify the type of a Data Value in two cases that are **not** inferrable:
- allowing any type (via the [@schema/type](#schematype) annotation).
- also allowing null (via the [@schema/nullable](#schemanullable) annotation).


### @schema/type

Explicitly configures the type of the annotated node. Currently, the only supported configuration is whether to allow the "any" type or not.

```yaml
#@schema/type any=True
```

where:
- `any` (`bool`) — whether or not any and all types are permitted on this node and its children.

The annotated node and its nested children are not checked by schema, and has no schema default behavior. 
However, the annotated node and its children are simply passed-through as a data value. 
All nested `@schema` annotations are ignored.

_Example: Using any=True to avoid schema restrictions on an array_
```yaml
#@data/values-schema
---
#@schema/type any=True
app_domains:
  - "carvel.dev"
  - 8080
```
### @schema/nullable

Extends the type of the Data Value to also allow `null` _and_ sets the default value to be `null`.

```yaml
#@schema/nullable
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

Without other Data Value settings, `aws` and `name` are both `null` by default:
```yaml
aws: null
name: null
```

However, if a Data Value is set:

```bash
$ ytt ... --data-value aws.username=sa ...
```

That effectively sets `aws` to be non-null: `username` is set to the custom value and `password` is defaulted.

```yaml
aws:
  username: sa
  password: "1234"

name: null
```
