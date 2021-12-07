---
title: Install
---

Grab the latest copy of YAML from the [Releases page](https://github.com/vmware-tanzu/carvel-kapp-controller/releases) and use your favorite deployment tool (such as [kapp](/kapp) or kubectl) to install it.

Example:

```bash
$ kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
```

or

```bash
$ kubectl apply -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
```

## Specific Environments and Distributions
Some kubernetes distributions require specific setup.
Notes below capture the wisdom of our collective community - we
appreciate your corrections and contributions to help everyone install
kapp-controller everywhere.

### Openshift
1. Explicitly set resource packageinstalls/finalizers for kapp controller cluster role to access (else the kapp controller fails to create packageinstalls).
```
kind: ClusterRole
metadata:
  name: kapp-controller-cluster-role
rules:
- apiGroups:
  - packaging.carvel.dev
  resources:
  ...
  - packageinstalls/finalizers
```
2. Bind the kapp controller cluster role to a security context constraint that allows uids/gids that kapp deployment uses.
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kapp-controller-cluster-role
rules:
- apiGroups:
  - security.openshift.io
  resourceNames:
  - nonroot
  resources:
  - securitycontextconstraints
  verbs:
  - use
```
3. Set the `IMGPKG_ENABLE_IAAS_AUTH` [environment
   variable](https://carvel.dev/imgpkg/docs/latest/auth/#via-iaas) to false.
