---
aliases: [/ytt/docs/latest/schema-validations-cheat-sheet]
title: "Schema Validations Cheat Sheet"
---

_(For a more detailed guide, see [Writing Schema Validations](how-to-write-validations.md).)_

{{< table class="cheat-sheet" >}}

(th)**Use Case**(/th)
(th)**Syntax**(/th)
(tr)
(td)
##### Required string
_usage: [Using the empty/zero value](../how-to-write-validations#using-the-emptyzero-value)_\
_reference: [`min_len=`](../lang-ref-ytt-schema#min_len)_
(/td)
(td)
```yaml
#@schema/validation min_len=1
username: ""
```
(/td)
(/tr)

(tr)
(td)
##### Required integer
_usage: [Using the empty/zero value](../how-to-write-validations#using-the-emptyzero-value)_\
_reference: [`min=`](../lang-ref-ytt-schema#min)_
(/td)
(td)
```yaml
#@schema/validation min=1
replicas: 0
```
(/td)
(/tr)

(tr)
(td)
##### Required array
_usage: [Using the empty/zero value](../how-to-write-validations#using-the-emptyzero-value)_\
_reference: [`min_len=`](../lang-ref-ytt-schema#min_len)_
(/td)
(td)
```yaml
#@schema/validation min_len=1 
responseTypes:
- ""
```
(/td)
(/tr)

(tr)
(td)
##### Required map
_usage: [mark as "nullable" and "not_null"](../how-to-write-validations#mark-as-nullable-and-not_null)_ \
_reference: [`@schema/nullable`](../lang-ref-ytt-schema#schemanullable) and [`not_null=`](../lang-ref-ytt-schema#not_null)_

(/td)
(td)
```yaml
#@schema/nullable
#@schema/validation not_null=True
credential:
  name: ""
  cloud: ""
```
(/td)
(/tr)

(tr)
(td)
##### Ensure string minimum length
_reference: [`min_len=`](../lang-ref-ytt-schema#min_len)_
(/td)
(td)
```yaml
#@schema/validation min_len=8
password: ""
```
(/td)
(/tr)

(tr)
(td)
##### Ensure string exact length
(/td)
(td)
```yaml
#@schema/validation min_len=8, max_len=8
password: ""
```
(/td)
(/tr)

(tr)
(td)
##### Ensure a min value
(/td)
(td)
```yaml
#@schema/validation min=3
replicas: 5
```
(/td)
(/tr)

(tr)
(td)
##### Ensure a max value
(/td)
(td)
```yaml
#@schema/validation max=5
replicas: 3
```
(/td)
(/tr)

(tr)
(td)
##### Ensure a value between min and max
(/td)
(td)
```yaml
#@schema/validation min=1, max=65535
port: 1024
```
(/td)
(/tr)

(tr)
(td)
##### Enumeration
_usage: [enumerations](../how-to-write-validations#enumerations)_\
_reference: [`one_of=`](../lang-ref-ytt-schema#one_of)_
(/td)
(td)
```yaml
#@schema/validation one_of=["aws", "azure", "vsphere"]
provider: ""
```
(/td)
(/tr)

(tr)
(td)
##### Exactly one is specified
_usage: [mutually exclusive config](../how-to-write-validations#mutually-exclusive-sections)_\
_reference: [`one_not_null=`](../lang-ref-ytt-schema#one_not_null)_
(/td)
(td)
```yaml
#@schema/validation one_not_null=["oidc", "ldap"]
config:
  #@schema/nullable
  oidc:
    client_id: “”
  #@schema/nullable
  ldap:
    host: “”
```
(/td)
(/tr)

(tr)
(td)
##### Conditionally run validations
_usage: [conditional validations](../how-to-write-validations#conditional-validations)_\
_reference: [`@schema/validation ... when=`](../lang-ref-ytt-schema#schemavalidation)_
(/td)
(td)
```yaml
#@data/values-schema
---
service:
  type: LoadBalancer
  #@schema/validation min_len=1, when=lambda _, ctx: ctx.parent["type"] == "LoadBalancer"
  name: ""
```
(/td)
(/tr)


(tr)
(td)
##### Custom description of valid value
_usage: [writing custom rules](../how-to-write-validations#writing-custom-rules)_\
_reference: [@ytt:assert](../lang-ref-ytt-assert)_
(/td)
(td)
```yaml
#@ load("@ytt:assert", "assert")

#@schema/validation ("a non-blank name", assert.min_len(1))
username: ""
```
(/td)
(/tr)

(tr)
(td)
##### Disable validations flag
(/td)
(td)
```yaml
$ ytt ... --dangerous-data-values-disable-validation
```
(/td)
(/tr)

{{< /table >}}
