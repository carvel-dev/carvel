---
aliases: [/kapp/docs/latest/diff]
title: Diff stage
---
## Overview

kapp compares resources specified in files against resources that exist in Kubernetes API. Once change set is calculated, it provides an option to apply it (see [Apply](apply.md) section for further details).

There are five different types of operations: `create`, `update`, `delete`, `noop` (shown as empty), `exists` (added in v0.43.0). Seen in `Op` column of diff summary table. Additionally there is `Op strategy` column (shorted as `Op st.`), added in v0.31.0+, that shows supplemental information how operation will be performed (for example [`fallback on replace`](apply.md#kappk14sioupdate-strategy) for `update` operation).

There are three different types of waiting: `reconcile` (waits until resource has converged to its desired state; see [apply waiting](apply-waiting.md) for waiting semantics), `delete` (waits until resource is gone), `noop` (shown as empty). Seen in `Wait to` column of diff summary table.

## Diff strategies

There are two diff strategies used by kapp:

1. kapp compares against last applied resource content (previously applied by kapp; stored in annotation `kapp.k14s.io/original`) **if** there were no outside changes done to the resource (i.e. done outside of kapp, for example, by another team member or controller); kapp tries to use this strategy as much as possible to produce more user-friendly diffs.

2. kapp compares against live resource content **if** it detects there were outside changes to the resource (hence, sometimes you may see a diff that shows several deleted fields even though these fields are not specified in the original file)

Strategy is selected for each resource individually. You can control which strategy is used for all resources via `--diff-against-last-applied=bool` flag.

Related: [rebase rules](config.md/#rebaserules).

## Versioned Resources

In some cases it's useful to represent an update to a resource as an entirely new resource. Common example is a workflow to update ConfigMap referenced by a Deployment. Deployments do not restart their Pods when ConfigMap changes making it tricky for wide variety of applications for pick up ConfigMap changes. kapp provides a solution for such scenarios, by offering a way to create uniquely named resources based on an original resource.

Anytime there is a change to a resource marked as a versioned resource, entirely new resource will be created instead of updating an existing resource. 

To make resource versioned, add `kapp.k14s.io/versioned` annotation with an empty value. Created resource follow `{resource-name}-ver-{n}` naming pattern by incrementing `n` any time there is a change.

Example:
```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-sa-sample
  annotations:
    kapp.k14s.io/versioned: ""
```
This will create versioned resource named `secret-sa-sample-ver-1`

```bash
Namespace  Name                    Kind    Conds.  Age  Op      Op st.  Wait to    Rs  Ri  
default    secret-sa-sample-ver-1  Secret  -       -    create  -       reconcile  -   -  

Op:      1 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop
```

Additionally kapp follows configuration rules (default ones, and ones that can be provided as part of application) to find and update object references (since new resource name is not something that configuration author knew about).

{{< detail-tag "Example" >}}
Sample Config
```yaml
apiVersion: kapp.k14s.io/v1alpha1
kind: Config
templateRules:
  - resourceMatchers:
      - apiVersionKindMatcher: {apiVersion: v1, kind: ConfigMap}
    affectedResources:
      objectReferences:
        - resourceMatchers:
            - apiVersionKindMatcher: {apiVersion: apps/v1, kind: Deployment}
          path: [spec, template, spec, containers, {allIndexes: true}, env, {allIndexes: true}, valueFrom, configMapKeyRef]
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: special-config
  annotations:
    kapp.k14s.io/versioned: ""
data:
  special.how: very-good
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.14.2
          ports:
            - containerPort: 80
          env:
            - name: SPECIAL_LEVEL_KEY
              valueFrom:
                configMapKeyRef:
                  name: special-config
                  key: special.how
```
Here we have specified the configuration rules that will update the ConfigMap object reference in resources of Kind Deployment. Here `ConfigMap` special-config is marked as versioned so anytime there is an update it will create a new resource with name `special-config-ver-{n}` and update the same name in resource of kind `Deployment` under `configMapKeyRef`. This example is part of [default configuration rule](https://github.com/carvel-dev/kapp/blob/28b17b775558ef4c64ce27a5655b81c00c8a2f59/pkg/kapp/config/default.go#L299) that kapp follows.
{{< /detail-tag >}}

As of v0.38.0+, `kapp.k14s.io/versioned-keep-original` annotation can be used in conjunction with `kapp.k14s.io/versioned` to have the original resource (resource without `-ver-{n}` suffix in name) along with versioned resource.

Example:
```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-sa-sample
  annotations:
    kapp.k14s.io/versioned: ""
    kapp.k14s.io/versioned-keep-original: ""
```
This will create two resources one with original name `secret-sa-sample` and one with `-ver-{n}` suffix in name `secret-sa-sample-ver-1`.
```bash
Namespace  Name                    Kind    Conds.  Age  Op      Op st.  Wait to    Rs  Ri  
default    secret-sa-sample        Secret  -       -    create  -       reconcile  -   -  
^          secret-sa-sample-ver-1  Secret  -       -    create  -       reconcile  -   -  

Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop
```

You can control number of kept resource versions via `kapp.k14s.io/num-versions=str(int)` annotation, e.g. `kapp.k14s.io/num-versions: "5"`. 

As of v0.41.0+, the `kapp.k14s.io/versioned-explicit-ref` can be used to explicitly refer to a versioned resource. This annotation allows a resource to be updated whenever a new version of the referred resource is created.

Multiple annotations with the prefix `kapp.k14s.io/versioned-explicit-ref.`(Note the "." at the end) can be used to define multiple explicit references.

Example:
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-1
  annotations:
    kapp.k14s.io/versioned: ""
data:
  foo: bar
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-2
  annotations:
    kapp.k14s.io/versioned-explicit-ref: |
      apiVersion: v1
      kind: ConfigMap
      name: config-1
data:
  foo: bar
```
Here, `config-2` explicitly refers `config-1` and is updated with the latest versioned name when `config-1` is versioned.
```bash
@@ create configmap/config-1-ver-2 (v1) namespace: default @@
  ...
  1,  1   data:
  2     -   foo: bar
      2 +   foo: alpha
  3,  3   kind: ConfigMap
  4,  4   metadata:
@@ update configmap/config-2 (v1) namespace: default @@
  ...
  8,  8         kind: ConfigMap
  9     -       name: config-1-ver-1
      9 +       name: config-1-ver-2
 10, 10     creationTimestamp: "2021-09-29T17:27:34Z"
 11, 11     labels:

Changes

Namespace  Name            Kind       Conds.  Age  Op      Op st.  Wait to    Rs  Ri  
default    config-1-ver-2  ConfigMap  -       -    create  -       reconcile  -   -  
^          config-2        ConfigMap  -       14s  update  -       reconcile  ok  -  
```

Try deploying [redis-with-configmap example](https://github.com/carvel-dev/kapp/tree/develop/examples/gitops/redis-with-configmap) and changing `ConfigMap` in a next deploy.

---
## Controlling diff via resource annotations

### kapp.k14s.io/disable-original

kapp, by default, records the resource copy into its annotation `kapp.k14s.io/original` while applying the resource to the cluster. 

{{< detail-tag "Example" >}}
Sample Config
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-1
  namespace: default
data:
  foo: bar
```
After deploying the resource, kapp added the annotation `kapp.k14s.io/original` with the content of the resource that was given to kapp:

```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-1
  namespace: default
  annotations:
    kapp.k14s.io/original: '{ "apiVersion": "v1", "kind": "ConfigMap", ...snip... }'
data:
  foo: bar
```
{{< /detail-tag >}}

`kapp.k14s.io/disable-original` annotation controls whether to record provided resource copy (rarely wanted)

Possible values: "" (empty). In some cases it's not possible or wanted to record applied resource copy into its annotation `kapp.k14s.io/original`. One such case might be when resource is extremely lengthy (e.g. long ConfigMap or CustomResourceDefinition) and will exceed annotation value max length of 262144 bytes.

{{< detail-tag "Example" >}}
Sample Config
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-1
  namespace: default
  annotations:
    kapp.k14s.io/disable-original: ""
data:
  foo: bar
```
After deploying the resource, kapp didn't add the annotation `kapp.k14s.io/original` this time:

```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-1
  namespace: default
  annotations:
    kapp.k14s.io/disable-original: ""
data:
  foo: bar
```
{{< /detail-tag >}}

---
## Controlling diff via deploy flags

Diff summary shows quick information about what's being changed:  
- `--diff-summary=bool` (default `true`) shows diff summary, listing how resources have changed
   {{< detail-tag "Example" >}}
Sample config
```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: sample
stringData:
  foo: bar
```
```bash
$ kapp deploy -a sample-secret -f config.yaml --diff-summary=true
Target cluster 'https://127.0.0.1:56540' (nodes: kind-control-plane)

Changes

Namespace  Name    Kind    Conds.  Age  Op      Op st.  Wait to    Rs  Ri  
default    sample  Secret  -       -    create  -       reconcile  -   -  

Op:      1 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: 
```
    {{< /detail-tag >}}

Diff changes (line-by-line diffs) are useful for looking at actual changes, when app is re-deployed:
- `--diff-changes=bool` (`-c`) (default `false`) shows line-by-line diffs
- `--diff-context=int` (default `2`) controls number of lines to show around changed lines
- `--diff-mask=bool` (default `true`) controls whether to mask sensitive fields
    {{< detail-tag "Example" >}}
Sample config
```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: sample
stringData:
  foo: bar
```
```bash
# deploy sample-secre app
$ kapp deploy -a sample-secret -f config.yaml

#update config
...
stringData:
  foo: bars
...

# re-deploy sample-secret app with required diff-changes flag to see line by line changes 
$ kapp deploy -a sample-secret -f config.yaml --diff-changes=true --diff-context=4
Target cluster 'https://127.0.0.1:56540' (nodes: kind-control-plane)

@@ update secret/sample (v1) namespace: default @@
  ...
 30, 30     resourceVersion: "244751"
 31, 31     uid: b2453c2a-8dc8-4ed1-9b59-791547f78ea8
 32, 32   stringData:
 33     -   foo: <-- value not shown (#1)
     33 +   foo: <-- value not shown (#2)
 34, 34   

Changes

Namespace  Name    Kind    Conds.  Age  Op      Op st.  Wait to    Rs  Ri  
default    sample  Secret  -       7m   update  -       reconcile  ok  -  

Op:      0 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

Continue? [yN]: 

# --diff-mask=true by default, note the masked value for secret data

# try out kapp deploy -a sample-secret -f config.yaml --diff-mask=false --diff-changes=true --diff-context=2
```
    {{< /detail-tag >}}

Controlling how diffing is done:

- `--diff-against-last-applied=bool` (default `true`) forces kapp to use particular diffing strategy (see above).
- `--diff-run=bool` (default `false`) set the flag to true, to stop after showing diff information.
- `--diff-exit-status=bool` (default `false`) controls exit status for diff runs (`0`: unused, `1`: any error, `2`: no changes, `3`: pending changes)
  {{< detail-tag "Example" >}}
  Sample config
```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: sample
stringData:
  foo: bar
```
```bash
# deploy secret-sample app
$ kapp deploy -a secret-sample -f config.yaml  --diff-run=true --diff-exit-status=true
Target cluster 'https://127.0.0.1:56540' (nodes: kind-control-plane)

Changes

Namespace  Name    Kind    Conds.  Age  Op      Op st.  Wait to    Rs  Ri  
default    sample  Secret  -       -    create  -       reconcile  -   -

Op:      1 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

kapp: Error: Exiting after diffing with pending changes (exit status 3)

# note that kapp exits after diff and displays the exit status

```
    {{< /detail-tag >}}

Diff filter allows to filter changes based on operation (add/update/delete), newResource (configuration provided to kapp) and existingResource (resources in Kubernetes cluster)

- `--diff-filter='{"and":[{"ops":["update"]},{"existingResource":{"kinds":["Deployment"]}]}'` will keep the resources which are getting updated and were of kind Deployment.
