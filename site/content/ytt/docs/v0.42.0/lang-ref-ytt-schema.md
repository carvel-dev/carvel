---
aliases: [/ytt/docs/latest/lang-ref-ytt-schema]
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

Default values can be overridden using the [@schema/default](#schemadefault) annotation.

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

The default value for all arrays is, by default, an empty array.

This is different from all other types where the default value is literally what is specified in schema. For arrays, it is `[]` (i.e. an empty array).

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

The default value of an array _itself_ can be overridden using the [@schema/default](#schemadefault) annotation.

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
- overriding the default value (via the [@schema/default](#schemadefault) annotation);
- also allowing null (via the [@schema/nullable](#schemanullable) annotation);
- allowing any type (via the [@schema/type](#schematype) annotation).

### @schema/default

Overrides the default value for the annotated node.

```yaml
#@schema/default default_value
```
- `default_value` — the value to set as the default for the annotated node.
  - this value must be of the same type as the value given on the node.

_(as of v0.38.0)_

_Example 1: Default value for an array of scalars_

```yaml
#@data/values-schema
---
#@schema/default ["apps.example.com", "gateway.example.com"]
app_domains:
- ""
```

... yields the default:

```yaml
app_domains:
- apps.example.com
- gateway.example.com
```

_Example 2: Default value for an array of maps_

When specifying values for an array of maps, it can quickly become unwieldy to keep on a single line.

To handle these situations, enclose those values in a [Fragment function](lang-ref-yaml-fragment.md) and invoke that function as the value for `@schema/default`:

```yaml
#! For best results, declare functions *before* the schema document.
#@ def default_dbs():
- name: core
  host: coredb
  user: app1
- name: audit
  host: metrics.svc.local
  user: observer
#@ end

#@data/values-schema
---
#@schema/default default_dbs()
databases:
- name: ""
  adapter: postgresql
  host: ""
  port: 5432
  user: admin
  secretRef:
    name: ""
```

Yields the default:

```yaml
databases:
- name: core
  adapter: postgresql
  host: coredb
  port: 5432
  user: app1
  secretRef:
    name: ""
- name: audit
  adapter: postgresql
  host: metrics.svc.local
  port: 5432
  user: observer
  secretRef:
    name: ""
```

Note: as the comment in the example schema indicates, it is best to declare the function prior to starting the schema document itself (see https://github.com/vmware-tanzu/carvel-ytt/issues/526 for details).

### @schema/nullable

Extends the type of the Data Value to also allow `null` _and_ sets the default value to be `null`.

```yaml
#@schema/nullable
```

**Unset value for strings**

The preferred way to express "unset value" for a string-type is _not_ to mark it as "nullable" but to provide the empty value: `""`. Empty values in Starlark are falsey (details in the [Starlark Spec > Booleans](https://github.com/google/starlark-go/blob/master/doc/spec.md#booleans)).

When empty string is a useful/valid value for a given Data Value, _then_ marking it as "nullable" is appropriate. In this case, one must take care to explicitly check if that Data Value is not [`None`](lang.md#types).

_Example: Nullable map_ 

```yaml
#@data/values-schema
---
#@schema/nullable
aws:
  username: admin
  password: "1234"

name: ""
```

Without other Data Value settings, `aws` is `null` by default:
```yaml
aws: null
name: ""
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

name: ""
```

### @schema/type

Explicitly configures the type of the annotated node. Currently, the only supported configuration is whether to allow the "any" type or not.

```yaml
#@schema/type any=True
```

where:
- `any` (`bool`) — whether or not any and all types are permitted on this node and its children.

The annotated node and its nested children are not checked by schema, and has no schema defaulting behavior.
However, _(as of v0.39.0)_ any nested `@schema` annotation that alters type or value of a child would conflict with the fragment's "any" type, resulting in an error.
Otherwise, the annotated node and its children are simply passed-through as a data value.

_Example: Using any=True to avoid schema restrictions on an array_

```yaml
#@data/values-schema
---
#@schema/type any=True
app_domains:
  - "carvel.dev"
  - 8080
```

_Example: Error case when setting schema within an any type fragment_

```yaml
#@data/values-schema
---
#@schema/type any=True
app_domains:
  #@schema/default "localhost"
  #@schema/type any=False
  - "carvel.dev"
```
```
ytt: Error:
  Invalid schema
  ==============

  Schema was specified within an "any type" fragment
  schema.yml:
    |
  5 |   #@schema/default "localhost"
  6 |   #@schema/type any=False
  7 |   - "carvel.dev"
    |

    = found: @schema/type, @schema/default annotation(s)
    = expected: no '@schema/...' on nodes within a node annotated '@schema/type any=True'
```

### @schema/validation

> ⚠️ **This function is part of the experimental "validations" feature.\
> ⚠️ Its interface and behavior are subject to change.** \
> _To enable this feature, see [Blog: "Preview of ytt Validations"](/blog/ytt-validations-preview/)._

Attaches a validation to the type being declared by the annotated node.

```
@schema/validation rule0, rule1, ... [,<named-rules>] [,when=] [,when_null_skip=]
```

where:
- `ruleX` — any number of custom rules, each a 2-item tuple `(description, assertion)`
  - `description` (`string`) — a description of what a valid value is.
  - `assertion` (`function(value) : None` | `function(value) : bool`) — that either `fail()`s or returns `False` when `value` is not valid.
    - `value` (`string` | `number` | `bool` | [`yamlfragment`](lang-ref-yaml-fragment.md)) — the value of the annotated node.
- `named-rules` — any number of built-in keywords that provide assertion functions for common scenarios.
  - `min=` (`string` | `number` | `bool` | `list` | `dict` | [`yamlfragment`](lang-ref-yaml-fragment.md)) — node's value must be >= the minimum provided. 
    - equivalent to [@ytt:assert.min()](lang-ref-ytt-assert.md#assertmin)
  - `max=` (`string` | `number` | `bool` | `list` | `dict` | [`yamlfragment`](lang-ref-yaml-fragment.md)) — node's value must be <= the maximum provided.
    - equivalent to [@ytt:assert.max()](lang-ref-ytt-assert.md#assertmax)
  - `min_len=` (`number`) — length of node's value must be >= the minimum length provided.
    - equivalent to [@ytt:assert.min_len()](lang-ref-ytt-assert.md#assertmin_len)
  - `max_len=` (`number`) — length of node's value must be <= the maximum length provided.
    - equivalent to [@ytt:assert.max_len()](lang-ref-ytt-assert.md#assertmax_len)
  - `not_null=` (`bool`) — if set to `True`, the node's value must not be null.
    - equivalent to [@ytt:assert.not_null()](lang-ref-ytt-assert.md#assertnot_null)
  - `one_not_null=` (`bool` | `list`) — exactly one item in a map is not null.
    - the node's value must be a map
    - if a list of keys are given, only those keys are considered
    - if `True` is given, all keys are considered
    - equivalent to [@ytt:assert.one_not_null()](lang-ref-ytt-assert.md#assertone_not_null)
  - `one_of=` (`list`) — node's value must be one of those in the supplied list.
    - values can be of any type
    - equivalent to [@ytt:assert.one_of()](lang-ref-ytt-assert.md#assertone_of)
- `when=` (`function(value) : None` | `function(value) : bool`) — criteria for when the validation rules should be checked. 
  - `value` (`string` | `int` | `float` | `bool` | [`yamlfragment`](lang-ref-yaml-fragment.md)) — the value of the annotated node.
- `when_null_skip=` (`bool`) — a special-case of `when=` that checks if the value of the annotated node is `null`. default: `False`
  - if the data value is also annotated `@schema/nullable`, this becomes `True`, by default.

The criteria in `when=` and `when_null_skip=` are evaluated (if present). The validation is run if _both_ are `True`.

Each rule is evaluated, in the order they appear in the annotation (left-to-right):
- if all rules pass (either returns `True` or `None`), then the value is valid.
- if a rule returns `False` (not `None`) or `fail()`'s, then the value is invalid.

The `named-rules` provide access to a set of built-in assertion functions that correspond to functions defined in the [`@ytt:assert` module](lang-ref-ytt-assert.md)

_Example 1: Out-of-the-box assertion rules_

```yaml
#@data/values-schema
---
login:
  #@schema/validation min_len=1
  username: admin
  #@schema/validation min_len=1
  password: password

#@schema/validation max_len=15
ipv4: "123.456.789.000"

#@schema/nullable
#@schema/validation not_null=True
database:
  driver: ""
  #@overlay/validation min_len=1
  username: ""
  db_name: ""
  #@overlay/validation min=1025
  port: 0

#@schema/validation max=10
concurrent_threads: 3
```

All values provided in the example schema pass the assertions, resulting in no error message.    

_Example 2: Custom assertion-based rule_

```yaml
#@data/values-schema
---
#@ def is_dynamic_port(port):
#@   port in range(49142, 65535) or fail("is {}".format(port))
#@ end
#@schema/validation ("a TCP/IP port in the dynamic range: 49142 and 65535, inclusive", is_dynamic_port)
adminPort: 1024
```

If not overridden will produce the following error message:

```console
$ YTTEXPERIMENTS=validations ytt -f schema.yml
ytt: Error: One or more data values were invalid:
- "adminPort" (schema.yml:7) requires "a TCP/IP port in the dynamic range: 49142 and 65535, inclusive"; fail: is 1024 (by schema.yml:6)
```
