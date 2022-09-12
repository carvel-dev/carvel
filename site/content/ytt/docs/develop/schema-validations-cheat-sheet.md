

---
title: "Schema Validations Cheat Sheet"
---
{{< table class="cheat-sheet" >}}

(th)**Use Case**(/th)
(th)**Syntax**(/th)
(tr)
(td) Required string(/td)
(td)
```yaml
#@schema/validation min_len=1
username: ""
```
(/td)
(/tr)

(tr)
(td)Required integer(/td)
(td)
```yaml
#@schema/validation min=1
replicas: 0
```
(/td)
(/tr)

(tr)
(td)Required array(/td)
(td)
```yaml
#@schema/validation min_len=1 
responseTypes:
- ""
```
(/td)
(/tr)

(tr)
(td)Required map(/td)
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
(td)Ensure string minimum length(/td)
(td)
```yaml
#@schema/validation min_len=8
password: ""
```
(/td)
(/tr)

(tr)
(td)Ensure a min value(/td)
(td)
```yaml
#@schema/validation min=3
replicas: 5
```
(/td)
(/tr)

(tr)
(td)Ensure a max value(/td)
(td)
```yaml
#@schema/validation max=5
replicas: 3
```
(/td)
(/tr)

(tr)
(td)Ensure a value between min and max(/td)
(td)
```yaml
#@schema/validation min=1, max=65535
port: 1024
```
(/td)
(/tr)

(tr)
(td)Enumeration(/td)
(td)
```yaml
#@schema/validation one_of=["aws", "azure", "vsphere"]
provider: ""
```
(/td)
(/tr)

(tr)
(td)Exactly one is specified\
(mutually exclusive config)
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
(td)Conditionally run validations (/td)
(td)
```yaml
#@ load("@ytt:assert", "assert")

#@ isLoadBalancer = lambda v: v["type"] == "LoadBalancer"
#@ assertNameGiven = ("be given", lambda v: assert.min_len(1).check(v["name"]))

#@data/values-schema
---
#@schema/validation assertNameGiven, when=isLoadBalancer
service:
  type: LoadBalancer
  name: ""
```
(/td)
(/tr)


(tr)
(td)Custom description of valid value (/td)
(td)
```yaml
#@ load("@ytt:assert", "assert")

#@schema/validation ("a non-blank name", assert.min_len(1))
username: ""
```
(/td)
(/tr)

(tr)
(td)Disable validations flag(/td)
(td)
```yaml
$ ytt ... --dangerous-data-values-disable-validation
```
(/td)
(/tr)

{{< /table >}}
