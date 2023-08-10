---
title: "Lazy Synching"
authors: [ "Fritz Duchardt <fritz.duchardt.ext@gec.io>" ]
status: "draft"
approvers: [ ]
---

# Make vendir lazy: don't syncing if the config has not changed

## Problem Statement
We have a rollout mechanism that heavily relies on vendir to pull in upstream workloads from Helm Charts, OCI Images and Git Repositories. Most of these workloads have fixed versions and don't change unless their corresponding vendir.yaml is modified. Yet, currently vendir constrains us to sync everything on every run, which slows down the process unnecessarily.

## Proposal
Add an additional config option to run sync only if the config was changed after the last sync. Users can activate this feature for all workloads they deem stable.

### Goals
Users benefit from quicker syncing process, if they use vendir to pull in stable release versions.

### Specification / Use Cases
The feature can be activated in the `vendir.yml` at `contents` level, e.g.:

```
apiVersion: vendir.k14s.io/v1alpha1
kind: Config
directories:
- path: vendor
  contents:
  - path: custom-repo-custom-version
    lazy: true
    helmChart:
      name: contour
      version: "7.10.1"
      repository:
        url: https://charts.bitnami.com/bitnami
```

Lazily `contents` are synced under two conditions:
- When their corresponding config section has changed. The mechanism works in a generic fashion for all repository types and reacts to any change to the `contents` config section. 
- When the path of the parent `directory` has changed.

To track changes to the config, the vendir.lock.yml is amended with a hash value that represents the state of a `contents` config section at the last sync, e.g.:
```
kind: LockConfig
apiVersion: vendir.k14s.io/v1alpha1
directories:
- path: vendor
  contents:
  - path: custom-repo-custom-version
    hash: e8a5d1511f2eb22b160bb849e5c8be39da1c4ffa5fd56ded71ff095a8b24720b
    helmChart:
      appVersion: 1.20.1
      version: 7.10.1
```
Hashes are only added, if vendir is run with the `lazy` setting. 

To force a sync despite the `lazy` setting, a new option is added to the vendir binary, e.g.
```
vendir sync --eager
```

### Other Approaches Considered
A simpler approach could work entirely at binary level, e.g. a lazy option to enable lazy-syncing on all `contents` of the synced vendir.yml:
```
vendir sync --lazy
```
The implementation for this feature would be much simpler, since an upfront comparison of vendir.yml and vendir.lock.yml would simply stop execution. A modification to the sync implementation that checks for changes individually for each `contents`, selectively skipping syncs while still building a valid lock file would not be required. 

With this approach one loses the ability to activate `lazy` syncing separately for specific `contents`. 


## Open Questions


## Answered Questions
