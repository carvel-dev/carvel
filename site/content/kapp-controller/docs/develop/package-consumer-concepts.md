---
title: Concepts for Package Consumers
---

## Namespacing

### Overview

In the packaging APIs, all the CRs are namespaced, which can create a lot of
duplication when wanting to share packages across the cluster. To account for
this, kapp-controller accepts a flag `-packaging-global-namespace`, which
configures kapp-controller to treat the provided namespace as a global namespace
for packaging resources. This means any Package and PackageMetadata CRs within
that namespace will be included in all other namespaces on the cluster, without
duplicating them. This does not apply to PackageRepositories or PackageInstalls.

### Collisions

When there is a conflict, the locally namespaced resources will take precedence
over the global ones. A conflict for Packages is defined as having the same
`spec.refName` and `spec.version`, while for PackageMetadatas it is defined as
having the same `metadata.name`. For example, if there is a globally available
PackageMetadata created from the following YAML:

```yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: simple-app.corp.com
  namespace: <global-namespace>
spec:
  categories:
  - demo
  displayName: Simple App
  longDescription: Simple app consisting of a k8s deployment and service
  shortDescription: Simple app for demoing
```

and then a new locally available PackageMetadata is created from this YAML,

```yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: simple-app.corp.com
  namespace: <local-namespace>
spec:
  categories:
  - demo
  displayName: Simple App Override
  longDescription: My locally available version of the Simple App package
  shortDescription: Simple App with some edits
```

a user listing the PackageMetadatas will see the second CR, and not the first.

### Annotations

For client discoverability, the namespace should also be present as an
annotation on the PackageRepository CRD under the
`packaging.carvel.dev/global-namespace`. Kapp controller's release
YAML comes preconfigured with this annotation.

(upcoming) If users would like to exclude the global packages from their namespace, the
annotation `packaging.carvel.dev/exclude-global-packages` can be added to
the namespace.

## Using PackageInstall's Version Selection

The following sections cover aspects of how to approach version selection when using PackageInstalls.

### Constraints

PackageInstalls offer a property called `constraints` under
`.spec.packageRef.versionSelection`.  This `constraints` property can be
used to select a specific version of a Package CR to install or include a set of
conditions to pick a version. This `constraints` property is based on semver
ranges and more details on conditions that can be included with `constraints`
can be found [here](https://github.com/blang/semver#ranges).

To select a specific version of a Package CR to use with a PackageInstall, the
full version (i.e. `.spec.version` from a Package CR) can be included in the
`constraints` property, such as what is shown below:

```yaml
packageRef:
  refName: fluent-bit.vmware.com
  versionSelection:
    constraints: "1.5.3"
```

The example above will result in version 1.5.3 of the Package being installed.

An example of using a condition to select a Package CR with `constraints` is shown below:

```yaml
packageRef:
  refName: fluent-bit.vmware.com
  versionSelection:
    constraints: ">1.5.3"
```

The above constraint will result in any version greater than `1.5.3` of the
Package being installed.  It will also automatically update to the latest
versions of the Package as they become available on the cluster.

### Prereleases

When creating a PackageInstall, by default prereleases are not included by
kapp-controller when considering which versions of a Package CR to install. To
include prereleases when creating a PackageInstall, the following can be
added to the spec:

```yaml
versionSelection:
  constraints: "3.0.0-rc.1"
  prereleases: {}
```

Specifying `prereleases: {}` will make kapp-controller consider all available
prereleases when seeing if a Package CR is available to be installed.

To filter by releases containing certain substrings, there is an `identifiers`
property under `prereleases` that can be used to only include certain
prereleases that contain the identifier, such as what is shown below:

```yaml
versionSelection:
  constraints: "3.0.0"
  prereleases:
    identifiers: [rc]
```

Multiple identifiers can be specified to include multiple types of pre-releases
(e.g. `identifiers: [rc, beta]`).

### Downgrading

In v0.25.0+ of kapp-controller, PackageInstalls feature an annotation to allow 
PackageInstalls to be downgraded to previous versions of a Package. By default, 
kapp-controller does not allow downgrading to a previous version of a Package to 
protect against certain scenarios (e.g. the latest version of a Package being removed 
resulting in a unintended reconciliation where the PackageInstall picks up a lower 
Package version that is now the latest version).

If downgrading to a previous version is desired, adding the annotation 
`packaging.carvel.dev/downgradable: ""` to a PackageInstall will allow for 
explicit or automated ways of downgrading the PackageInstall to a lower version.

```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: pkg-demo
  annotations:
    packaging.carvel.dev/downgradable: ""
spec:
  packageRef:
    refName: simple-app.corp.com
    versionSelection:
      constraints: >=1.0.0
```
