---
title: Writing Schema
---

## Overview

In `ytt`, before a Data Value can be used in a template, it must be declared. This is typically done via Data Values Schema.

This guide shows how to write such schema.

_(For a broader overview of Data Values, see [Using Data Values](how-to-use-data-values.md))._

---
## Starting a Schema Document

One writes Data Values Schema in a YAML document annotated with `#@data/values-schema`:

```yaml
#@data/values-schema
---
#! Schema contents
```

Files containing Schema documents are included via the `--file`/`-f` flag.

```bash
$ ytt ... -f schema.yml ...
```

The contents of such a document _are_ the Data Values being declared.

## Declaring Data Values

Each item in the schema document declares a Data Value.

A Data Value declaration has three (3) parts: a **name**, a **default value**, and a **type**.

For example,
```yaml
#@data/values-schema
---
system_domain: ""
```

declares the Data Value, with the name `system_domain` to be of type **string** with the default value of an empty string (i.e. `""`).

---
## Implying Types

In `ytt` Schema types of Data Values are _inferred_ from the values given. So, when one writes schema, they are _implying_ the type of each Data Value through the default value they give.

For example:
```yaml
#@data/values-schema
---
system_domain: ""

load_balancer:
  enabled: true
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

effectively declares the following data values:
- `system_domain` — a string
- `load_balancer` — a map containing two items:
    - `enabled` — a boolean
    - `static_ip` — a string
- `app_domains` — an array of strings (and only strings)
- `databases` — an array where each element is a map. Each map has exactly six items:
    - `name` — a string
    - `adapter` — a string
    - `host` — a string
    - `port` — an integer
    - `user` — a string
    - `secretRef` — a map having exactly one item:
        - `name` — a string

_(see [Data Values Schema Reference: Types](lang-ref-ytt-schema.md#types) for details.)_

---
## Setting Default Values

In `ytt` Schema, the default value for a Data Value is almost always simply the value specified.

From the example, [above](#implying-types), the corresponding Data Values have the following defaults:
- `system_domain` is empty string (i.e. `[]`),
- `load_balancer.enabled` is `true`, and
- `load_balancer.static_ip` initializes to empty string.

**Special Case: Arrays**

However, as described in [Data Values Schema Reference: Defaults for Arrays](lang-ref-ytt-schema.md#defaults-for-arrays), the two arrays, `app_domains` and `databases` are each an empty list (i.e. `[]`) by default.

That said, when an item is added to `database`, each item will...
- `adapter` defaulting to `"postresql"`,
- `port` to `5432`, and
- `user` initialized to `"admin"`.


For details on how to set individual default values, see [Data Values Schema Reference: Default Values](lang-ref-ytt-schema.md#default-values).

---
## Specific Use-Cases

A few less common, but real-world scenarios:

- [setting a default value for arrays](#setting-a-default-value-for-an-array)
- [marking a Data Value as optional](#marking-a-data-value-as-optional)
- [allowing multiple types of maps or arrays](#allowing-multiple-types-of-maps-or-arrays)
- [declaring "pass-through" Data Values](#declaring-pass-through-data-values)

### Setting a Default Value for an Array

As explained in [Data Values Schema Reference: Defaults for Arrays](lang-ref-ytt-schema.md#defaults-for-arrays), the default value for an array is an empty list (i.e. `[]`).

In some cases, it is useful to provide a non-empty default value for an array. To do so, one typically uses a Data Values overlay.

For example, with this schema:

```yaml
#@data/values-schema
---
app_domains:
- ""
```

and this Data Values overlay:

```yaml
#@data/values
---
app_domains:
- apps.cf-apps.io
- mobile.cf-apps.io
```

The default value for `app_domains` will be `["apps.cf-apps.io", "mobile.cf-apps.io"]`.

### Marking a Data Value as Optional

Sometimes, it can be useful to define a section of Data Values as optional. This typically means that templates that rely on those values conditionally include output that use the contained value.

For example, the following template:
```yaml
#@ load("@ytt:data", "data")
---
...
spec:
  #@ if data.values.load_balancer:
  loadBalancerIP: #@ data.values.load_balancer.static_ip
  #@ end
...
```
will only include `spec.loadBalancerIP` if a value is provided for the `load_balancer` Data Value.

One notes this in Schema using the `@schema/nullable` annotation:

```yaml
#@data/values-schema
---
#@schema/nullable
load_balancer:
  static_ip: ""
```

which indicates that `load_balancer` is `null`, by default. However, if a value _is_ provided for `load_balancer`, it must be the `static_ip` and have a value that is a **string**.

For more details see [Data Values Schema Reference: `@schema/nullable`](lang-ref-ytt-schema.md#schemanullable).

### Allowing Multiple Types of Maps or Arrays

In rare cases, a given Data Value needs allow more than one type.

Currently, `ytt` Schema does not explicitly support specifying more than one type for a Data Value.

In the meantime, one can mark such types as having any type:

```yaml
#@schema/type any=True
int_or_string: ""
```
so that:
- `int_or_string` is, by default, an empty string
- it can accept an **integer** or a **string** ... or any other type.

If it is critical to ensure that the type of `int_or_string` to be _only_ an integer or string, one can include a validating library that does so explicitly:

```python
load("@ytt:assert", "assert")
load("@ytt:data", "data")

if type(data.value.int_or_string) not in ("int", "string"):
  assert.fail("'int_or_string' must be either an integer or a string.")
end
```

### Declaring "Pass-through" Data Values

In certain cases, one designs a Data Value to carry a chunk of YAML whose exact type or shape is unimportant to templates.




---
## Next Steps
