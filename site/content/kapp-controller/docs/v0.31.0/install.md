---

title: Install
---

Grab the latest copy of YAML from the [Releases page](https://github.com/carvel-dev/kapp-controller/releases) and use your favorite deployment tool (such as [kapp](/kapp) or kubectl) to install it.

Example:

```bash
$ kapp deploy -a kc -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

or

```bash
$ kubectl apply -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
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
2. Bind the kapp-controller cluster role to a security context constraint that allows uids/gids that kapp deployment uses
(currently uid 1000; value given for `runAsUser` in the release.yaml for your
version of kapp-controller).
The security context constraint you provide should allow kapp-controller's uid
to run and should not have root privileges.
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kapp-controller-cluster-role
rules:
- apiGroups:
  - security.openshift.io
  resourceNames:
  - my-nonroot-security-context-contstraint
  resources:
  - securitycontextconstraints
  verbs:
  - use
```
3. Set the `IMGPKG_ENABLE_IAAS_AUTH` [environment
   variable](/imgpkg/docs/latest/auth/#via-iaas) to false.


### Kubernetes versions >= 1.24
All kapp-controller versions <= v0.36.1 will be unable to reconcile
PackageInstall and App CRs with the `LegacyServiceAccountTokenNoAutoGeneration`
feature gate, which is enabled by default in Kubernetes starting in v1.24.

### Kubernetes versions < 1.20
Starting in kapp-controller 0.31.0 we have upgraded our underlying kubernetes
libraries which will try to use APIs that don't exist on clusters v1.19 and
earlier.

Those using k8s v1.19 and earlier will see a repeating error message such as the one below, because
our libraries are hardcoded to watch `v1beta1.PriorityLevelConfiguration` and that won't exist on your cluster.
```
k8s.io/client-go@v0.22.4/tools/cache/reflector.go:167: Failed to watch *v1beta1.PriorityLevelConfiguration: failed to list *v1beta1.PriorityLevelConfiguration: the server could not find the requested resource (get prioritylevelconfigurations.flowcontrol.apiserver.k8s.io)
```
While kapp-controller will still work, your logs may fill at a remarkable pace.

To disable these APIs, set the deployment config variable
`enable_api_priority_and_fairness` to false.
