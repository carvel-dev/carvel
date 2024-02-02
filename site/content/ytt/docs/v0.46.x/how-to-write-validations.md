---

title: Writing Schema Validations
---

## Overview

_(Looking for a quick start? see the [Validations Cheat Sheet](schema-validations-cheat-sheet.md))_

A Configuration Author can constraint their users' Data Value inputs via `ytt` Validations.

One might do this for a number of reasons:
- **catch configuration errors early** — help the user of the `ytt` library from wasting time _discovering_ errors in their configuration when they use it... by catching and _reporting_ those errors right away
  - e.g. in Kubernetes, instead of sifting through statuses and logs troubleshooting a failed deploy, present the user with an error message at configuration time — _before_ the deployment begins.
- **avoid impractical configuration** — guide them away from setting values that won't work in practice (e.g. too many `replicas:` of a Kubernetes Deployment, when the system won't actually scale that large);
- **make a Data Values "required"** — force the user to supply values for Data Values that you — as the author — can't possibly know (e.g. credentials, connection info to services, etc.).

This guide explains how to do all that with Validations.

## What Validations Look Like

A validation is an annotation on a Data Value in a schema file:

```yaml
#@data/values-schema
---
dex:
  #@schema/validation min_len=1
  namespace: ""
```

Here:
- the Data Value `dex.namespace` is a string
- to be valid, that string must be set to a value at least one character long.

One can specify multiple "rules":

```yaml
#@data/values-schema
---
dex:
  #@schema/validation min_len=1, max_len=63
  namespace: ""
```

Here, `dex.namespace` must ultimately be:
- at least 1 character, _and_ 
- no more than 63 characters in length.

And one can declare validations for _each_ Data Value; `ytt` will validate _all_ Data Values, together.

```yaml
#@data/values-schema
---
dex:
  #@schema/validation min_len=1, max_len=63
  namespace: ""
  #@schema/validation min_len=1
  username: ""
```

Here:
- additionally, `dex.username` is also a string; and to be valid must be at least one character in length.

> _There can only be one `@schema/validation` annotation on a Data Value: all rules required to define validity must be combined into that one annotation._

Finally, one can write their own custom rules, as well:

```yaml
#@data/values-schema
---
dex:
  #@schema/validation ("not 'default'", lambda v: v != "default"), min_len=1, max_len=63
  namespace: ""
```

Here:
- For `dex.namespace` to be valid it must:
  - _not_ be the string "default", _and_
  - be at least one character long, _and_
  - be no more than 63 characters in length.

_(For a list of the most common rules, see [Validations Cheat Sheet](schema-validations-cheat-sheet.md))_

