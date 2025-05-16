---
aliases: [/kapp-controller/docs/latest/packaging]
title: Package Management
---


## Overview

kapp-controller provides a declarative way to install, manage, and upgrade packages on a Kubernetes cluster. It leverages the PackageRepository, PackageMetadata, Package, and PackageInstall CRDs to do so. Get started by installing the [latest release of kapp-controller](install.md).

## Concepts & CustomResourceDefinitions

### Package

A package is a combination of configuration metadata and OCI images that informs the package manager what software it holds and how to install itself onto a Kubernetes cluster. For example, an nginx-ingress package would instruct the package manager where to download the nginx container image, how to configure the associated Deployment, and install it into a cluster. 

A Package is represented in kapp-controller using a Package CR. The Package CR is created for every new version of a package and it carries information about how to fetch, template, and deploy the package. A Package CR is a namespaced resource by default. [Learn more](package-consumer-concepts.md#namespacing) about how to share a Package CR across all namespaces within a cluster.

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  # Must be of the form '<spec.refName>.<spec.version>' (Note the period)
  name: fluent-bit.carvel.dev.1.5.3
  # The namespace this package is available in
  namespace: my-ns
spec:
  # Package name; referenced by PackageInstall;
  # - must be a valid DNS subdomain name (https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names)
  # - at least three segments separated by a '.', no trailing '.'
  # - only use subdomain names under your direct or your organization's control
  #   to avoid any future naming conflicts with domain owners.
  # Examples (assuming you own "corp.com" or its subdomains):
  # - fluent-bit.packages.corp.com
  # - frontend.corp.com
  # - frontend.apps.corp.com
  # - app1.team-x.corp.com
  # (required; string)
  refName: fluent-bit.carvel.dev
  # Package version; referenced by PackageInstall;
  # Must be valid semver as specified by https://semver.org/spec/v2.0.0.html
  # Cannot be empty (required; string)
  version: 1.5.3
  # Version release notes (optional; string)
  releaseNotes: "Fixed some bugs"
  # System requirements needed to install the package.
  # Note: these requirements will not be verified by kapp-controller on
  # installation. (optional; string)
  capacityRequirementsDescription: "RAM: 10GB"
  # Description of the licenses that apply to the package software
  # (optional; Array of strings)
  licenses:
  - "Apache 2.0"
  - "MIT"
  # Timestamp of release (iso8601 formatted string; optional)
  releasedAt: 2021-05-05T18:57:06Z
  # IncludedSoftware can be used to show the software contents of a Package.
  # This is especially useful if the underlying versions do not match the Package version
  includedSoftware:
  - displayName: fluent-bit
    version: 1.5.3
    description: fluent bit
  - displayName: fluent-webhook
    version: 2.3.4
    description: a fluent webhook
  # KappControllerVersionSelection specifies the versions of kapp-controller which can install this package.
  # PackageInstall will fail if this constraint is not met.
  kappControllerVersionSelection: 
    # Constraint to limit acceptable versions for this package.
    constraints: ">0.40.0 <1.0.0"
  # KubernetesVersionSelection specifies the versions of kubernetes which this package can be installed on.
  # PackageInstall will fail if this constraint is not met.
  kubernetesVersionSelection: 
    # Constraint to limit acceptable versions for this package.
    constraints: ">0.20.5"
  # valuesSchema can be used to show template values that
  # can be configured by users when a Package is installed.
  # These values should be specified in an OpenAPI schema format. (optional)
  valuesSchema:
    # openAPIv3 key can be used to declare template values in OpenAPIv3
    # format. Read more on using ytt to generate this schema: 
    # https://carvel.dev/kapp-controller/docs/latest/packaging-tutorial/#creating-the-custom-resources
    openAPIv3:
      title: fluent-bit.carvel.dev.1.5.3 values schema
      examples:
      - namespace: fluent-bit
      properties:
        namespace:
          type: string
          description: Namespace where fluent-bit will be installed.
          default: fluent-bit
          examples:
          - fluent-bit
  # App template used to create the underlying App CR.
  # See 'App CR Spec' docs for more info
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: registry.tkg.vmware.run/tkg-fluent-bit@sha256:...
      template:
      - ytt:
          paths:
          - config/
      - kbld:
          paths:
          # - must be quoted when included with paths
          - .imgpkg/images.yml
          - "-"
      deploy:
      - kapp: {}
```

### Package Metadata 

Package Metadata are attributes of a single package that do not change frequently and that are shared across multiple versions of a single package. It contains information similar to a project's README.md. 

It is represented in kapp-controller by a PackageMetadata CR. A PackageMetadata CR is a namespaced resource by default. [Learn more](package-consumer-concepts.md#namespacing) about how to share a PackageMetadata CR across all namespaces within a cluster.

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  # Package name (spec.refName) used by associated Package CRs
  name: fluent-bit.vmware.com
  # The namespace this package metadata is available in
  namespace: my-ns
spec:
  # Human friendly name of the package (optional; string)
  displayName: "Fluent Bit"
  # Long description of the package (optional; string)
  longDescription: "Fluent bit is an open source..."
  # Short desription of the package (optional; string)
  shortDescription: "Log processing and forwarding"
  # Base64 encoded icon (optional; string)
  iconSVGBase64: YXNmZGdlcmdlcg==
  # Name of the entity distributing the package (optional; string)
  providerName: VMware
  # List of maintainer info for the package.
  # Currently only supports the name key. (optional; array of maintainer info)
  maintainers:
  - name: "Person 1"
  - name: "Person 2"
  # Classifiers of the package (optional; Array of strings)
  categories:
  - "logging"
  - "daemon-set"
  # Description of the support available for the package (optional; string)
  supportDescription: "..."
```

### Package Repository

A package repository is a collection of packages and their metadata. Similar to a maven repository or a rpm repository, adding a package repository to a cluster gives users of that cluster the ability to install any of the packages from that repository. 

It is represented in kapp-controller by a PackageRepository CR. A PackageRepository CR is a namespaced resource by default. [Learn more](package-consumer-concepts.md#namespacing) about how to share a PackageRepository CR across all namespaces within a cluster.

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  # Any user-chosen name that describes package repository
  name: basic.carvel.dev
  # The namespace to make packages available to
  namespace: my-ns
spec:
  # pauses _future_ reconciliation; does _not_ affect
  # currently running reconciliation (optional; default=false)
  paused: true
  # specifies the length of time to wait, in time + unit
  # format, before reconciling.(optional; default=10m)
  syncPeriod: 1m
  # Must have only one directive.
  fetch:
    # pull content from within this resource; or other resources in the cluster
    inline: # NOTE: inline fetch available since v 0.31.0
      # specifies mapping of paths to their content;
      # not recommended for sensitive values as CR is not encrypted (optional)
      paths:
        dir/file.ext: file-content
      # specifies content via secrets and config maps;
      # data values are recommended to be placed in secrets (optional)
      pathsFrom:
        - secretRef:
            name: secret-name
            # specifies where to place files found in secret (optional)
            directoryPath: dir
        - configMapRef:
            name: cfgmap-name
            # specifies where to place files found in config map (optional)
            directoryPath: dir
    # pulls imgpkg bundle from Docker/OCI registry
    imgpkgBundle:
      # Docker image url; unqualified, tagged, or
      # digest references supported (required)
      image: host.com/username/image:v0.1.0
      # specifies a strategy to choose a tag (optional; v0.24.0+)
      # if specified, do not include a tag in url key
      tagSelection:
        semver:
          # list of semver constraints (see https://carvel.dev/vendir/docs/latest/versions/ for details) (required)
          constraints: ">1.0.0 <3.0.0"
          # by default prerelease versions are not included (optional; v0.24.0+)
          prereleases:
            # select prerelease versions that include given identifiers (optional; v0.24.0+)
            identifiers: [beta, rc]
    # pulls image containing packages from Docker/OCI registry
    image:
      # Image url; unqualified, tagged, or
      # digest references supported (required)
      url: host.com/username/image:v0.1.0
      # grab only portion of image (optional)
      subPath: inside-dir/dir2
      # specifies a strategy to choose a tag (optional; v0.24.0+)
      # if specified, do not include a tag in url key
      tagSelection:
        semver:
          # list of semver constraints (see https://carvel.dev/vendir/docs/latest/versions/ for details) (required)
          constraints: ">1.0.0 <3.0.0"
          # by default prerelease versions are not included (optional; v0.24.0+)
          prereleases:
            # select prerelease versions that include given identifiers (optional; v0.24.0+)
            identifiers: [beta, rc]
    # uses http library to fetch file containing packages
    http:
      # http and https url are supported;
      # plain file, tgz and tar types are supported (required)
      url: https://host.com/archive.tgz
      # checksum to verify after download (optional)
      sha256: 0a12cdef83...
      # grab only portion of download (optional)
      subPath: inside-dir/dir2
    # uses git to clone repository containing package list
    git:
      # http or ssh urls are supported (required)
      url: https://github.com/k14s/k8s-simple-app-example
      # branch, tag, commit; origin is the name of the remote (required)
      ref: origin/develop
      # grab only portion of repository (optional)
      subPath: config-step-2-template
      # skip lfs download (optional)
      lfsSkipSmudge: true
      # specifies a strategy to resolve to an explicit ref (optional; v0.24.0+)
      refSelection:
        semver:
          # list of semver constraints (see https://carvel.dev/vendir/docs/latest/versions/ for details) (required)
          constraints: ">0.4.0"
          # by default prerelease versions are not included (optional; v0.24.0+)
          prereleases:
            # select prerelease versions that include given identifiers (optional; v0.24.0+)
            identifiers: [beta, rc]
```

### Package Install

A Package Install is an actual installation of a package and its underlying resources on a Kubernetes cluster. It is represented in kapp-controller by a PackageInstall CR. A PackageInstall CR must reference a Package CR.

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: fluent-bit
  # The namespace to install the package in to
  namespace: my-ns
spec:
  # pauses _future_ reconcilation; does _not_ affect
  # currently running reconciliation (optional; default=false)
  paused: true
  # cancels current and future reconciliations (optional; default=false)
  canceled: true
  # Deletion requests for the PackageInstall/App will result in 
  # the PackageInstall/App CR being deleted, but its associated 
  # resources will not be deleted (optional; default=false)
  noopDelete: true
  # specifies the length of time to wait, in time + unit
  # format, before reconciling.(optional; default=10m)
  syncPeriod: 1m
  # specifies service account that will be used to install underlying package contents
  serviceAccountName: fluent-bit-sa
  # Specifies the default namespace to install the Package resources, by default this is
  # same as the PackageInstall namespace
  defaultNamespace: ""
  # specifies that Package should be deployed to destination cluster;
  # by default, cluster is same as where this resource resides (optional)
  # NOTE: if you provide a serviceAccountName then the cluster block will be ignored.
  cluster:
    # specifies namespace in destination cluster (optional)
    namespace: ns2
    # specifies secret containing kubeconfig (required)
    kubeconfigSecretRef:
      # specifies secret name within app's namespace (required)
      name: cluster1
      # specifies key that contains kubeconfig (optional - by default kubeconfig
      # will be expected under a key named "value")
      key: value
  packageRef:
    # Specifies the name of the package to install (required)
    refName: fluent-bit.vmware.com
    # Selects version of a package based on constraints provided (required)
    versionSelection:
      # Constraint to limit acceptable versions of a package;
      # Latest version satisfying the constraint is chosen;
      # Newly available, acceptable later versions are picked up and installed automatically. (optional)
      constraints: ">v1.5.3"
      # Include prereleases when selecting version. (optional)
      prereleases: {}
  # Values to be included in package's templating step
  # (currently only included in the first templating step) (optional)
  values:
  - secretRef:
      name: fluent-bit-values
# Populated by the controller
status:
  packageRef:
    # Kubernetes resource name of the package chosen against the constraints
    name: fluent-bit.tkg.vmware.com.v1.5.3
  # Derived from the underlying App's Status
  conditions:
  - type: ValuesSchemaCheckFailed
  - type: ReconcileSucceeded
  - type: ReconcileFailed
  - type: Reconciling
```

**Note:** Values will only be included in the first templating step of the package,
though we intend to improve this experience in later releases.

### Package Build

A PackageBuild resource is created by running `kctrl package init` to store information about how users would like to build and publish
their projects as Packages. This format is used to store configuration on the hosts filesystem, rather than on the cluster.

```yaml
apiVersion: kctrl.carvel.dev/v1alpha1
kind: PackageBuild
metadata:
  # The name of the PackageBuild (is the same as the 'spec.refName' of the Package it generates)
  name: samplepackage.corp.com
spec:
  # Describes the steps to be followed while building and releasing the project
  template:
    spec:
      # Specifies app template that will be used by the generated Package
      # NOTE: The fetch section is not included as the generated Package always
      # fetches from an 'imgpkg' bundle which is created and published when a package is released.
      app:
        spec:
          # The deploy section is copied over to the generated Package and might be used
          # to specify any additional 'rawOptions'
          deploy:
          - kapp: {}
          # Specifies how the generated Package will template the fetched config
          # The section should include paths to a `kbld` Config that describes
          # how images should be built and where they should be pushed, if images should be built
          # as a part of the release.
          # 'kctrl' will build and push images if 'kbld's Config tells it to - before 
          # 'kctrl' generates the ImagesLock file bundled into the 'imgpkg' bundle created by a release.
          template:
          # Options specified here will be used in the 'ytt' section of generated Package
          - ytt:
              paths:
              - config
          # Required (even if it does not specify paths) as 'kctrl' uses this step to generate lock
          # files and build images.
          # Paths pointing to the lockfile and piping output from the 'ytt' stage are added by 'kctrl'
          - kbld: {}
      # Describes any resources a release would have to publish
      export:
        # Publishes an 'imgpkg' bundle
      - imgpkgBundle:
          # The OCI registry the bundle should be pushed to
          image: 100mik/simple-package
          # Specifies whether or not 'kctrl' should use the ImagesLock generated while building the project
          # true, by default (when generated with 'kctrl package init')
          # NOTE: The user MUST include a path to a custom ImagesLock file in 'includePaths' if they
          # set this value to 'false'
          useKbldImagesLock: true
        # Paths to be included as a part of the published resource
        includePaths:
        - config
  # Describes the end product of the release process
  release:
  # Creates and stores Package and PackageMetadata resources on the hosts file system
  - resource: {}
```

## Advanced Use Cases

### Requiring specific versions of Kubernetes

Available as of v0.41.x

As Kubernetes APIs evolve, features can be deprecated and breaking changes can be introduced. For the contents of a
package to be successfully installed, the target cluster will need to support those associated resource versions.

kapp-controller provides a way to declare which versions of Kubernetes for which the package is compatible.

This is done in the [Package](#package) resource:

```yaml
spec:
  kubernetesVersionSelection:
    constraints: ">0.20.5"
```
_(see [Package Consumer Concepts > Constraints](package-consumer-concepts.md#constraints) for syntax.)_

If a PackageInstall resource is created for that package and the version of target cluster falls outside the given constraint, 
the installation will fail.

> ⚠️ **Unenforced Constraints** \
> kapp-controller installations prior to v0.41.x are unaware of this field in the Package CRD, ignore it, and therefore
> **cannot** honor these constraints.

If that constraint should be ignored, this can be noted in the [PackageInstall](#package-install) resource:

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  annotations:
    packaging.carvel.dev/ignore-kubernetes-version-selection: true
```

When the `ignore-kubernetes-version-selection` annotation is present on the PackageInstall, kapp-controller will
attempt to install that package, regardless of the version of the cluster.

### Requiring specific versions of kapp-controller

Available as of v0.41.x

A package may rely a feature of either kapp-controller itself or one of the bundled tools (or one of the bundled tools
used to fetch, template, or deploy). In this case, for the package to be installed successfully, the attendant version 
of kapp-controller must be deployed.

The package can declare which versions of kapp-controller are known to be compatible.

This is done in the [Package](#package) resource:

```yaml
spec:
  kappControllerVersionSelection:
    constraints: ">0.40.0 <1.0.0"
```
_(see [Package Consumer Concepts > Constraints](package-consumer-concepts.md#constraints) for syntax.)_

If a PackageInstall resource is created for that package and the version of kapp-controller on that cluster falls outside 
the given constraint, the installation will fail.

> ⚠️ **Unenforced Constraints** \
> kapp-controller installations prior to v0.41.x are unaware of this field in the Package CRD, ignore it, and therefore
> **cannot** honor these constraints.

If that constraint should be ignored, this can be noted in the [PackageInstall](#package-install) resource:

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  annotations:
    packaging.carvel.dev/ignore-kapp-controller-version-selection: true
```

When the `ignore-kapp-controller-version-selection` annotation is present on the PackageInstall, kapp-controller will
attempt to install that package, regardless of the version of kapp-controller.


## Combinations and Special Cases

### Overlapping Package Repositories 

Available as of v0.38.0

Multiple Package Repositories (PKGRs) are trivially supported, but it gets more complicated if
they include the same Package or PackageMetadata (Package[Metadata]). The rules are:

- Any Package[Metadata] with completely identical name (and version,
  for Packages), spec, annotations[1], and labels[1] that appears in multiple PKGRs
  will be associated to the first PKGR that reconciles. Subsequent PKGRs will
  reconcile without conflicts.
- If an identical Package[Metadata] is provided by multiple PKGRs, and the PKGR that owns it is
  deleted, there may be a transient period (corresponding to the PKGR sync
  period) when that package is unavailable,
  until the other PKGR that provides it reconciles again.
- If a Package[Metadata] is provided by multiple PKGRs, and while the
  name/refname match, the rest of the resource is _not_
  identical, then only the first PKGR to reconcile on the system will reconcile
  successfully. Subseuent PKGRs will fail with a nominally helpful error message
  indicating which Package[Metadata] failed to match and providing a top-level
  key (e.g. "annotations failed to match" or "spec.template failed to match").
- If a Package[Metadata] is provided by multiple PKGRs and despite having the
  same name/refname/version it is known that one of the resources is an update
  or later revision, the annotation key "packaging.carvel.dev/revision" can be
  used to provide an ordering.
  - Resources without the annotation are considered to have version -1
  - Resources with the revision annotation should have a value of the form "int"
    or "int.int" or "int.int.int.int.int...."
  - Revision 0 will be considered < revision 0.0 (longer revision is "greater
    than" shorter revision of the same numbers)
  - Revision 1.1.0 will be considered < revision 1.2.0 (semver sensibilities,
    but we don't parse '+' or other extensions)


[1] comparisons of annotations and labels exclude those annotations and labels
that are added or used by kapp or kapp-controller.
