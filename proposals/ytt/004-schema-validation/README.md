---
title: "Validations"
authors: [ "John S. Ryan <ryanjo@vmware.com>" ]
status: "draft"
approvers: []
---


# Validations

- [Problem Statement](#problem-statement)
- [Terminology / Concepts](#terminology--concepts)
- [Proposal](#proposal)
  - [Use Cases](#use-cases)
  - [Specification](#specification)
  - [Open Questions](#open-questions)
  - [Answered Questions](#answered-questions)
  - [Complete Examples](#complete-examples)
  - [Other Approaches Considered](#other-approaches-considered)
- [Implementation Considerations](#implementation-considerations)

## Problem Statement

To date, ytt Library / Carvel Package **authors have had to "roll their own" logic to check that customer's inputs are valid.** That is: that data values are a) present/non-empty; and b) within expected range(s).

Given the expressiveness of Starlark, producing the actual logic, itself, is not too onerous.

However, Authors have had to...
- write the "plumbing" code around validations (or offer their consumers a degraded UX):
    - collecting all violations (instead of failing on first violation)
    - ordering validation evaluation — leaves to root
    - handling common scenarios (empty values, enums, unions, conditional)
- hand-document validations by adding comments to their Data Values (Schema) describing those constraints.
    - it's double the work
    - there are now two places that need to be updated whenever a constraint changes (see [Shalloway's Law](https://netobjectivesthoughts.com/shalloways-law-and-shalloways-principle/#:~:text=%E2%80%9CWhen%20N%20things%20need%20to,%2D1%20of%20these%20things.%E2%80%9D&text=It's%20a%20law!)).

**The time our users spend in developing and maintaining this code, is time lost to making progress in their first-order work.**

In the Kubernetes space, as cluster deployments become **increasingly complex**, the need to **vet declarative configuration becomes ever more critical**. Users are rightfully expecting their tooling to help them catch errors as early as possible, out-of-the-box.

## Terminology / Concepts

- **assertion** — a function that — given a value — if the value meets the assertion's criteria, quietly succeeds, but if the value fails the criteria, fails.
- **CEL** — [Common Expression Language](https://github.com/google/cel-spec) — language supported (in alpha) by Kubernetes for CRD validation rules.
- **module** — a file that can be loaded into a template in order to reuse its functions (or variables). The `ytt` "Standard Library" is comprised of modules that begin with the `@ytt:` prefix (e.g. @ytt:data, @ytt:assert, @ytt:overlay, ...) 
- **node** — a single piece of YAML: a document set, document, map, map item, array, array item. One "annotates" a node by placing a `ytt` annotation-shaped comment just above the node (see also: [YAML Primer](https://carvel.dev/ytt/docs/v0.39.0/yaml-primer/)).
- **required value** — a Data Value that the consumer must set. Mechanically, a Data Value that does not (yet) have a value that is "valid."
- **rule** — the combination of: 
    - a textual description of what constitutes a valid value;
    - a function that asserts the rule against an actual value;
    - a violation message template, used to report invalid values.
    - **custom rule** — a rule based on a function (either one written by a user or provided in a `ytt` module).
    - **named rule** — a rule provided with `ytt` expressed through a keyword argument to an `@schema/validation` or `@assert/validate`.
- **schema base document** — the document instantiated from a schema; when the schema describes Data Values, it is the annotated default data values document.
- **validation** — the binding of one or more "rule"s to a "node".
- **violation** — an instance of where a given value of a "node" fails a "validation".

## Proposal

Implement all plumbing logic required to provide high-quality data validation over Data Values and output documents.

Mechanically, this means:

Extend `@schema/...` to be able to annotate validations in schema:
- introduce `@schema/validation` which attaches a validation to a type.
- when generating default Data Values (generally, the schema base document), when a type has a validation, annotate the corresponding node with an `@assert/validate` with that validation.

Extend the `@ytt:assert` module, to include the ability to validate:
- introduce an annotation (`@assert/validate`) which attaches one or more "rules" to a "node", defining what a valid value is for that node;
- supply a set of common assertions (functions in the `@ytt:assert` module) that covers most validation use-cases;
- provide guidance for how to express most commonly intended validations.

Further, integrate this feature into `ytt`'s processing pipeline:
- immediately after a final Data Values is calculated for a library, automatically validate that document (and halt processing if there are any violations);
- if the user is inspecting schema, include validations in the output;
- immediately after the Output Document Set (i.e. the final result of evaluating a library) is produced, automatically validate each document in the set (and halt processing if there are any violations).

Finally, achieve all this in a way that complements existing validation tooling:
- be 100% compatible with Kubernetes validation facilities (i.e. OpenAPI v3 / JSON Schema validations + [Kubernetes Validation Rules](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#validation-rules)).

Deliver this functionality in the following increments:

1. core validation plumbing, integrated into Schema, (at least) minimum set of built-in validations.
2. include validations in exports to OpenAPI v3 formatted Schema "inspect" / exports.
3. address advanced use-cases by adding the ability to edit annotations in the overlay module.
4. integrate evaluating validations in output documents.

### Use Cases

Specific scenarios within the overall job of validating data include:

- [Ensure consumer provides a value (Required Input)](#use-case-required-input)
  - [... when the data value is a type that has length](#required-input-for-types-with-length)
  - [... when the data value is a type that has an empty value](#required-input-for-types-with-empty-value)
  - [... for all other cases](#required-input-for-types-with-no-empty-value)
- [Require value to be from a defined set (Enumeration)](#use-case-enumeration)
- [Sections of configuration are mutually exclusive (Union Structures)](#use-case-union-structures)
- [Validations involving multiple Data Values (Multiple Nodes)](#use-case-multiple-nodes)
- [Validate nullable Data Values](#use-case-validations-over-nullables)
- [Apply validations in specific situations (Conditional Validations)](#use-case-conditional-validations)
- [Disable all validations in an "emergency" (Disable Validations)](#use-case-disable-validations)
- [Reuse a set of validations over a commonly-shaped set of Data Values (Programatic Validations)](#use-case-programmatic-validations)
- [Export Schema in OpenAPI v3 format](#use-case-exporting-schema-in-openapi-format)
- [Validate an output document](#use-case-validating-an-output-document)

The following sections detail each use case, in turn...

#### Use Case: Required input

When the author cannot/will not provide a default value for a data value and requires the consumer to provide it.

Where possible, authors are encouraged to use a type-specific "non-empty" validation. As a fallback, they may opt for nullable+not_null.

##### Required input for types with length

**String Values**

The recommended way for an author to indicate required string input is to expect a non-empty string:

```yaml
#@data/values-schema
---
dex:
  #@schema/validation min_len=1
  namespace: ""
  #@schema/validation min_len=1
  username: ""
```

This case is so common (it is our understanding that most string-based data values are meant to be non-empty), we offer this convenience:

```yaml
#@data/values-schema
#@schema/validation-defaults-for-strings min_len=1
---
dex:
  namespace: ""
  username: ""
```

Which is equivalent to the prior example, but applies the default to any descendent that contains a string-typed value. If a particular node already has an `@assert/validate` annotation, it is skipped.

**Array Values**

Similarly, a non-empty value of an array has at least one element:

```yaml
#@data/values-schema
---
dex:
  oauth2:
    #@schema/validation min_len=1
    responseTypes:
    - ""
```

Array-typed values are less common. And when present are not necessarily _as_ common to require a non-empty value as string-typed values. So, there is no corresponding shorthand annotation for requiring a non-empty array.


##### Required input for types with empty value

For some integer-typed (or float-typed) data values, a zero value may be invalid and thus can represent "empty".

```yaml
#@data/values-schema
dex:
  #@schema/validation min=1024, max=65535
  port: 0
```

Authors are encouraged to favor this approach over [marking the data values as nullable](#required-input-for-types-with-no-empty-value) to keep their schema as simple as possible.
 
##### Required input for types with no empty value

Some types have no natural (or easily detectable) "empty" value. In these cases, authors can force the consumer to supply a value by marking the value as "nullable" and constraint it to be "not null":

```yaml
#@data/values-schema
---
#@schema/nullable
#@schema/validation not_null=("Cloud credentials are required.", True)
credential:
  name:
  secretContents:
    cloud:
```

_(also considered: [`@schema/required`](#schemarequired))._

#### Use Case: Enumeration

Values can be constrained to be one of a finite site (i.e. of an enumeration).

```yaml
#@data/values-schema
---
volumeSnapshotLocation:
  spec:
    #@schema/validation one_of=["aws", "azure", "vsphere"]
    provider: ""
```

#### Use Case: Union Structures

An author can require that exactly one of a set of sibling node has a value:

```yaml
#@data/values-schema
---
dex:
  #@schema/validation one_not_null=["oidc", "ldap"]
  config:
    #@schema/nullable
    oidc:
      CLIENT_ID: null #! required if oidc enabled
      CLIENT_SECRET: null #! required if oidc enabled
      issuer: null #! <OIDC_IDP_URL> is required if oidc enabled
    #@schema/nullable
    ldap:
      host: null #! <LDAP_HOST> is required if ldap enabed
      bindDN: null
      bindPW: null
```

This approach is simpler than (and therefore recommended over) using a discriminator:

```yaml
#@data/values
---
dex:
  config:
    type: "oidc"
    oidc:
      CLIENT_ID: null #! required if oidc enabled
      CLIENT_SECRET: null #! required if oidc enabled
      issuer: null #! <OIDC_IDP_URL> is required if oidc enabled
    ldap:
      host: null #! <LDAP_HOST> is required if ldap enabed
      bindDN: null
      bindPW: null
```

#### Use Case: Multiple Nodes

When a validation involves more than just one Node's value:

```python
def validate_registry():
 if data.values.persistence.imageChartStorage.type == "filesystem":
   if data.values.persistence.persistentVolumeClaim.registry.accessMode == "ReadWriteOnce":
     data.values.registry.replicas == 1 or assert.fail("The registry replicas must be 1 when the image storage is filesystem and the access mode of persistentVolumeClaim is ReadWriteOnce")
   end
 end
end
```
(ref: [vmware-tanzu/community-edition/.../harbor/2.2.3/config/values.star](https://github.com/vmware-tanzu/community-edition/blob/cc7eb24b0e13875a06ac8578cd73f83a217ec4d9/addons/packages/harbor/2.2.3/bundle/config/values.star#L45-L53))

The author places the validation at the lowest-common parent Node:

```yaml
#@ def one_registry_if_pvc_is_filesystem(val):
#@   if val.persistence.imageChartStorage.type == "filesystem" and
#@      val.persistence.persistentVolumeClaim.registry.accessMode == "ReadWriteOnce":
#@      return val.registry.replicas == 1 \
#@          or (False, "There can be only one registry replica when the image storage is filesystem and the access mode of persistentVolumeClaim is ReadWriteOnce; there are {} replicas.".format(val.registry.replicas))
#@   end
#@ end

#@data/values-schema
#@schema/validation ("There should be exactly one (1) registry replica if Helm Charts are stored on the filesystem.", one_registry_if_pvc_is_filesystem)
---
persistence:
  imageChartStorage:
    type: filesystem
  persistentVolumeClaim:
    registry:
      accessMode: ReadWriteOnce
registry:
  replicas: 2
```

Note: the `@ytt:data` module's `data.values` struct is _not_ populated until _after_ the Data Values Pre-Processing phase is complete.  As such, the `data.values` variable is not useful within validations.

Authors are encouraged to minimize their use of this technique: it fixes the location of data values making it more expensive to reorganize them.

#### Use Case: Validations over Nullables

Whenever a node is annotated `@schema/nullable`, then its default value is `null`.

```yaml
#@data/values-schema
---
#@schema/validation min=42, max=42
#@schema/nullable
foo: 13
```

By default, validations are skipped when the actual value is `null`. Authors can insist that validations are run by including the `not_null=` rule:

```yaml
#@data/values-schema
---
#@schema/validation min=42, max=42, not_null=True
#@schema/nullable
foo: 13
```

When present, the `not_null=` rule runs first. If it fails, all other rules are guaranteed to fail, so they are not run.

_(also considered: [Opt-out of skipping validations when value is `null`](#opt-out-of-skipping-validations-when-value-is-null))_
_(also considered: [automatically including `when_null_skip` when Data Value is nullable](#automatically-including-when_null_skip-for-nullable-data-values))._

When the author has set the Data Value as "nullable" with the intent to require the consumer to supply their own value, this is the [Required Input (for types with no empty value)](#required-input-for-types-with-no-empty-value) use case.

This keyword is a special case of [`when=`](#use-case-conditional-validations) because it is so common.

#### Use Case: Conditional Validations

The author can short-circuit validations under certain conditions:

```yaml
#@data/values-schema
---
#@schema/validation ("", valid_service_config), when=lambda v: v.enabled
service:
  enabled: true
  type: NodePort
```

Before any validations are checked, the value of `when=` (itself being a validation) is checked.\
If `false`, then none of the other validations are checked and the value is assumed "valid."

Here, the contents of the `service:` are validated (via `valid_service_config()`) only if `service.enabled` is `true`.

Similarly, the validation can be dependent on _other_ data values.

```yaml
#@data/values-schema
---
service:
  enabled: true
  #@schema/validation one_of=["NodePort", "LoadBalancer"], when=lambda _, ctx: ctx.parent["enabled"]
  type: NodePort
```

#### Use Case: Disable Validations

A consumer can skip validating Data Values:

```console
$ ytt ... --data-value-schema-disable-validation
```

or the programmatic equivalent:

```python
lib.eval(data_value_schema_disable_validation=True)
```

Likewise, a consumer can skip validating output documents:

```console
$ ytt ... --output-disable-validation=True
```

or the programmatic equivalent:

```python
lib.eval(output_disable_validation=True)
```

#### Use Case: Programmatic Validations

> **TODO:**
- [ ] briefly talk through how common structures themselves are best duplicated _or_ captured in a fragment function — including validations

_(Also considered: [programmatically invoking multiple validations](#programmatically-invoking-multiple-validations).)_


#### Use Case: Exporting Schema in OpenAPI format

> **TODO:**
> - [ ] detail how rule descriptions are included in documentation.
> - [x] for each OpenAPI/JSON Schema validation keyword, show exactly how that would be expressed in `ytt` validation.
> - [ ] describe the fallback strategy where authors can represent their rule where there _is_ no OpenAPI equivalent.
> - [ ] Incorporate feedback about key schema needs
>       > Maybe these have already been added and I haven't been paying attention, but are there equivalents for the following in OpenAPI schema:
>       > ```yaml
>       > labelSelector:
>       >   type: object
>       >     properties:
>       >       matchLabels:
>       >         type: object
>       >         x-kubernetes-preserve-unknown-fields: true
>       >         additionalProperties:
>       >           type: string
>       > ```
>       > 
>       > That is:
>       > additionalProperties so can force values must be of certain type in an object.
>       > x-kubernetes-preserve-unknown-fields so can allow any number of keys in object.
>       > These are the two main things I would care about.

When the user inspects the schema:

```
$ ytt ... --data-values-schema-inspect -o openapi-v3
```

Validations defined on schema are included in that export.

##### OpenAPI v3 / JSON Schema validation keywords:

Supported (ytt rule ==> OpenAPI v3 / JSON Schema property):
- `max=` / `@ytt:assert.max()` ==> [maximum](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.2)
- `min=` / `@ytt:assert.min()` ==> [minimum](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.4)
- `max_len=` / `@ytt:assert.max_len()`:
  - type: `string` ==> [maxLength](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.6)
  - type: `array` ==> [maxItems](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.10)
  - type: `map` ==> [maxProperties](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.13)
- `min_len=` / `@ytt:assert.min_len()`:
  - type: `string` ==> [minLength](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.7)
  - type: `array` ==> [minItems](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.11)
  - type: `map` ==> [minProperties](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.14)
- `one_of=` / `@ytt:assert.one_of()`: [enum](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.20)
- `format=` / `@ytt:assert.format()` : [format](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-7) \
   Format names are identical:
  - [date-time](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-7.3.1)
  - [email](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-7.3.2)
  - [hostname](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-7.3.3)
  - [ipv4](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-7.3.4)
  - [ipv6](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-7.3.5)
  - [uri](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-7.3.6)
  - [uriref](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-7.3.7)
- `multiple_of=` / `@ytt:assert.multiple_of()` : [multipleOf](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.1)

The following are deferred:

- uniqueItems
- exclusiveMaximum (is this useful?)
- exclusiveMinimum (is this useful?)
- pattern (This string SHOULD be a valid regular expression, according to the ECMA 262 regular - expression dialect)

The following JSON Schema properties are better supported as part of `ytt` schema:
- [items](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.9)
- [additionalItems](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.9)
- [additionalProperties](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.18)

The following are references to JSON Schema and will not be generated:
- [properties](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.16)
- [patternProperties](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.17)
- [dependencies](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.19)
- [allOf](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.22)
- [anyOf](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.23)
- [not](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.25)
- [oneOf](https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00#section-5.24)

References:
- https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#schemaObject
- https://262.ecma-international.org/5.1/#sec-7.8.5
- https://datatracker.ietf.org/doc/html/draft-wright-json-schema-validation-00 

#### Use Case: Exporting Schema with Kubernetes Extensions

> **TODO:**
- [ ] consider how to allow for or translate `ytt` validations to CEL rules. (directly support CEL?)


#### Use Case: Validating an output document

> **TODO:**
> - [ ] illustrate validating a YAML document from within template code.

A template author can help ensure that not just the inputs, but also the final output is valid.

```yaml
#@ load("@ytt:assert", "assert")

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  #@assert/validate max=4
  replicas: #@ calc_replicas()
  selector:
    matchLabels: #@ labels()
  template:
    metadata:
      #@assert/validate ("Istio sidecar inbound port must be present and >= 9000", lambda v: ("excludeInboundPorts" in v) and int(v["excludeInboundPorts"]) > 9000)
      annotations:
        excludeInboundPorts: #@ "{}".format(data.values.istioPortLimit)
      labels: #@ labels()
    spec:
      containers:
        - name: nginx
          image: nginx:1.14.2
          ports:
            - containerPort: 80

```

Note: in order for validations to be applied via an overlay in any practical way, we would need to [define merge semantics of annotations in overlays](#consideration-defining-merge-semantics-for-annotations-in-an-overlay).

Sources:
- [cloudfoundry/cf-for-k8s/tests](https://github.com/cloudfoundry/cf-for-k8s/tree/95c77d741706ab2a27979db90873fb4461a1ac3c/tests)

### Specification

#### @assert/validate

Defines validity for the value of the annotated node.

```
@assert/validate [rule0, rule1, ...] [,<named-rules>] [,when=]
```

where:
- `ruleX` — any number of custom rules: a tuple `(description, assertion, [message])`  
  - `description` (`string`) — a description of what a valid value is.
  - `assertion` (`function(value) : None` | `function(value) : bool`) — that either `assert.fail()`s or returns `False` when `value` is not valid.
    - `value` (`string` | `int` | `float` | `bool` | [`yamlfragment`]()) — the value of the annotated node.
  - `message` (`string`) — (optional) overrides the default violation message with a custom template in [`string.format()`](https://github.com/google/starlark-go/blob/bb14e15/doc/spec.md#stringformat) syntax supplied with the following fields:
    - `{key}` — the key portion of the map item (or index if an array item or document).
    - `{value}` — the value of the annotated node (supplied as [`repr(value)`](https://github.com/google/starlark-go/blob/bb14e15/doc/spec.md#repr))
    - `{desc}` — the description supplied in the 0th item in this rule.
    - `{failure}` — when `assertion` fails, the message from that `assert.fail()` or empty string.
- `<named-rules>` — any of the keyword arguments described in [Named Rules](#named-rules), below.
- `when=` (`function(value[, context]) : bool`) — criteria for when the validation rules should be checked. If the criteria is met (function returns `True`), the validations are checked; otherwise (function either returns `False` or `assert.fail()`s, none of the validations are checked.

Each rule is evaluated, in the order they appear in the annotation (left-to-right):
- if all rules pass (either returns `True` or `None`), then the value is valid.
- if a rule returns `False` (not `None`) or `assert.fail()`s, then the valid is invalid.

The default `message` is: 
```
\"{key}\" requires a valid value: {desc}; {failure}.
```
- centering around the word "...requires..." helps the message work both in the case where the consumer supplied no value (see [Use Case: Required input](#use-case-required-input)) _and_ when they supplied an invalid value.
- `{value}` is omitted to not contribute to the risk of leaking secrets.

> **Note** \
> Examples below illustrate how an author would specify a validation (using `@schema/validation`) that becomes an `@assert/validate` as this is the driving use case at this time.

_Example 1: Named rules_

```yaml
#@data/values-schema
---
#@schema/validation min=49142 max=65535
adminPort: 1024
```
which yields a schema base document:
```yaml
---
#@assert/validate min=49142 max=65535
adminPort: 1024
```

_Example 2: Custom assertion-based rule_

```yaml
#@data/values-schema
---
#@ def is_dynamic_port(n):
#@   n >= 49142 and n <= 65535 or assert.fail("{} is not in the dynamic port range".format(n))
#@ end

#@schema/validation ("a TCP/IP port in the \"dynamic\" range: 49142 and 65535, inclusive", is_valid_port)
adminPort: 1024
```
which yields a schema base document:
```yaml
---
#@assert/validate ("a TCP/IP port in the \"dynamic\" range: 49142 and 65535, inclusive", is_valid_port)
adminPort: 1024
```

Yields:
> "adminPort" requires a valid value: a TCP/IP port in the "dynamic" range: 49142 and 65535, inclusive; 1024 is not in the dynamic port range.

_Example 3: Custom violation message_

```yaml
#@data/values-schema
---
#@ def is_dynamic_port(n):
#@   n >= 49142 and n <= 65535 or assert.fail("{} is not in the dynamic port range".format(n))
#@ end

#@schema/validation ("a TCP/IP port in the \"dynamic\" range: 49142 and 65535, inclusive", is_valid_port, "\"{key}\" (={value}) must be between 49142 and 65535")
adminPort: 1024
```
which yields a schema base document:
```yaml
---
#@assert/validate ("a TCP/IP port in the \"dynamic\" range: 49142 and 65535, inclusive", is_valid_port, "\"{key}\" (={value}) must be between 49142 and 65535")
adminPort: 1024
```


Yields:
> "adminPort" (=1024) must be between 49142 and 65535

_Example 4: Custom predicate-based rule_

```yaml
#@data/values-schema
---
#@ def is_valid_port(n):
#@   return n >= 49142 and n <= 65535
#@ end

#@schema/validation ("A TCP/IP port in the \"dynamic\" range: 49142 and 65535, inclusive", is_valid_port)
adminPort: 1024
```
which yields a schema base document:
```yaml
---
#@assert/validate ("A TCP/IP port in the \"dynamic\" range: 49142 and 65535, inclusive", is_valid_port)
adminPort: 1024
```

Yields:
> "adminPort" requires a valid value: a TCP/IP port in the "dynamic" range: 49142 and 65535, inclusive; \"is_valid_port()\" returned False."

Note that `ytt` detects that `is_valid_port()` returns a false-y value and formats `{failure}` as `\"{key}\" returned False.`

> **TODO:**
> - [ ] determine how anonymous functions (e.g. lambdas) can be effectively referred (e.g. "third rule"?)

##### Named Rules

A number of rules are so common that in addition to their function form, they warrant a shorthand in the form of a keyword argument.

They are:
- `min_len=` (see [`@ytt:assert.min_len()`](#yttassertmin_len))
- `max_len=` (see [`@ytt:assert.max_len()`](#yttassertmax_len))
- `min=` (see [`@ytt:assert.min()`](#yttassertmin))
- `max=` (see [`@ytt:assert.max()`](#yttassertmax))
- `one_of=` — enumeration (see [`@ytt:assert.one_of()`](#yttassertone_of))
- `not_null=` (see [`@ytt:assert.not_null()`](#yttassertone_not_null))
- `one_not_null=` — union structure (see [`@ytt:assert.one_not_null()`](#yttassertone_not_null))

General-purpose string assertions:
- `starts_with=` (see [`@ytt:assert.starts_with()`](#yttassertstarts_with))
- `ends_with=` (see [`@ytt:assert.ends_with()`](#yttassertends_with)) — e.g. ".git" for a git source in GitOps CRDs in a CI/CD system.
- `contains=` (see [`@ytt:assert.contains()`](#yttassertcontains)) — e.g. registry name within a URL, "@sha" to validate an image reference is digest-resolved.
- `matches=` (see [`@ytt:assert.matches()`](#yttassertmatches))
- `format=` (see [`@ytt:assert.format()`](#yttassertformat))

Kubernetes-common:
- `even=` (see [`@ytt:assert.even()`](#yttasserteven)) — e.g. memory resources should be even.
- `odd=` (see [`@ytt:assert.odd()`](#yttassertodd)) — e.g. replicas should be odd numbers in stateful applications.
- `multiple_of=` (see [`@ytt:assert.multiple_of()`](#yttassertmultiple_of)) — e.g. memory sizes ought to be multiples of 1024

###### Named rule arguments

The argument of a named rule can either be just the value:
```
@assert/validate min_len=1
username: ""
```
and invalid values with be reported with the underlying validation's default violation message.

> `"username" requires a valid value (a length of at least 1); it is a length of 0.`


The value can also be a tuple of a custom definition of a valid value, along with the value:
```
@assert/validate min_len=("a non-empty string", 1)
username: ""
```

> `"username" requires a valid value (a non-empty string); it is a length of 0.`

Note: if an author wishes to provide a custom violation message, they would use the corresponding built-in rule as a custom rule.

#### @ytt:assert.validate()

Programmatically asserts that a given value is valid based on the set of supplied rules.

```python
assert.validate(key, value, rule0, rule1, ... [,<named-rules>] [,when=]
```
where:
- `key` (`string`) — the name of the value being validated.
- `value` (any) — the value being validated.

This function is the programmatic equivalent of [@assert/validate](#assertvalidate).

#### @ytt:assert.valid()

Asserts any validations present on a Node (and descendents).

```python
assert.valid(node)
```

- if all validation rules are satisfied, nothing happens.
- all violated validation rules result ..., `assert.fail()`s with the corresponding validation message(s).
  - `violations` (`list`)


#### Included Assertion Functions

- the functions in this section are technically higher-order functions that _produce_ assertions:
    ```python
    def assert.min(x):
      return lambda v: assert.fail("at least {}", x) if v >= x else None
    end
    ```
    of which the return value _is_ an assertion.
- violation messages should be consistent across these functions.
- these functions should attempt to support as many types as possible:

##### @ytt:assert.contains()

##### @ytt:assert.ends_with()

##### @ytt:assert.even()

##### @ytt:assert.format()

Supported formats:
- "quantity" — https://kubernetes.io/docs/reference/glossary/?all=true#term-quantity
- Additional keywords will be added as needs are clear. Likely candidates come from common domain-specific formats:
[JSON Schema Validation: §7 Vocabularies for Semantic Content With "format"](https://json-schema.org/draft/2020-12/json-schema-validation.html#rfc.section.7).

##### @ytt:assert.len()

The length of the value is _exactly_ that of the given length.

##### @ytt:assert.matches()

##### @ytt:assert.max()

The value is _at most_ (inclusive) of the given minimum.

##### @ytt:assert.max_len()

The length of the value is _at most_ (inclusive) that of the given minimum.


##### @ytt:assert.min()

The value is _at least_ (inclusive) of the given minimum.

##### @ytt:assert.min_len()

The length of the value is _at least_ (inclusive) that of the given minimum.

##### @ytt:assert.multiple_of()

##### @ytt:assert.not_null()

When present, this validator is always checked first.

##### @ytt:assert.odd()

##### @ytt:assert.one_not_null()

##### @ytt:assert.one_of()

##### @ytt:assert.starts_with()

#### @schema/validation

Attaches a validation to the type being declared by the annotated node.

```
@schema/validation [rule0, rule1, ...] [,<named-rules>] [,when=]
```

When the schema base document is generated, the corresponding node is annotated with `@assert/validate` with the same configuration provide _this_ annotation.

See [@assert/validate](#assertvalidate) for details about arguments to this annotation.

#### @schema/validation-defaults-for-strings

> **TODO:**
> - [ ] firm-up name of this annotation: is it a bug or a feature that it is type-specific?

Defines what a valid value is for all descendants which hold a "string" value.

```
@schema/validation-defaults-for-strings [rule0, rule1...] [,<named-rules>] [,when=]
```

See also: [Consideration: Setting validation defaults for strings in a schema overlay](#consideration-setting-validation-defaults-for-strings-in-a-schema-overlay).
#### Custom Validation Functions

> **TODO:**
> - [ ] Determine: does more need to be specified about these kinds of functions? Or are descriptions from elsewhere sufficient?
#### Consideration: Order of Validations

Validations are checked, leaf-upwards: a parent value can't be valid if one of its children are invalid.

#### Consideration: Merging Validations on Schema Nodes

Some preliminary design work has been done describe how to augment the Overlay module to better support editing of annotations.  (see [Defining merge semantics for annotations in an overlay](#consideration-defining-merge-semantics-for-annotations-in-an-overlay) for details).

However, for the few that find themselves in a situation where they need to edit existing schema, they have workarounds
available with existing mechanisms:
- one can knock-out any overly-constraining validation by writing an overlay that removes the existing node and subsequently replaces it with a node that has the desired annotations.
- if all else fails, one can supply a "valid" input and then override the desired output value via an overlay (over templated result).

### Open Questions

1. **Q:** How are `one_not_null` expressed in CRDs (or built-in types) e.g. go look at Volumes (for each array item). \
   https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/_print/#validation
2. **Q:** `@schema/validation-defaults-for-strings` feels overly specific; is there a way to both generalize the notion of defaulting while keeping a reasonable syntax?
3. **Q:** in the case where a function is placed higher up on the tree, but really the value being checked is one of the children, should we give the facility to be able to name the path of the target key? In this way, the violation message can be associated with the child (as well).
4. **Q:** When evaluating a private library, should validations be _automatically_ evaluated?
5. **Q:** Should we provide a "break-the-glass" means of capturing a form of a validation in CEL?

### Answered Questions

1. **Q:** (backwards compatibility) should we be validating against non-empty strings, by default? \
   **A:** no, there's no known way to do this without creating a breaking change. Instead, we'll provide a convenient 
2. **Q:** Should we accept more than one `@assert/validate` annotation (to make it easier to stack them)?
    - what happens today when we have multiple instances? (merge vs. replace behavior)
    - what would it mean to have multiple annotation of other kinds?
    - ideally, this is a generic rule about how annotations merge
    - if an annotation is applied at the doc level, how does that work when merging to an existing schema? (think string defaults to min_len=0) 

   **A:** No. These scenarios can be deferred until a general mechanism for editing annotations within an overlay are worked out.
3. **Q:** Should keyword argument validations perform type-checking? \
   **A:** No. Given that schema will type-check values _before_ applying validations, it's a rare case when the author will place the wrong validation on a data value and not realize it. This is likely unnecessary complexity.
4. **Q:** Are there any special considerations for libraries of validations? (e.g. Kubernetes, cloud-provider specific values) \
   **A:** If we ensure that we map well to Kubernetes validation features, 

### Complete Examples

- https://github.com/vmware-tanzu/community-edition/tree/main/addons/packages
    - https://github.com/vmware-tanzu/community-edition/blob/cc7eb24b0e13875a06ac8578cd73f83a217ec4d9/addons/packages/harbor/2.2.3/bundle/config/values.star
    - https://github.com/vmware-tanzu/community-edition/blob/cc7eb24b0e13875a06ac8578cd73f83a217ec4d9/addons/packages/vsphere-cpi/1.22.4/bundle/config/values.star
    - https://github.com/vmware-tanzu/community-edition/blob/cc7eb24b0e13875a06ac8578cd73f83a217ec4d9/addons/packages/velero/1.6.3/bundle/config/values.star
    - https://github.com/vmware-tanzu/community-edition/blob/cc7eb24b0e13875a06ac8578cd73f83a217ec4d9/addons/packages/pinniped/0.12.0/bundle/config/upstream/_ytt_lib/supervisor/helpers.lib.yaml
- https://github.com/vmware-tanzu/tanzu-framework
    - https://github.com/vmware-tanzu/tanzu-framework/blob/2b3c557f5651a0bfe79dac1b19e12d5925178bef/pkg/v1/providers/ytt/lib/validate.star
        - e.g. `validate_configuration()` used by https://github.com/vrabbi/tkg-resources/blob/0e302afc87997bee8312cc7da25b76815ea01b0c/TKG%20Customization/tkg/providers/infrastructure-vsphere/v0.7.1/ytt/overlay.yaml
- https://github.com/cloudfoundry/cf-for-k8s/blob/develop/config/get_missing_parameters.star
- String values that are typically/ok to be empty by default: https://github.com/tomkennedy513/carvel-package-kpack/blob/main/config/schema.yaml

#### Harbor

From:
- vmware-tanzu/community-edition//addons/packages/harbor/2.2.3/bundle/
  - [config/values.yaml](https://github.com/vmware-tanzu/community-edition/blob/cc7eb24b0e13875a06ac8578cd73f83a217ec4d9/addons/packages/harbor/2.2.3/bundle/config/values.yaml)
  - [config/values.star](https://github.com/vmware-tanzu/community-edition/blob/cc7eb24b0e13875a06ac8578cd73f83a217ec4d9/addons/packages/harbor/2.2.3/bundle/config/values.star)

To:

```yaml
#@ load("@ytt:assert", "assert")
#@
#@ def one_registry_if_pvc_is_filesystem(val):
#@   if val.persistence.imageChartStorage.type == "filesystem" and
#@      val.persistence.persistentVolumeClaim.registry.accessMode == "ReadWriteOnce":
#@      return val.registry.replicas == 1 \
#@          or assert.fail("{} replicas are configured".format(val.registry.replicas))
#@   end
#@ end

#@data/values-schema
#@schema/validation ("There can be exactly one (1) registry replica if Helm Charts are stored on the filesystem.", one_registry_if_pvc_is_filesystem)
#@schema/validation-defaults-for-strings min_len=1
---
#@schema/desc "The namespace to install Harbor"
namespace: harbor

#@schema/desc "The FQDN for accessing Harbor admin UI and Registry service."
#@schema/validation min_len=1, format="hostname"
hostname: harbor.yourdomain.com
#@schema/desc "The network port of the Envoy service in Contour or other Ingress Controller."
port:
  #@schema/validation min=1, max=65535
  https: 443

#@schema/desc "The log level of core, exporter, jobservice, registry."
#@schema/validation one_of=["debug", "info", "warning", "error", "fatal"]
logLevel: info

#@ text = """
#@ The certificate for the ingress if you want to use your own TLS certificate.
#@ We will issue the certificate by cert-manager when it's empty.
#@ """
#@schema/desc text
#@schema/nullable
tlsCertificate:
  #@schema/desc "The certificate"
  tls.crt: ""
  #@schema/desc "The private key"
  tls.key: ""
  #@schema/desc "The certificate of CA, this enables the download link on portal to download the certificate of CA."
  #@schema/validation min_len=0
  ca.crt: ""

#@schema/desc "Use contour http proxy instead of the ingress."
enableContourHttpProxy: true

#@schema/desc "The initial password of Harbor admin."
harborAdminPassword: ""

#@schema/desc "The secret key used for encryption."
#@schema/validation len=16
secretKey: ""

database:
  #@schema/desc "The initial password of the postgres database."
  password: ""

core:
  replicas: 1
  #@schema/desc "Secret is used when core server communicates with other components."
  secret: ""
  #@schema/desc "The XSRF key."
  #@schema/validation len=32
  xsrfKey: ""
jobservice:
  replicas: 1
  #@schema/desc "Secret is used when job service communicates with other components."
  secret: ""
registry:
  replicas: 1
  #@ text = """
  #@ Secret used to secure the upload state from client and registry storage backend.
  #@ See: https://github.com/docker/distribution/blob/master/docs/configuration.md#http
  #@ """
  #@schema/desc text
  secret: ""
notary:
  #@schema/desc "Whether to install Notary"
  enabled: true
  
#@schema/desc "Trivy scanner configuration"
#@schema/nullable
trivy:
  replicas: 1
  #@schema/desc "gitHubToken the GitHub access token to download Trivy DB"
  gitHubToken: ""
  #@ text = """
  #@ The flag to disable Trivy DB downloads from GitHub
  #@  
  #@ You might want to set the value of this flag to `true` in test or CI/CD environments to avoid GitHub rate limiting issues.
  #@ If the value is set to `true` you have to manually download the `trivy.db` file and mount it in the
  #@ `/home/scanner/.cache/trivy/db/trivy.db` path.
  #@ """
  #@schema/desc text
  skipUpdate: false

#@ text = """
#@ The persistence is always enabled and a default StorageClass
#@ is needed in the k8s cluster to provision volumes dynamically.
#@ Specify another StorageClass in the "storageClass" or set "existingClaim"
#@ if you have already existing persistent volumes to use.
#@
#@ For storing images and charts, you can also use "azure", "gcs", "s3",
#@ "swift" or "oss". Set it in the "imageChartStorage" section
#@ """
#@schema/desc text
persistence:
  #@ pvc_existing_claim_desc = "Use the existing PVC which must be created manually before bound, and specify the 'subPath' if the PVC is shared with other components"
  
  #@ pvc_storage_class_desc = """
  #@ Specify the 'storageClass' used to provision the volume. Or the default
  #@ StorageClass will be used(the default).
  #@ Set it to '-' to disable dynamic provisioning
  #@ """
  #@schema/validation-defaults-for-strings min_len=0
  persistentVolumeClaim:
    registry:
      #@schema/desc pvc_existing_claim_desc
      existingClaim: ""
      #@schema/desc pvs_storage_class_desc
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 10Gi
    jobservice:
      #@schema/desc pvc_existing_claim_desc
      existingClaim: ""
      #@schema/desc pvs_storage_class_desc
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
    database:
      #@schema/desc pvc_existing_claim_desc
      existingClaim: ""
      #@schema/desc pvs_storage_class_desc
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
    redis:
      #@schema/desc pvc_existing_claim_desc
      existingClaim: ""
      #@schema/desc pvs_storage_class_desc
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
    trivy:
      #@schema/desc pvc_existing_claim_desc
      existingClaim: ""
      #@schema/desc pvs_storage_class_desc
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 5Gi
      
  #! Specify the type of storage: "filesystem", "azure", "gcs", "s3", "swift", "oss" by filling in the information 
  #! in the corresponding section. 
  #! You must use "filesystem" if you want to use persistent volumes for registry and chartmuseum
  #@schema/validation one_not_null=["filesystem", "azure", "gcs", "s3", "swift", "oss"]
  
  #@ text = """
  #@ Define which storage backend is used for registry and chartmuseum to store
  #@ images and charts. Refer to
  #@ https://github.com/docker/distribution/blob/master/docs/configuration.md#storage
  #@ for the detail.
  #@ """
  #@schema/desc text
  imageChartStorage:
    #@ text = """
    #@ Specify whether to disable `redirect` for images and chart storage, for
    #@ backends which not supported it (such as using minio for `s3` storage type), please disable
    #@ it. To disable redirects, simply set `disableredirect` to `true` instead.
    #@ Refer to
    #@ https://github.com/docker/distribution/blob/master/docs/configuration.md#redirect
    #@ for the detail.
    #@ """
    #@schema/desc text
    disableredirect: false
    #@ text = """
    #@ Specify the "caBundleSecretName" if the storage service uses a self-signed certificate.
    #@ The secret must contain keys named "ca.crt" which will be injected into the trust store
    #@ of registry's and chartmuseum's containers.
    #@ """
    #@schema/desc text
    #@schema/validation min_len=0
    caBundleSecretName: ""

    #@schema/nullable
    filesystem:
      rootdirectory: /storage
      #@schema/nullable
      maxthreads: 100
    #@schema/nullable
    azure:
      accountname: ""
      #@schema/desc "base-64 encoded account key"
      accountkey: ""
      container: ""
      #@schema/validation min_len=0
      #@schema/examples ("Using the default realm", "core.windows.net")
      realm: ""
    #@schema/nullable
    gcs:
      bucket: ""
      #@schema/desc The base64 encoded json file which contains the key
      #@schema/validation min_len=0
      encodedkey: ""
      #@schema/validation min_len=0
      rootdirectory: ""
      chunksize: 5242880
    #@schema/nullable
    s3:
      #@schema/validation one_of=["af-south-1", "ap-east-1", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-southeast-3", "ca-central-1", "eu-central-1", "eu-north-1", "eu-south-1", "eu-west-1", "eu-west-2", "eu-west-3", "me-south-1", "sa-east-1", "us-east-1", "us-east-2", "us-gov-east-1", "us-gov-west-1", "us-west-1", "us-west-2"]
      region: us-west-1
      bucket: ""
      #@schema/examples ("", "awsaccesskey")
      accesskey: ""
      #@schema/examples ("", "awssecretkey")
      secretkey: ""
      #@schema/examples ("Local endpoint", "http://myobjects.local")
      #@schema/validation min_len=0
      regionendpoint: ""
      encrypt: false
      #@schema/examples ("", "mykeyid")
      keyid: ""
      secure: true
      skipverify: false
      v4auth: true
      #@schema/nullable
      chunksize: 0
      #@schema/validation min_len=0
      rootdirectory: ""
      #@schema/validation one_of=["REDUCED_REDUNDANCY", "STANDARD"]
      storageclass: STANDARD
      #@schema/nullable
      multipartcopychunksize: 0
      #@schema/nullable
      multipartcopymaxconcurrency: 0
      #@schema/nullable
      multipartcopythresholdsize: 0
    
    #@schema/validation one_of=["1", "10"]
    #@schema/nullable
    swift:
      #@schema/examples ("Example", "https://storage.myprovider.com/v3/auth")
      authurl: ""
      username: ""
      password: ""
      container: ""
      #@schema/examples ("France", "fr")
      region: ""
      #@schema/examples ("", "tenantname")
      tenant: ""
      #@schema/examples ("", "tenantid")
      tenantid: ""
      #@schema/examples ("", "domainname")
      domain: ""
      #@schema/examples ("", "domainid")
      domainid: ""
      #@schema/examples ("", "trustid")
      trustid: ""
      #@schema/nullable
      insecureskipverify: false
      #@schema/nullable
      #@schema/validation format="quantity"
      #@schema/examples ("Five meg chunks", "5M")
      chunksize: ""
      #@schema/nullable
      prefix: ""
      #@schema/nullable 
      #@schema/examples ("", "secretkey")
      secretkey: ""
      #@schema/nullable 
      #@schema/examples ("", "accesskey")
      accesskey: ""
      #@schema/nullable 
      authversion: 3
      #@schema/nullable 
      #@schema/examples ("", "public")
      endpointtype: ""
      #@schema/nullable 
      tempurlcontainerkey: false
      #@schema/nullable
      tempurlmethods: ""
    #@schema/nullable
    oss:
      #@schema/examples ("", "accesskeyid")
      accesskeyid: ""
      #@schema/examples ("", "accesskeysecret")
      accesskeysecret: ""
      #@schema/examples ("", "regionname")
      region: ""
      #@schema/examples ("", "bucketname")
      bucket: ""
      #@schema/nullable
      endpoint: ""
      #@schema/nullable
      internal: false
      #@schema/nullable
      encrypt: false
      #@schema/nullable
      secure: true
      #@schema/nullable
      #@schema/examples ("Ten megabytes", "10M")
      chunksize: ""
      #@schema/nullable
      rootdirectory: ""

#@schema/desc "The http/https network proxy for core, exporter, jobservice, trivy"
proxy:
  httpProxy:
  httpsProxy:
  noProxy: 127.0.0.1,localhost,.local,.internal

#! The PSP names used by Harbor pods. The names are separated by ','. 'null' means all PSP can be used.
pspNames: null

#! The metrics used by core, registry and exporter
metrics:
  enabled: false
  core:
    path: /metrics
    port: 8001
  registry:
    path: /metrics
    port: 8001
  exporter:
    path: /metrics
    port: 8001
```

### Other Approaches Considered

#### Default non-empty validation for strings

From the beginning of our design of this feature, we expected to provide a default validation for strings:

```yaml
#@data/values-schema
---
foo: ""
```

would be equivalent to:

```yaml
#@data/values-schema
---
#@schema/validation min_len=1
foo: ""
```

However, doing so would result in a breaking change: anyone using a ytt library that adopted Schema would suddenly see an error message that they needed to specify a value for a data value they previously had not.

Example:

```yaml
#@data/values-schema
---
kp_default_repository: ""
kp_default_repository_username: ""
kp_default_repository_password: ""

http_proxy: ""
https_proxy: ""
no_proxy: ""
```
(src: [tomkennedy513/carvel-package-kpack:/config/schema.yaml](https://github.com/tomkennedy513/carvel-package-kpack/blob/2d7ffd7276db244c6a574019ebb80603115d1009/config/schema.yaml))

#### Opt-out of skipping validations when value is `null`

Initially, the design included a keyword argument — `when_null_skip=`. This flag allowed the user to opt-out of skipping validations when the value was `null`.

The rationale for including the keyword is documented in [Automatically including `when_null_skip` for nullable data values](#automatically-including-when_null_skip-for-nullable-data-values).

However, the implementation turned out not to rely on any schema features. Further, after [conducting usability testing](https://github.com/carvel-dev/ytt/issues/707), it became clear that this was an unnecessary feature.

#### Automatically including `when_null_skip` for nullable data values

Had considered automatically short-circuiting validations on a Data Value that was also annotated `@schema/nullable`. Thinking: "when would someone _ever_ want the validations to fire when the value is null?!?!"

Providing the `when_null_skip=` keyword has these advantages:
- makes the behavior explicit; 
- carries the behavior into other contexts (e.g. validation on an output document);
- make schema and validations features as orthogonal as possible.

#### More feature rich Validation Functions

- `validation_func` (`function`) — zero-to-many "validation functions"
    - predicate: `func (value) : bool | (bool, string)`
    - assertion: `func (value) : None` (that `assert.fail()`s when condition is not met)
    - validator: `func () : {"description": string, "type": string}`
        - a "predicate" or "assertion" that when invoked with no arguments returns a specification of the validator.

**Validation Function Specification**

A validation function can improve the consumer's experience by supplying a "validation function specification". This is
a dictionary value returned when the function is invoked with no arguments:
```python
{
    "description": "(a definition of what a valid value is/means.)",
    "type": "int"
}
```

- `description` (`string`) will be used in two cases: a) when generating documentation; b) as a hint when reporting a violation.
- `type` (enum: Starlark type) enables `ytt` to automatically check the type of the annotated node to ensure the validation is appropriate for that node.

#### Programmatically invoking multiple validations

At one point, it seemed tempting to provide a facility by which authors could name a set of validations to run over a tree of nodes.

Here's one "prototype":

```yaml
#@ load("@ytt:assert", "assert")

#! Checks that a Persistent Volume configuration contains valid values.
#@ def validPV(pv):
#@   return assert.validate_all(
#@     ("accessMode", pv.accessMode, ("a PV access mode", validation.one_of["ReadWriteOnce", "ReadWriteOncePod", "ReadWriteMany", "ReadOnlyMany"]))),
#@     ("size", pv.size, ("", validation.format("quantity"))
#@   )
#@ end
```

But this kind of move separates the validation from the node it is targeting, which then requires that the system provide a means for naming nodes (i.e. providing the path to the node).

Instead of creating and solving that problem, if we encourage users to stay _within_ the structure (i.e. attach validations on the node against which violation messages will be reported), none of this work need be done.

For now, we've decided to not pursue this approach until we can get clearer signal that the facilities we _do_ provide are too awkward in a sufficient number of cases as to warrant absorbing that complexity into the tool. In 2022 Q1, this seemed doubtful.

#### @schema/required

In consideration is whether another annotation would be practically useful in schema to indicate that a given data value is required.

https://github.com/carvel-dev/ytt/issues/556

For now, we're deferring this approach until we get a clearer indication of how the "require non-empty" approach is working out (or not).


#### Allow multiple validations using sequence numbers

re: [Merging validations on schema nodes](#consideration-merging-validations-on-schema-nodes)...

Accept a sequence as part of the annotation name:

```yaml
#@assert/validate ...
#@assert/validate1 ...
```

...which merges nicely with...

```yaml
#@assert/validate2
```
## Implementation Considerations

### Consideration: Attaching Validations to Nodes

In a recent refactoring, `yamlmeta.Node` presents programmers with the ability to attach any kind of metadata to a Node.
This proposal presumes that validations are attached to Nodes using this facility (rather than say as a property of a `schema.Type`).

In this way, validation is orthogonal to, but readily composable with Schema functionality.

### Consideration: `@assert/validate` Keyword arguments are syntactic sugar over `@ytt:assert` functions

Consider prior art around how functionality that's exposed through a Starlark built-in is reused in other contexts:

https://github.com/carvel-dev/ytt/blob/c43dcf06798d3ed246e7c458f829a0d63f956e05/pkg/yttlibrary/yaml.go#L31-L69

For example `@ytt:assert.not_null()`'s functionality is likely literally used in implementing `@assert/validate not_null=True`.


### Consideration: Decode yamlfragments to Starlark values in assertion functions



### Consideration: Setting validation defaults for strings in a schema overlay

When exploring how to implement [@schema/validation-defaults-for-strings](#schemavalidation-defaults-for-strings), there are challenges.

Setting up an example:

Two (2) schema files: a base and an overlay.

```yaml
#! base-schema.yml

#@data/values-schema
---
#@schema/validation min_len=5
hostname: ""

proxy: ""
```

```yaml
#! schema-overlay.yml

#@data/values-schema
#@overlay/match-child-defaults missing_ok=True
#@schema/validation-defaults-for-strings min_len=1
---
kp_default_repository: ""
#@schema/validation min_len=0
kp_username: ""
limit: #@ 30
```
_(the `#@ 30` expression is here to remind us that we can't determine the type of the value of a node until it is evaluated — not just parsed.)_

#### Challenge A: No merge semantics for annotations

Currently, `ytt`'s overlaying mechanism specifically preserves all annotations of the "left" side of the overlay operation (i.e. the base). The only way to change the annotations on the "left" is to completely replace that node.

So, merging our example with the current release of `ytt` (v0.38.0) results in:

```yaml
#@data/values-schema
---
#@schema/validation min_len=5
hostname: ""

proxy: ""
kp_default_repository: ""
#@schema/validation min_len=0
kp_username: ""
limit: 30
```
where:
- 👎 the `@schema/validation-defaults-for-strings` annotation is effectively ignored.

#### Solution A1: Implement merge semantics for annotations

... let's stipulate that we _do_ implement merging of annotations (as described in [Defining merge semantics for annotations in an overlay](#consideration-defining-merge-semantics-for-annotations-in-an-overlay), then we hit the next challenge...


#### Challenge B: Unintended scoping of "normalized" annotations

We classify `@schema/validation-defaults-for-strings` as a "normalized annotation" — by that we mean that it represents a factoring out of a set of annotations within a tree of nodes. In our example, it's the "factoring out" of `@schema/validation min_len=1` from `kp_default_repository:`.

The next challenge is that the naive merge causes the normalized annotation to apply to not just the nodes of the overlay, but of the entire overlayed result:

```yaml
#@data/values-schema
#@schema/validation-defaults-for-strings min_len=1
---
#@schema/validation min_len=5
hostname: ""

http_proxy: ""

kp_default_repository: ""
#@schema/validation min_len=0
kp_username: ""
limit: 30
```
where:
- 👎 `http_proxy:` suddenly _also_ had the `min_len=1` default applied to it (surprising)


#### Solution B1: Denormalize annotations before overlaying

One approach is to "distribute" the annotation to all the descendents _before_ the overlay is applied:

```yaml
#! schema-overlay.yml

#@data/values-schema
#@overlay/match-child-defaults missing_ok=True
---
#@schema/validation-defaults-for-strings min_len=1
kp_default_repository: ""
#@schema/validation min_len=0
#@schema/validation-defaults-for-strings min_len=1
kp_username: ""
#@schema/validation-defaults-for-strings min_len=1
limit: 30
```
Note:
- resist the temptation to check the type of the value of each node; instead wait until we have formal schema type information available (after all schema has been merged).
- we take care to retain the "blame"/Position of the original/normalized annotation.

Which results in a net schema:

```yaml
#@data/values-schema
---
#@schema/validation min_len=5
hostname: ""

proxy: ""
#@schema/validation-defaults-for-strings min_len=1
kp_default_repository: ""
#@schema/validation min_len=0
#@schema/validation-defaults-for-strings min_len=1
kp_username: ""
#@schema/validation-defaults-for-strings min_len=1
limit: 30
```

... that can be compiled into a `schema.Type` composite tree.

In type compilation process, the `@schema/validation-defaults-for-strings` is properly combined with the existing annotations (if any):

```yaml
#@data/values-schema
---
#@schema/validation min_len=5
hostname: ""

proxy: ""
#@schema/validation min_len=1
kp_default_repository: ""
#@schema/validation min_len=0
kp_username: ""
limit: 30
```
where:
- `kp_default_repository:` obtains its validation from the defaults.
- `kp_username` — already having a `@schema/validation` present, ignores the defaults.
- `limit` — having a type other than `"string"`, ignores the defaults.


### Consideration: Defining merge semantics for annotations in an overlay

... so that (for example) a consumer can edit `@schema/validation` annotations

For example to:
- be able to remove/disable/edit a validation on a given Data Value (or output field).

#### Replacing an existing annotation

```yaml
#! base-schema.yml

#@data/values-schema
---
#@schema/validation is_even
foo: 42
bar: 13
```

...overlayed with...

```yaml
#! schema-overlay.yml

#@data/values-schema
---
#@schema/validation lambda n: n < 1000
#@overlay/replace-ann
foo: 13
#@schema/validation lambda n: n < 1000
#@overlay/replace-ann
bar: 1001
```
- requiring the consumer to supply the

... yields ...

```yaml
#@data/values-schema
---
#@schema/validation lambda n: n < 1000
foo: 13
#@schema/validation lambda n: n < 1000
bar: 1001
```

#### Merging over an existing annotation

- new arguments are appended,
- new keyword arguments are appended,
- existing keyword arguments are replaced.

```yaml
#! base-schema.yml

#@data/values-schema
---
#@schema/validation is_even, not_null=True
foo: 42
bar: 13
```

...overlayed with...

```yaml
#! schema-overlay.yml

#@data/values-schema
---
#@schema/validation lambda n: n < 1000, min=10, not_null=False
#@overlay/noop
#@overlay/merge-anns
foo: ~
#@schema/validation lambda n: n < 1000
#@overlay/noop
#@overlay/merge-anns
bar: ~
```

... yields ...

```yaml
#@data/values-schema
---
#@schema/validation is_even, lambda n: n < 1000, not_null=False, min=10
foo: 42
#@schema/validation lambda n: n < 1000
bar: 13
```

#### Removing an existing annotation

```yaml
#! base-schema.yml

#@data/values-schema
---
#@schema/validation is_even, not_null=True
foo: 42
#@schema/nullable
#@schema/validation not_null=True
bar: 13
```

...overlayed with...

_(or with an overlay-namespaced annotation)_
```yaml
#! schema-overlay.yml

#@data/values-schema
---
#@overlay/noop
#@overlay/remove-anns "schema/validate"
foo: 13
#@overlay/noop
#@overlay/remove-anns "schema/validate"
#@overlay/validate min=1, max=1000
bar: 0
```
- include a `via=` kwarg takes a predicate, called once for each existing annotation?

... yields ...

```yaml
#@data/values-schema
---
foo: 42
#@overlay/nullable
#@overlay/validate min=1, max=1000
bar: 13
```

### Consideration: Proactively Address Likely-Challenging Topics in Documentation

- The concept of declaring [Required Input](#use-case-required-input) by setting the default value to be invalid is not intuitive for many users. We anticipate this being a heavily-used feature and need to make sure it is grokable.
  - documenting approaches around this idea should particularly _start_ from the user/reader's intention.
  - sometimes acknowledging that a concept is counter-intuitive for some and buttressing the explanation with the explicit benefits for the user can help.
  - is there an analogy that can help bridge the gap?
  - see also: https://github.com/carvel-dev/carvel/pull/331#discussion_r820794818 
- When guiding users through the [Union Structures use case](#use-case-union-structures), be mindful there is a body of existing configuration that uses the discriminator style.
  - It's a breaking change for them to modify their configuration to adopt the union-style we recommend.
  - even as we recommend the union-style over discriminator, given the pervasive existence of the latter, it would ease adoption if there were specific guidance on how to implement/work with the former.
  - see also: https://github.com/carvel-dev/carvel/pull/331#discussion_r820796795