_(For details on the use and shape of individual rules, see [About Rules](#about-rules), below)_

## How Validations Work

At a high level, validations fit into the flow like so:

1. In schema, the Author declares validations on Data Values (described [above](#what-a-validations-look-like))
2. The Consumer configures data values (described in [How To Use Data Values](how-to-use-data-values.md#configuring-data-values))
3. All of those values are merged into a single set (the first step of the [ytt Pipeline](how-it-works.md#step-1-calculate-data-values))
4. All validations are run on that final Data Values; if any fail, those are collected as "violations"
5. If there were violations, processing stops and those are reported; \
   ... otherwise, processing continues normally.

For example, given this schema:

```yaml
#@data/values-schema
---
dex:
  #@schema/validation min_len=1, max_len=63
  namespace: ""
  #@schema/validation min_len=1
  username: ""
```

If the Consumer supplies no data values, then the final Data Values are the defaults from the schema.
When the validations are run, instead of rendering templates, `ytt` reports the violations:

```console
$ ytt -f schema.yaml
ytt: Error: Validating final data values:
  dex.namespace
    from: schema.yaml:5
    - must be: length >= 1 (by: schema.yaml:4)
      found: length = 0

  dex.username
    from: schema.yaml:7
    - must be: length >= 1 (by: schema.yaml:6)
      found: length = 0
```

And if the Consumer supplies data values:

```yaml
dex:
  namespace: the-longest-namespace-you-ever-did-see-in-fact-probably-too-long
  username: alice
```

Only _after_ those are merged with the default values are validations run:

```console
$ ytt -f schema.yaml --data-values-file values.yaml
ytt: Error: Validating final data values:
  dex.namespace
    from: alues.yaml:2
    - must be: length <= 63 (by: schema.yaml:4)
      found: length = 64
```

Until, finally, all Data Values have valid values:

```console
$ ytt -f schema.yaml --data-values-file values.yaml --data-value dex.namespace=ident-system --data-values-inspect
dex:
  namespace: ident-system
  username: alice
```

Next, we cover typical situations where validations are useful...

## Common Use Cases

There are a variety of ways you can put validations to use:

- ["Required" Data Values](#required-data-values) — ensure the user supplies their own value
- [Enumerations](#enumerations) — limit the value to a finite, specific set.
- [Mutually Exclusive Sections](#mutually-exclusive-sections) — when there are multiple way to configure a feature, but the Consumer should only choose one.
- [Conditional Validations](#conditional-validations) — trigger validations only in certain situations.

### "Required" Data Values

Sometimes, there are configuration values that you — as the Author — either can't possibly know (e.g. IP addresses, domain names) or do not want to default (e.g. passwords, tokens, certificates, other credentials). Instead, you want to force the Consumer to supply these values.

> ℹ️ _The way to mark a Data Value as "required" is by declaring a validation rule that is not satisfied by that Data Value's default._

There are three general tactics:

- ideally, [using natural constraints](#using-natural-constraints)
- otherwise, [using the empty/zero value](#using-the-emptyzero-value)
- if all else fails, [mark as 'nullable' _and_ 'not_null'](#mark-as-nullable-and-not_null)

#### Using Natural Constraints

The most concise (and maintainable) way to make a data value "required" is to set a default outside of its natural constraints.

For example, if `port:`, means any "registered" (ports 1024 - 49151) or "dynamic" (49152 - 65535) port, then

```yaml
#@data/values-schema
---
#@schema/validation min=1024
port: 0
```

out of the box, the Consumer receives this message:

```console
$ ytt -f schema.yaml
  port
    from: schema.yaml:4
    - must be: a value >= 1024 (by: schema.yaml:3)
      found: value < 1024
```

Where there are not "natural" limits, one might be able to use the zero or empty value...

#### Using the empty/zero value

For strings, an empty value is often not valid. One can specifically require a non-zero length:

```yaml
#@schema/validation min_len=1
username: ""
```

For integers and floating-point values, non-positive numbers are often not valid. One can require a non-negative number

```yaml
#@schema/validation min=1
replicas: 0
```

For array values, note that [the default value is always an empty list](how-to-write-schema.md#setting-a-default-value-for-an-array). One can require that the array not be empty:

```yaml
#@data/values-schema
---
dex:
  oauth2:
    #@schema/validation min_len=1
    responseTypes:
    - ""
```
Here, 
- `dex.oauth2.responseTypes` is an array of strings. 
- by default no response types are configured.
- however, the rule requires that _at least one_ be specified.

#### Mark as 'nullable' and 'not_null'

In some cases, there simply is no invalid value and/or there is no zero value (e.g. maps).

What's left is to specify no value at all (i.e. `null`) and then require a non-null value.

```yaml
#@data/values-schema
---
#@schema/nullable
#@schema/validation not_null=True
tlsCertificate:
  tls.crt: ""
  tls.key: ""
  ca.crt: ""
```
Here:
- `tlsCertificate:` is a map, containing three items.
- `@schema/nullable` changes `tlsCertificate:` in two ways (details at [`@schema/nullable`](lang-ref-ytt-schema.md#schemanullable))
  - now, `tlsCertificate` can be set to `null`
  - and, `tlsCertificate` is `null` by default.
- the `not_null=` rule requires that `tlsCertificate:` _not_ be `null`

out of the box, the Consumer receives this message:

```console
$ ytt -f schema.yaml
ytt: Error: Validating final data values:
  tlsCertificate
    from: schema.yaml:5
    - must be: not null (by: schema.yaml:4)
      found: value is null
```

### Enumerations

Some values must be from a discrete and specific set.

```yaml
#@data/values-schema
---
#@schema/validation one_of=["aws", "azure", "vsphere"]
provider: vsphere
```

### Conditional Validations

Sometimes, a Data Value should be validated only when some _other_ configuration has been set.

In `ytt` Validations, this is achieved through the `when=` keyword.

For example:

```yaml
#@data/values-schema
---
#@schema/validation ("at least 1 instance", lambda v: v["instances"] >= 1), when=lambda v: v["enabled"]
service:
  enabled: true
  instances: 1
```
Here:
- if `service.enabled` is false, the validation is _not_ run;
- when `service.enabled` is true, `service.instances` is required to be non-negative.

_(For more details, see [Reference for `@schema/validation`](lang-ref-ytt-schema.md#schemavalidation).)_

#### Making Validations Dependent on Other Data Values

In some situations, a Data Values's final value is only relevant (i.e. worth validating) if some _other_ data value has a specific setting.
For these situations, the `@schema/validation ... when=` can accept an optional second parameter.

For example, the previous example could be rewritten as:

```yaml
#@data/values-schema
---
service:
  enabled: true
  #@schema/validation min=1, when=lambda _, ctx: ctx.parent["enabled"]
  instances: 6
```
where:
- the `when=` now has a function value that accepts two (2) arguments; the second of which is named `ctx`.
  - see [Reference for `@schema/validation`](lang-ref-ytt-schema.md#schemavalidation) for details of the value assigned to `ctx`.
- `instances` will only be validated if `enabled` is `true`

### Mutually Exclusive Sections 

One pattern found in configuration files is the "mutually exclusive" structure.

This is typically done with a discriminator field:

```yaml
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
Here:
- there are two kinds of identity systems one could configure: OIDC _or_ LDAP.
- which one being used is named in `dex.config.type`; in this case, OIDC.
- both structures are present and `null` values are used.

Essential is that the Consumer can configure _either_ OIDC _or_ LDAP _but not both._

There are at least a couple of approaches possible:
- [Using `one_not_null=`](#using-one_not_null) to enforce that only one section can be populated.
- [Using a Discriminator as the Condition](#using-a-discriminator-as-the-condition) to trigger validations only on the currently selected section.

#### Using `one_not_null=`

With `ytt` the Author can more clearly enforce this structure and validate only the active configuration:

```yaml
#@data/values-schema
---
dex:
  #@schema/validation one_not_null=["oidc", "ldap"]
  config:
    #@schema/nullable
    oidc:
      CLIENT_ID: ""
      CLIENT_SECRET: ""
      issuer: ""
    #@schema/nullable
    ldap:
      host: ""
      bindDN: ""
      bindPW: ""
```
Here:
- each option (i.e. `oidc:` and `ldap:`) are made "optional" by marking them as `@schema/nullable`
  - `@schema/nullable` makes a Data Value _able_ to be `null` _and_ sets it to `null`, by default. (for details [`@schema/nullable`](lang-ref-ytt-schema.md#schemanullable))
- however, `config:` requires that _exactly one (1)_ of the listed keys contain a **not-null** value.

By default, then, neither `oidc:` nor `ldap:` are configured:

```console
$ ytt -f schema.yaml --inspect-data-values --dangerous-data-values-disable-validation
dex:
  config:
    oidc: null
    ldap: null
```

When validations run, the Consumer is prompted to configure one:

```console
$ ytt -f schema.yaml --data-values-inspect
ytt: Error: Validating final data values:
  dex.config
    from: schema.yaml:5
    - must be: exactly one of ["oidc", "ldap"] to be not null (by: schema.yaml:4)
      found: all values are null
```

Once a value _is_ provided for one or the other, the configuration becomes valid:

```console
$ ytt -f schema.yaml --data-values-inspect --data-value dex.config.oidc.CLIENT_ID=admin
dex:
  config:
    oidc:
      CLIENT_ID: admin
      CLIENT_SECRET: ""
      issuer: ""
    ldap: null
```

#### Using a Discriminator as the Condition

In some cases, it may be desirable to keep the discriminator.

Reworking the example from above...

```yaml
#@data/values-schema
---
dex:
  config:
    #@schema/validation one_of=["oidc", "ldap"]
    type: "oidc"
    oidc:
      #@schema/validation min_len=1, when=lambda _, ctx: ctx.root["dex"]["config"]["type"] == "oidc"
      CLIENT_ID: ""
      #@schema/validation min_len=1, when=lambda _, ctx: ctx.root["dex"]["config"]["type"] == "oidc"
      CLIENT_SECRET: ""
      #@schema/validation min_len=1, when=lambda _, ctx: ctx.root["dex"]["config"]["type"] == "oidc"
      issuer: ""
    ldap:
      #@schema/validation min_len=1, when=lambda _, ctx: ctx.root["dex"]["config"]["type"] == "ldap"
      host: ""
      #@schema/validation min_len=1, when=lambda _, ctx: ctx.root["dex"]["config"]["type"] == "ldap"
      bindDN: ""
      #@schema/validation min_len=1, when=lambda _, ctx: ctx.root["dex"]["config"]["type"] == "ldap"
      bindPW: ""
```
where:
- `dex.config.type` can only be _either_ "oidc" or "ldap"
- `dex.config.oidc` values will only be validated if `type` is "oidc"
- `dex.config.ldap` values, likewise, will only be validated if `type` is "ldap"

_(See also [Making Validations Dependent on Other Data Values](#making-validations-dependent-on-other-data-values).)_

## About Rules

A validation is made up of one or more rules.

A rule comes in one of two forms:
- a [named rule](#using-named-rules) — a set of pre-built commonly used rules
- a [custom rule](#writing-your-own-custom-rules) — a rule an Author writes for a specific purpose

### Using "Named" Rules

`ytt` comes with a library of built-in rules known as "named" rules.

These rules are primarily used as a keyword on the `@schema/validation` annotation; refer to the [Data Values Schema Reference](lang-ref-ytt-schema.md#schemavalidation) for the current complete list. Most of the examples we see use named rules.

For example:
```yaml
#@data/values-schema
---
#@schema/validation one_of=["INFO", "WARN", "ERROR", "FATAL"]
logLevel: INFO
```
Here:
- `logLevel` is a string, defaulting to "INFO"
- a valid `logLevel` must be one of the four values given.

Authors are encouraged to use named rules whenever possible:
- there's no code to maintain: these rules are [unit-tested](https://github.com/carvel-dev/ytt/tree/develop/pkg/validations/filetests)
- they more succinctly document the constraints, making the schema easier to read/maintain
- when rules are included in [OpenAPI v3 schema exports](how-to-export-schema.md), these are the first batch of such rules likely to be included.


### Writing Custom Rules

The ["Named" rules](#using-named-rules) will not cover _all_ possible validation cases. One might opt to write a custom rule for a number of reasons:
- the desired constraint can't be expressed through a named rule
- the description supplied by a named rule is inadequate


- [Complex Custom Rules](#complex-custom-rules)
- [About `null` values](#about-null-values)

A validation rule has two parts:
- a description of a valid value;
- a function that implements that definition in Starlark code.

For example:
```yaml
#@data/values-schema
---
#@schema/validation ("a multiple of 1024", lambda v: v % 1024 == 0)
quota: 1023
```
Here:
- the rule is a two-value "[tuple](https://github.com/google/starlark-go/blob/master/doc/spec.md#tuples)"
- the first value is a string; 
  - it describes what a valid value looks like;
  - this string is used in violation messages (see below) to help the user provide a valid input.
- the second value is a function (here's a [lambda](https://github.com/google/starlark-go/blob/master/doc/spec.md#lambda-expressions) expression);
  - the function will be passed one (1) argument: the value being validated.
  - the function must return a boolean value (either `True` or `False`) _or_ `fail()` with a message describing the failure.

Has the initial result:

```console
$ ytt -f schema.yaml
ytt: Error: Validating final data values:
  quota
    from: schema.yaml:4
    - must be: a multiple of 1024 (by: schema.yaml:3)
```

And quietly reports nothing when the value _is_ valid.

#### Complex Custom Rules

Occasionally, a validation rule requires pre-processing of a value or requires multiple checks. In these cases, a lambda expression is often not enough: a function needs to be written.

To keep the schema itself readable/maintainable, Authors will typically extract these functions to a separate file:

`rules.star`
```python
def one_registry_if_pvc_is_filesystem(val):
   if val["persistence"]["imageChartStorage"]["type"] == "filesystem" and \
     val["persistence"]["persistentVolumeClaim"]["registry"]["accessMode"] == "ReadWriteOnce":
     return val["registry"]["replicas"] == 1 \
         or fail("{} replicas are configured".format(val["registry"]["replicas"]))
  end
end
```

`schema.yaml`
```yaml
#@ load("rules.star", "one_registry_if_pvc_is_filesystem")

#@data/values-schema
#@schema/validation ("exactly one (1) registry replica if Helm Charts are stored on the filesystem.", one_registry_if_pvc_is_filesystem)
---
registry:
  replicas: 2
persistence:
  imageChartStorage:
    type: "filesystem"
  persistentVolumeClaim:
    registry:
      accessMode: "ReadWriteOnce"
```

Here:
- the `@schema/validation` annotates the _document_ because the validation applies across two top-level keys (`registry` and `persistence`);
- the assertion itself is defined in `rules.star`, so as to not clutter the schema; it is _loaded_ into `schema.yaml`
- in `rules.star`, the parameter `val` is expected to receive the value of the document:
  - that value is a [YAML Fragment](lang-ref-yaml-fragment.md) containing a map with those two top-level keys (and their contents, recursively)
  - and so, contained items are accessed through bracket notation.

_(See also using a `struct` to export multiple functions through a single `load()` in [Load Statements > Usage](lang-ref-load.md#usage))_

#### About `null` values

`ytt` attempts to gracefully handle `null` values in validations:
- when a Data Value is marked `@schema/nullable`, and the value remains `null`, validations are skipped automatically.
- if the same Data Value has the `not_null=True` rule, _that_ rule is run.
- the `not_null=` rule, if present, is checked _first_.

The upshot of these policies are:
- no other rules need handling the `null` value.

