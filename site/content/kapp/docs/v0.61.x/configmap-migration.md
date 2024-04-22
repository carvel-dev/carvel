---
aliases: [/kapp/docs/latest/configmap-migration]
title: Configmap Migration (experimental)
---

## Overview

Kapp internally uses a configmap to store information about an application.

This configmap name has defaulted to the app name supplied during a deploy. `kapp deploy -a <app_name>`.

Example:

```bash
kapp deploy -a my-app -f app.yml --yes

$ kapp ls
Namespace  Name        Namespaces  Lcs   Lca
default    my-app      default     true  7s

$ kubectl get configmaps

NAME     DATA   AGE
my-app   1      1m
```

This is challenging when users also want to create a configmap named `my-app` for their application. It is not expected that `kapp` is already using this configmap name.

## Enabling Configmap migration 

As of v0.47.0+, kapp now supports a new optional boolean environment variable `KAPP_FQ_CONFIGMAP_NAMES` which can be used to migrate **both new and existing configmaps** to the new naming convention: `<app_name>.apps.k14s.io`. 

- `KAPP_FQ_CONFIGMAP_NAMES=true` opts into the new kapp behavior.
- `KAPP_FQ_CONFIGMAP_NAMES=false` maintains the current kapp behavior.

*Important Note: The app name is not being changed, only the configmap name, all references to the app name can remain the same.*

### Examples

#### Deploy new App

```bash
export KAPP_FQ_CONFIGMAP_NAMES=true

kapp deploy -a my-app -f app.yml --yes

$ kapp ls
Namespace  Name        Namespaces  Lcs   Lca
default    my-app      default     true  7s

$ kubectl get configmaps

NAME                      DATA   AGE
my-app.apps.k14s.io       1      1m
```

#### Deploy existing App

```bash
$ kapp ls
Namespace  Name        Namespaces  Lcs   Lca
default    my-app      default     true  7s

export KAPP_FQ_CONFIGMAP_NAMES=true

$ kapp deploy -a my-app -f app.yml --yes

$ kubectl get configmaps

NAME                      DATA   AGE
my-app.apps.k14s.io       1      1m
```

#### Delete

```bash
# With migration enabled
$ KAPP_FQ_CONFIGMAP_NAMES=true kapp delete -a my-app

Changes

Namespace  Name                         Kind           Conds.  Age  Op      Op st.  Wait to  Rs  Ri
default    simple-app                   Deployment     2/2 t   28m  delete  -       delete   ok  -

# With migration disabled
$ KAPP_FQ_CONFIGMAP_NAMES=false kapp delete -a my-app

App 'my-app' (namespace: default) does not exist

```

### Caveats

1. Migrated apps will show up with the suffix with previous versions of kapp (0.46.0-):

```bash
export KAPP_FQ_CONFIGMAP_NAMES=true

kapp deploy -a my-app -f app.yml --yes

$ kapp ls
Namespace  Name        Namespaces  Lcs   Lca
default    my-app      default     true  7s

# With old kapp versions
$ kapp ls
Namespace  Name                     Namespaces  Lcs   Lca
default    my-app.apps.k14s.io      default     true  7s
```

### Opting out after migration

To return to the previous configmap naming convention, the following steps must be followed:

1. `kubectl get configmap my-app.apps.k14s.io -o yaml > app.yml`

2. Find the `metadata.name` field in `app.yml` and remove the suffix `.apps.k14s.io`

3. Find the annotation named `kapp.k14s.io/is-configmap-migrated` in `metadata.annotations` and remove it

4. `kubectl create -f app.yml`

5. `kubectl delete configmap my-app.apps.k14s.io`

*Important Note: Ensure the configmap with suffix `apps.k14s.io` is deleted after opting-out!*   
