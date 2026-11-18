---
title: Configuration
---

## Overview

kapp supports custom `Config` resource to specify its own configuration. It's expected to be included with your other Kubernetes configuration. Config resource is never applied to the cluster, though it follows general Kubernetes resource format. Multiple config resources are allowed.

kapp comes with __built-in configuration__ (see it via `kapp deploy-config`) that includes rules for common resources.

## Format

```yaml
apiVersion: kapp.k14s.io/v1alpha1
kind: Config

minimumRequiredVersion: 0.23.0

rebaseRules:
- path: [spec, clusterIP]
  type: copy
  sources: [new, existing]
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: v1, kind: Service}

ownershipLabelRules:
- path: [metadata, labels]
  resourceMatchers:
  - allMatcher: {}

labelScopingRules:
- path: [spec, selector]
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: v1, kind: Service}

templateRules:
- resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: v1, kind: ConfigMap}
  affectedResources:
    objectReferences:
    - path: [spec, template, spec, containers, {allIndexes: true}, env, {allIndexes: true}, valueFrom, configMapKeyRef]
      resourceMatchers:
      - apiVersionKindMatcher: {apiVersion: apps/v1, kind: Deployment}
    - path: [spec, template, spec, containers, {allIndexes: true}, envFrom, {allIndexes: true}, configMapRef]
      resourceMatchers:
      - apiVersionKindMatcher: {apiVersion: apps/v1, kind: Deployment}

additionalLabels:
  department: marketing
  cost-center: mar201

diffAgainstLastAppliedFieldExclusionRules:
- path: [metadata, annotations, "deployment.kubernetes.io/revision"]
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: apps/v1, kind: Deployment}

diffAgainstExistingFieldExclusionRules:
  - path: [status]
    resourceMatchers:
      - allMatcher: {}

diffMaskRules:
- path: [data]
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: v1, kind: Secret}

preflightRules:
- name: [preflight]
  config:
    [preflightSpecific]: [data]
```

### minimumRequiredVersion

`minimumRequiredVersion` forces kapp to exit with a validation error if kapp's version is below minimum required version. Available in v0.23.0+.

### rebaseRules

`rebaseRules` specify origin of field values. 

kapp rebase rules explicitly define how to merge resources during an update. To read more about why rebase rules are necessary, see [Resource Merge Method](merge-method.md).
For examples of rebase rules in use, see [HPA and Deployment rebase](hpa-deployment-rebase.md) or [PersistentVolumeClaim rebase](rebase-pvc.md).

