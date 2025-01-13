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

Note: as the comment in the example schema indicates, it is best to declare the function prior to starting the schema document itself (see https://github.com/carvel-dev/ytt/issues/526 for details).

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

Attaches a validation to the type being declared by the annotated node.

```
@schema/validation rule0, rule1, ... [,<named-rules>] [,when=]
```

where:
- `ruleX` — any number of custom rules, each a 2-item tuple `(description, assertion)`
  - `description` (`string`) — a description of what a valid value is.
  - `assertion` (`function(value) : bool`) — returns `True` is the value is valid; returns `False` or `fail()`s if the value is invalid.
    - `value` (`string` | `number` | `bool` | [`yamlfragment`](lang-ref-yaml-fragment.md)) — the value of the annotated node.
    - the message given in the `fail()` will be incorporated in the violation message.
- `<named-rules>` — a combination of one or more built-in keywords that provide assertion functions for common scenarios. 
  - for a quick reference, see [Validations Cheat Sheet](quick-ref-validations.md).
  - for the complete list, see [Named Validation Rules](#named-validation-rules), below.
- `when=` (`function(value[, context]) : bool`) — criteria for when the validation rules should be checked. 
  - `value` (`string` | `int` | `float` | `bool` | [`yamlfragment`](lang-ref-yaml-fragment.md)) — the value of the annotated node
  - `context` (_optional_) — a struct with two attributes (both of the same _type_ as `value`).
    - `parent` — the node directly containing the annotated node (in other words, its parent)
    - `root` — the document in which the annotated node is contained (that is, the root of document resulting from the merge of all data values)

When present, the predicate given for `when=` is run. If it evaluates to `True`, the validation is run. For guidance on writing these conditions, see [How To Write Validations](how-to-write-validations.md#conditional-validations).

For a quick reference of various rules and idioms, see [Schema Validation Cheat Sheet](schema-validations-cheat-sheet.md).

Below:
- [Example 1: Using "named" rules](#example-1-using-named-rules)
- [Example 2: Using `when=`](#example-2-using-when)
- [Example 3: Accessing other data values within `when=`](#example-3-accessing-other-data-values-within-when)
- [Validation Rule Evaluation](#validation-rule-evaluation)
- [Named Validation Rules](#named-validation-rules)


#### Example 1: Using "named" rules

```yaml
#@data/values-schema
---
#@schema/validation min_len=1
namespace: ""

#@schema/validation min_len=1
hostname: ""

port:
  #@schema/validation min=1, max=32767
  https: 443

#@schema/validation one_of=["debug", "info", "warning", "error", "fatal"]
logLevel: info

#@schema/nullable
tlsCertificate:
  #@schema/validation min_len=1
  tls.crt: ""
  #@schema/validation min_len=1
  tls.key: ""
  #@schema/nullable
  ca.crt: ""
```
where:
- `namespace` and `hostname` are "required" —  they will require overrides from the user to pass validation.
  - see [How to Write Validations: "Required" Data Values](how-to-write-validations.md#required-data-values)
- `port.https` must be between 1 and 32767, inclusive.
- `logLevel` can _only_ be one of the values given
- `tlsCertificate` is optional, by default (and is `null`)
  - however, if one or more of its values are set, _then_ both `tls.crt` and `tls.key` are "required".
  - `ca.crt` is optional (and defaults to `null`)

#### Example 2: Using `when=`

```yaml
#@data/values-schema
---
#@schema/validation ("have 1+ response type", lambda v: len(v["responseTypes"]) > 0), when=lambda v: v["enabled"] == True
oauth2:
  enabled: true
  responseTypes:
    - ""
```
where:
- validation on `oauth2` will only be run if `oauth2.enabled` is true.
- `v` is a [YAML Fragment](lang-ref-yaml-fragment.md) (hence the need for index notation to traverse the tree).

#### Example 3: Accessing other data values within `when=`

```yaml
#@data/values-schema
---
credential:
  useDefaultSecret: true
  #@schema/nullable
  #@schema/validation not_null=True, when=lambda _, ctx: ctx.parent["useDefaultSecret"]
  secretContents:
    cloud: ""
backupStorageLocation:
  spec:
    #@schema/nullable
    #@schema/validation not_null=True, when=lambda _, ctx: not ctx.root["credential"]["useDefaultSecret"]
    existingSecret: ""
#@schema/validation ("have 1+ response type", lambda v: len(v["responseTypes"]) > 0), when=lambda v: v["enabled"] == True
oauth2:
  enabled: true
  responseTypes:
    - ""
```
where:
- `secretContents` validation is dependent on its sibling `useDefaultSecret` value.
  - the value of `when=` is a lambda expression  making it possible to define a function value in-place.
    - Lambda expressions start with the keyword `lambda`, followed by a parameter list, then a `:`, and a single expression that is the body of the function. For more detail see [Starlark Spec: lambda expression](https://github.com/google/starlark-go/blob/master/doc/spec.md#lambda-expressions).
  - the `_` is an idiom for an ignored parameter. Here, the value of `secretContents` is not being used.
  - the optional second parameter `ctx` where the `.parent` attribute refers to the value of `credential`
- `existingSecret` validation is dependent on `secretContents` which resides in a whole different subset of the data values.
  - `ctx.root` refers to the top-most node of the document resulting from merging of all data values (as described in [How It Works: Calculating Data Values](how-it-works.md#step-1-calculate-data-values)).

#### Validation Rule Evaluation

When a validation runs, _all_ rules are evaluated. Rules are evaluated in the order they appear in the annotation (left-to-right).

The one exception is the `not_null=` rule:
- when present, this rule is evaluated _first_ — regardless of its position on the annotation.
- if this rule is not satisfied, no other rules are evaluated.

`not_null=` behaves this way so that all other rules can assume they are validating a non-null value. This simplifies all other rules as they need not perform a null-check.

Validity:
- if _all_ rules pass (i.e. returns `True`), then the value is valid.
- if _any_ rule returns `False` or `fail()`'s, then the value is invalid.


#### Named Validation Rules

There are seven (7) built-in (so-called "named") rules:

- [`max=`](#max) — the node's value must be <= the maximum given
- [`max_len=`](#max_len) — the length of node's value must be <= the maximum given
- [`min=`](#min) — the node's value must be >= the minimum given
- [`min_len=`](#min_len) — the length of node's value must be >= the minimum given
- [`not_null=`](#not_null) — the node's value must not be `null`
- [`one_not_null=`](#one_not_null) — _exactly_ one (1) item in the map is not `null`.
- [`one_of=`](#one_of) — the node's value must be one from the given set.

Every named rule is also available as a function in the [`@ytt:assert` module](lang-ref-ytt-assert.md). Having a function that behaves identically to the named rule makes it easier to transition to more customized experience.


What follows is a reference for each named rule.

---

##### max=

```
@schema/validation max=maximum
```

Where:
- `maximum` (`int` | `float` | `string` | `bool` | `list` ) — the largest allowable valid value (inclusive); see [Starlark: Comparisons](https://github.com/google/starlark-go/blob/master/doc/spec.md#comparisons) for how different values compare.

This keyword is equivalent to:

```
@schema/validation ("a value less than or equal to", lambda v: v <= maximum)
```

##### max_len=

```
@schema/validation max_len=maximum
```

Where:
- `maximum` (`int`) — the longest allowable length (inclusive)

This keyword is equivalent to:

```
@schema/validation ("length less than or equal to", lambda v: len(v) <= maximum)
```

##### min=

```
@schema/validation min=minimum
```

Where:
- `minimum` (`int` | `float` | `string` | `bool` | `list` ) — the smallest allowable value (inclusive); see [Starlark: Comparisons](https://github.com/google/starlark-go/blob/master/doc/spec.md#comparisons) for how different values compare.

This keyword is equivalent to:

```
@schema/validation ("a value greater than or equal to", lambda v: v >= minimum)
```

##### min_len=

```
@schema/validation min_len=(minimum)
```

Where:
- `minimum` (`int`) — the shortest allowable length (inclusive)

This keyword is equivalent to:

```
@schema/validation ("length greater than or equal to", lambda v: len(v) >= minimum)
```

##### not_null=

```
@schema/validation not_null=(nullable)
```

Where:
- `nullable` (`bool`) — whether `null` is a valid value.

When present, this rule is checked before any other; this allows other rules (including custom rules) to assume the value is not null.


This keyword is equivalent to:

```
@schema/validation ("not null", lambda v: v != None)
```

##### one_not_null=

Requires a map to contain exactly one (1) item that has a non-null value.

```
@schema/validation one_not_null=([key0, key1,...] | True)
```

Where:
- `keyX` (`string`) — keys within the annotated map to check for null/non-null; other map items are ignored.
- `True` — check all contained map items for null/non-null.

Each item that is referenced by this rule is almost always annotated as nullable:

```yaml
#@schema/validation one_not_null=["item1", "item2", "item3"]
map:
  #@schema/nullable
  item1: ""
  #@schema/nullable
  item2: ""
  #@schema/nullable
  item3: ""
  otherConfig: true
```

This keyword is equivalent to:

```
@schema/validation ("exactly one child not null", lambda v: assert.one_not_null([key0, key1,...]))
```
(see also [@ytt:assert.one_not_null()](lang-ref-ytt-assert.md#assertone_not_null))

##### one_of=

Requires value to be exactly one of the given enumeration.

```
@schema/validation one_of=[val0, val1, ...]
```

Where:
- `[val1, val2, ...]` (list/tuple of any type) — the exhaustive set of valid values.

This keyword is equivalent to:

```
@schema/validation ("one of [val0, val1, ...]", lambda v: v in [val0, val1, ...])
```
