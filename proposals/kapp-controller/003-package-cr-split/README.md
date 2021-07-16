---
title: "Splitting the Package CR"
authors: [ "Eli Wrenn <ewrenn@vmware.com>" ]
status: "accepted"
approvers: [ "Dmitriy Kalinin <dkalinin@vmware.com>" ]
---

# Splitting the Package CR

## Problem Statement
Currently, the means of discovering which packages are available on a cluster
can be overwhelming. Because the Package CR is versioned uniquely, when users
list packages, there will be an entry for every version of software shipped.
This can quickly grow to be thousands via a few mature repositories, which
provides an undesirable experience of sifting through thousands of package
versions to discover which packages are available on the cluster.

Also, because each Package CR contains, and is versioned along with, all of the
metadata fields, there will be massive amount of duplication present in
sufficiently large package offerings. For example, every version of a particular
package will likely have the same logo, but because logo is a field of a
versioned Package CR, it will need to be duplicated for every version. This
duplication will lead to unnecessary storage consumption by kapp-controller.

These two issues combined provide a sub par experience for consumers of the
packaging APIs.

## Terminology / Concepts

Definitions and details about packaging APIs and concepts can be found in the
[documentation](https://carvel.dev/kapp-controller/docs/latest/packaging/).

## Proposal

### Goals and Non-goals

#### Goals
- Provide a better experience for consumers trying to discover packages
  available on their cluster
- Provide a way to reduce duplication of metadata fields

### Specification
In order to achieve the above goals, we will split what is the current Package
CR in to two CR's, Package and PackageVersion.

#### Package CR
As mentioned, in the current state, a Package CR contains both version-specific
data, such as the spec section, as well as version agnostic data, such as
description. For example,

```yaml
apiVersion: package.carvel.dev/v1alpha1
kind: Package
metadata:
  name: fluent-bit.vmware.com.v1.5.3
spec:
  publicName: fluent-bit.vmware.com # aka package name
  version: v1.5.3                       # aka package version
  displayName: "Fluent Bit"
  description: "Fluent Bit is an open source and multi-platform..."
  template: # type of App CR
    spec:
      fetch:
      - imgpkgBundle:
          image: registry.vmware.run/tkg-fluent-bit@sha256:...
      template:
      - ytt:
          paths:
          - config
      - kbld:
          paths:
          - -
          - .imgpkg/images.yml
      deploy:
      - kapp: {}
  valuesSchema:
    # generated from templates (like ytt, helm chart, etc.)
    openAPIV3Schema:
      ...
```

In the proposed state, the Package CR will continue to exist, but will instead
act as the place for authors to specify any unversioned metadata about their
package, such as a logo, description, etc. A Package will remain a unique
cluster scoped resource that states a package is available. For example,

```yaml
apiVersion: package.carvel.dev/v1alpha1
kind: Package
metadata:
  name: fluent-bit.vmware.com
  # cluster scoped
spec:
  displayName: "Fluent Bit"
  icon: "<encoded image>"
  shortDescription: "Fluent Bit is an open source and multi-platform..."
  longDescription: "..."
  provider: VMware
  maintainers: ...
  category: logging
  support: ...
```

will show users that a package named `fluent-bit.vmware.com` is available and
tells them, at a high-level, any information they would need to know about it.

By extracting this unversioned information, we are able to reduce the
duplication within the cluster as well as provide a more straight-forward
discovery experience, which will be explored more in the Use Cases section.

#### PackageVersion CR
The new PackageVersion CR will contain any version-specific information, such as
particular resources to install, how to install them, release notes, etc. It
must also be associated with a high-level package definition via a reference to
the Package CR. An example of the PackageVersion CR:

```yaml
apiVersion: package.carvel.dev
kind: PackageVersion
metadata:
  name: fluent-bit.vmware.com.1.5.3
spec:
  packageName: fluent-bit.vmware.com
  version: 1.5.3
  template: # type of App CR
    spec:
      fetch:
      - imgpkgBundle:
          image: registry.vmware.run/fluent-bit@sha256:...
      template:
      - ytt:
          paths:
          - config
      - kbld:
          paths:
          - -
          - .imgpkg/images.yml
      deploy:
      - kapp: {}
  valuesSchema:
    # generated from templates (like ytt, helm chart, etc.)
    openAPIV3Schema:
  releaseNotes: |
    ...
  systemRequirements: ...
  license: ...
```

Because PackageVersions must reference a higher level package definition, if
that package does not exist, kapp-controller will create an empty Package CR
with the correct name.

#### InstalledPackage CR
This CR will remain largely unchanged, except for a slight update to how
the desired Package is referenced.

```yaml
apiVersion: install.package.carvel.dev/v1alpha1
kind: InstalledPackage
metadata:
  name: fluent-bit
  namespace: my-namespace
spec:
  serviceAccountName: default-cluster-admin
  packageName: fluent-bit.vmware.com          # No longer under packageRef key
  versionSelection:
    constraint: "1.5.3"
  values:
  - secretRef:
      name: ...
status:
  PackageVersionRef:
    name: fluent-bit.vmware.com.1.5.3
  conditions:
  - type: ValuesSchemaCheckFailed
  - type: ReconcileSucceeded
  - type: ReconcileFailed
  - type: Reconciling
```

#### Use Case: Discovering Packages

With the unversioned metadata split from the versioned, discovering packages
becomes simpler. Users will be able to list the packages installed in the
cluster and see a table consisting of a single entry for each unique package in
the cluster. The table will include columns to provide some information, such as
category, short descriptions, etc.:

```bash
$ kubectl get packages
Name                      Display Name          Description         Category
fluent-bit.vmware.com     Fluent Bit            ...                 logging
...
```

To find out more details, users can run `kubectl get
packages/fluent-bit.vmware.com` as they would with any other kubernetes
resources.

Once the desired package has been found, users can then discover versions via
`kubectl get packageversions --field-selector
packageName=fluent-bit.vmware.com`, which will display a table of information
about the versions available:

```bash
$ kubectl get packageversions --field-selector packageName=fluent-bit.vmware.com
Name                            Version               Notes Preview
fluent-bit.vmware.com.1.5.3     1.5.3                 ...
...
```

As with packages, users will be able to see more details about a specific
PackageVersion via `kubectl get packageversions/fluent-bit.vmware.com.1.5.3
-oyaml`.

After the user has discovered the package version they'd like to install, the
flow is the same, and they will create an InstalledPackage with the correct
packageName and version constraints.

#### Use Case: Installing an Instance of a Package
This consumer use case remains unchanged beyond a minor restructuring of the
InstalledPackage CR.

#### Use Case: Authoring a Package
In the proposed state, authoring a Package would also remain largely what it is
today. Authors would first create their Package CR, such that it contains all
the desired information about their package, and then author new PackageVersions
any time a new version is ready to be shipped. Authors are also able to iterate
on the Package CR as they see fit.

In the case an author wants to provide a repo that adds versions, without
redefining the package, they will be able to create a repository without a
corresponding Package CR. Once the consumers add this repository, if the package
is already available on the cluster, the new versions will simply be added, but
if the Package CR is not present, kapp-controller will automatically create an
empty Package CR with the correct name.

Note: There are some open questions related to how these CRs will be
incorporated into a repository, but these problems exist in the current state
and should not block this proposal.


### Other Approaches Considered
1. Splitting metdata that is common in Package CRs, but can be unversioned, in to a
PackageMetadata CR, which pacakges then reference.

  This approach seemed largely similar to the one described above, but would be
  less natural to consumers.

## Open Questions
1. How do we handle the case of two repositories both defining the same Package?

## Answered Questions

1. How do we handle the case of a repository containing PackageVersion CRs, but
   not the required Package CR?

   - The current thinking here is to have kapp-controller automatically add the
     needed Package CR. The CR will be empty and only created if one does not
     already exist on the cluster.