- `rebaseRules` (array) list of rebase rules
  - `path` (array of strings) specifies location within a resource to rebase. Mutually exclusive with `paths`. Example: `[spec, clusterIP]`
  - `paths` (array of `path`) specifies multiple locations within a resource to rebase. This is a convenience for specifying multiple rebase rules with only different paths. Mutually exclusive with `path`. Available in v0.27.0+.
  - `type` (string) specifies strategy to modify field values. Allowed values: `copy` or `remove`. `copy` will update the field value; `remove` will delete the field.
  - `sources` (array of `new` or `existing`) specifies a preference order for the source of the referenced field value being rebased. `new` refers to an updated resource from user input, where `existing` refers to a resource already in the cluster. If the field value being rebased is not found in any of the sources provided, kapp will error. Only used with `type: copy`. \
    Examples:
     - `[existing, new]` – If field value is present in the `existing` resource on cluster, use that value, otherwise use the value in the `new` user input.
     - `[existing]` – Only look for field values in resources already on cluster, corresponding value you provide in new resource will be overwritten.
  - `resourceMatchers` (array) specifies rules to find matching resources. See various resource matchers below.
  - `ytt` specifies choice as [ytt](https://carvel.dev/ytt/) for rebase rule. Available in v0.38.0+.
    - `overlayContractV1` allows to use ytt overlay to modify provided resource based on existing resource. 
      - `overlay.yml` overlay YAML file. 
    - Following fields are accessible via `data.values` inside ytt:
      - `data.values.existing` resource from live cluster
      - `data.values.new` resource from config (post-prep)
      - `data.values._current` resource after previous rebase rules already applied
  
Rebase rule to `copy` the `clusterIP` field value to `Service`/`v1` resources; if `clusterIp` is present in the `new` user input, use that value, otherwise use the value in `existing` resource on cluster:
```yaml
rebaseRules:
- path: [spec, clusterIP]
  type: copy
  sources: [new, existing]
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: v1, kind: Service}
```

Rebase rule to `copy` the `clusterIP` and `healthCheckNodePort` field values from the `existing` resource on cluster, to `Service`/`v1` resources:
```yaml
rebaseRules:
- paths:
  - [spec, clusterIP]
  - [spec, healthCheckNodePort]
  type: copy
  sources: [existing]
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: v1, kind: Service}
```

See [ytt rebase rule](https://github.com/carvel-dev/kapp/blob/d3ee9a01b5f0d7d5632b6a157ea7d0338730d497/pkg/kapp/config/default.go#L123-L154) (included in default configuration) for retaining cluster added token secret in ServiceAccount's secrets array.

### ownershipLabelRules

`ownershipLabelRules` specify locations for inserting kapp generated labels. These labels allow kapp to track which resources belong to which application. For resources that describe creation of other resources (e.g. `Deployment` or `StatefulSet`), configuration may need to specify where to insert labels for child resources that will be created. `kapp.k14s.io/disable-default-ownership-label-rules: ""` (value must be empty) annotation can be be used to exclude an individual resource from default onwership label rules.

### labelScopingRules

`labelScopingRules` specify locations for inserting [kapp generated labels](apply.md#resource-labels) that scope resources to resources within current application.

The annotations `kapp.k14s.io/disable-default-label-scoping-rules: ""` (as of v0.33.0+, or use `kapp.k14s.io/disable-label-scoping: ""` in earlier versions) can be used to exclude an individual resource from label scoping.

The global CLI option `--default-label-scoping-rules=false` can be used to disable addition of ownership labels
entirely, but it's recommended to limit the scope of this option to specific use cases so kapp can do a better job of tracking the application's resources.

### waitRules

Available in v0.29.0+.

`waitRules` specify how to wait for resources that kapp does not wait for by default. Each rule provides a way to specify which `status.conditions` indicate success or failure. Once any of the condition matchers successfully match against one of the resource's conditions, kapp will stop waiting for the matched resource and report any failures. (If this functionality is not enough to wait for resources in your use case, please reach out on Slack to discuss further.)

```yaml
waitRules:
- supportsObservedGeneration: true
  conditionMatchers:
  - type: Failed
    status: "True"
    failure: true
  - type: Deployed
    status: "True"
    success: true
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: corp.com/v1, kind: DatabaseInstance}
```

```yaml
waitRules:
- supportsObservedGeneration: true
  conditionMatchers:
  - type: Ready
    status: "False"
    failure: true
  - type: Ready
    status: "True"
    success: true
    supportsObservedGeneration: true    # available at condition level from v0.47.0+
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: corp.com/v1, kind: Application}
```

Available in v0.48.0+.

ytt `waitRules` can be for Custom Resources that don't have `conditions` field in their `status`. This allows users to configure arbitrary rules. `is_done(resource)` method can be defined as part of a ytt waitRule to return the done state based on resource fields.

```yaml
waitRules:
  - ytt:
      funcContractV1:
        resource.star: |
          def is_done(resource):
              state = resource.status.currentState
              if state == "Failed":
                return {"done": True, "successful": False, "message": "Current state as Failed"}
              elif state == "Running":
                return {"done": True, "successful": True, "message": "Current state as Running"}
              else:
                return {"done": False, "successful": False, "message": "Not in Failed or Running state"}
              end
          end
  resourceMatchers:
    - apiVersionKindMatcher: {apiVersion: <resource-api-version>, kind: <resource-kind>}
``` 

Available in v0.50.0+

`unblockChanges` can be used for conditions to unblock any dependent resources. These conditions are treated as non success/failure conditions. It can also be used along with ytt waitRules.

```yaml
waitRules:
- conditionMatchers:
  - type: Progressing
    status: "True"
    unblockChanges: true
  resourceMatchers:
  - apiVersionKindMatcher: {apiVersion: corp.com/v1, kind: Application}
```
 
### templateRules

`templateRules` specify how versioned resources affect other resources. In above example, versioned config maps are said to affect deployments. [Read more about versioned resources](diff.md#versioned-resources).

### additionalLabels

`additionalLabels` specify additional labels to apply to all resources for custom uses by the user (added based on `ownershipLabelRules`).

### diffAgainstLastAppliedFieldExclusionRules

`diffAgainstLastAppliedFieldExclusionRules` specify which fields should be removed before diff-ing against last applied resource. These rules are useful for fields are "owned" by the cluster/controllers, and are only later updated. For example `Deployment` resource has an annotation that gets set after a little bit of time after resource is created/updated (not during resource admission). It's typically not necessary to use this configuration.

### diffAgainstExistingFieldExclusionRules

`diffAgainstExistingFieldExclusionRules` specify which fields should be removed before diff-ing against a resource. These rules are useful for fields that are "owned" by the cluster/controllers, and are only updated later. For example a `Custom Resource Definition` resource has a `status` field that gets altered now and then, especially between a diff and the actual apply step. It's typically not necessary to use this configuration.

### diffMaskRules

`diffMaskRules` specify which field values should be masked in diff. By default `v1/Secret`'s `data` fields are masked. Currently only applied to `deploy` command.

### preflightRules

Available in v0.61.0+.

`preflightRules` specify configuration for [preflight checks](preflight.md). Specifying the `name` of a preflight check enables it; additional configuration via the `config` field may be optionally provided. The contents of the `config` field are specific to each preflight check.

The `--preflight` flag overrides the enabled setting in the configuration:
* If a preflight check is omitted from the `--preflight` flag, it is disabled regardless of its presence in the configuration file.
* If a preflight check is specified in the `--preflight` flag, it is enabled regardless of its absence in the configuration file.

### changeGroupBindings

Available in v0.25.0+.

`changeGroupBindings` bind specified change group to resources matched by resource matchers. This is an alternative to using `kapp.k14s.io/change-group` annotation to add change group to resources. See `kapp deploy-config` for default bindings.

### changeRuleBindings

Available in v0.25.0+.

`changeRuleBindings` bind specified change rules to resources matched by resource matchers. This is an alternative to using `kapp.k14s.io/change-rule` annotation to add change rules to resources. See `kapp deploy-config` for default bindings.

---
## Resource matchers

Resource matchers (as used by `rebaseRules`, `ownershipLabelRules`, `labelScopingRules`, `templateRules`, `diffAgainstLastAppliedFieldExclusionRules`, `diffAgainstExistingFieldExclusionRules` and `diffMaskRules`):

### allMatcher

Matches all resources

```yaml
allMatcher: {}
```

### anyMatcher

Matches resources that match one of matchers

```yaml
anyMatcher:
  matchers:
  - apiVersionKindMatcher: {apiVersion: apps/v1, kind: Deployment}
  - apiVersionKindMatcher: {apiVersion: extensions/v1alpha1, kind: Deployment}
```

### notMatcher

Matches any resource that does not match given matcher

```yaml
notMatcher:
  matcher:
    apiVersionKindMatcher: {apiVersion: apps/v1, kind: Deployment}
```

### andMatcher

Matches any resource that matches all given matchers

```yaml
andMatcher:
  matchers:
  - apiVersionKindMatcher: {apiVersion: apps/v1, kind: Deployment}
  - hasNamespaceMatcher: {}
```

### apiGroupKindMatcher

```yaml
apiGroupKindMatcher: {apiGroup: apps, kind: Deployment}
```

### apiVersionKindMatcher

```yaml
apiVersionKindMatcher: {apiVersion: apps/v1, kind: Deployment}
```

### kindNamespaceNameMatcher

```yaml
kindNamespaceNameMatcher: {kind: Deployment, namespace: mysql, name: mysql}
```

### hasAnnotationMatcher

Matches resources that have particular annotation

```yaml
hasAnnotationMatcher:
  keys:
  - kapp.k14s.io/change-group
```

### hasNamespaceMatcher

Matches any resource that has a non-empty namespace

```yaml
hasNamespaceMatcher: {}
```

Matches any resource with namespace that equals to one of the specified names

```yaml
hasNamespaceMatcher:
  names: [app1, app2]
```

### customResourceMatcher

Matches any resource that is not part of builtin k8s API groups (e.g. apps, batch, etc.). It's likely that over time some builtin k8s resources would not be matched.

```yaml
customResourceMatcher: {}
```

### emptyFieldMatcher

Available in v0.34.0+.

Matches any resource that has empty specified field

```yaml
emptyFieldMatcher:
  path: [aggregationRule]
```

---
## Paths

Path specifies location within a resource (as used `rebaseRules` and `ownershipLabelRules`):

```
[spec, clusterIP]
```

```
[spec, volumeClaimTemplates, {allIndexes: true}, metadata, labels]
```

```
[spec, volumeClaimTemplates, {index: 0}, metadata, labels]
```

---
## Config wrapped in ConfigMap

Available of v0.34.0+.

Config resource could be wrapped in a ConfigMap to support same deployment configuration by tools that do not understand kapp's `Config` resource directly. ConfigMap carrying kapp config must to be labeled with `kapp.k14s.io/config` and have `config.yml` data key. Such config maps will be applied to the cluster, unlike config given as `Config` resource.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-kapp-config
  labels:
    kapp.k14s.io/config: ""
data:
  config.yml: |
    apiVersion: kapp.k14s.io/v1alpha1
    kind: Config
    rebaseRules:
    - path: [rules]
      type: copy
      sources: [existing, new]
      resourceMatchers:
      - notMatcher:
          matcher:
            emptyFieldMatcher:
              path: [aggregationRule]
```

NOTE: `kapp` is _only_ affected by a `Config` (whether wrapped in a `ConfigMap` or not) when supplied as a direct input (i.e. as a `-f` argument). Any `ConfigMap` containing a `Config` is already present in the target cluster has _no affect whatsoever_ on `kapp`'s behavior.
