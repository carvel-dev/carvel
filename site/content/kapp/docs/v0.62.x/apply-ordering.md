---
aliases: [/kapp/docs/latest/apply-ordering]
title: Apply Ordering
---

## Overview

kapp includes builtin rules to make sure certain changes are applied in particular order:

- Creates/updates
  - CRDs are created/updated before custom resources
  - Namespaces are created/updated before namespaced resources
  - Pod related resources (ServiceAccount, ConfigMap, Secret, etc.) are created/updated before other resources (v0.25.0+)
  - RBAC related resources (Role, RoleBinding, etc.) are created/updated before other resources (v0.25.0+)
- Deletions (below is order as of v0.29.0+)
  - Custom resources are deleted first
  - CRDs are deleted next
  - Rest of resoures are deleted

As of v0.25.0+, builtin rules are specified via [changeGroupBindings and changeRuleBindings](config.md#changegroupbindings) configurations. Custom rules can be added via same mechanism.

Additionally kapp allows to customize order of changes via following resource annotations:

- `kapp.k14s.io/change-group` annotation to group one or more resource changes into arbitrarily named group. Example: `apps.big.co/db-migrations`. You can specify multiple change groups by suffixing each annotation with a `.x` where `x` is unique identifier (e.g. `kapp.k14s.io/change-group.istio-sidecar-order`).
- `kapp.k14s.io/change-rule` annotation to control when resource change should be applied (created, updated, or deleted) relative to other changes. You can specify multiple change rules by suffixing each annotation with a `.x` where `x` is unique identifier (e.g. `kapp.k14s.io/change-rule.istio-sidecar-order`).

`kapp.k14s.io/change-rule` annotation value format is as follows: `(upsert|delete) (after|before) (upserting|deleting) <name>`. For example:

- `kapp.k14s.io/change-rule: "upsert after upserting apps.big.co/db-migrations"`
- `kapp.k14s.io/change-rule: "delete before upserting apps.big.co/service"`

As of v0.41.0+, kapp provides change group placeholders, which can be used in change-group and change-rule annotation values and are later replaced by values from the resource manifest of the resource they are associated with. For example:

- `kapp.k14s.io/change-group: apps.co/db-migrations-{name}` - Here `{name}` would later be replaced by the name of the resource.
- `kapp.k14s.io/change-rule: upsert after upserting apps.co/namespaces-{namespace}` - Here `{namespace}` would later be replaced by the namespace of the resource.

kapp provides the following placeholders:

- `{api-group}` - apiGroup
- `{kind}` - kind
- `{name}` - name
- `{namespace}` - namespace
- `{crd-kind}` - spec.names.kind (available for CRDs only)
- `{crd-group}` - spec.group (available for CRDs only)

These placeholders can also be used in changeGroupBindings and changeRuleBindings. By default, they are used for CRDs, CRs, namespaces and namespaced resources. Due to this, CRs now wait for their respective CRDs only and namespaced resources now wait for their respective namespaces only.

## Example

Following example shows how to run `job/migrations`, start and wait for `deployment/app`, and finally `job/app-health-check`.

```yaml
kind: ConfigMap
metadata:
  name: app-config
  annotations: {}
#...
---
kind: Job
metadata:
  name: migrations
  annotations:
    kapp.k14s.io/change-group: "apps.big.co/db-migrations"
#...
---
kind: Service
metadata:
  name: app
  annotations:
    kapp.k14s.io/change-group: "apps.big.co/deployment"
#...
---
kind: Ingress
metadata:
  name: app
  annotations:
    kapp.k14s.io/change-group: "apps.big.co/deployment"
#...
---
kind: Deployment
metadata:
  name: app
  annotations:
    kapp.k14s.io/change-group: "apps.big.co/deployment"
    kapp.k14s.io/change-rule: "upsert after upserting apps.big.co/db-migrations"
#...
---
kind: Job
metadata:
  name: app-health-check
  annotations:
    kapp.k14s.io/change-rule: "upsert after upserting apps.big.co/deployment"
#...
```
