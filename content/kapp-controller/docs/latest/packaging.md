---
title: Packaging
---

The new release candidate of kapp-controller adds new APIs to bring common package
management workflows to a Kubernetes cluster.  This is done using four new CRs:
PackageRepository, PackageMetadata, Package, and PackageInstall, which are
described further in their respective sections.

We would love any and all
feedback regarding these APIs or any documentation relating to them! (Ping us on
Slack)

## Install

These APIs or only available in the latest release candidate, so see the
documentation on [installing the latest release candidate of
kapp-controller](install-alpha.md) to get started.

## Terminology

To ensure understanding of the newly introduced CRDs and their uses,
establishing a shared vocabulary of some terms commonly used
in package management may be necessary.

### Package

A single package is a combination of configuration metadata and OCI images that
ultimately inform the package manager what software it holds and how to install
it into a Kubernetes cluster. For example, an nginx-ingress package would
instruct the package manager where to download the nginx container image, how to
configure the associated Deployment, and install it into a cluster.

### Package Repositories

A package repository is a collection of packages that are grouped together.
By informing the package manager of the location of a package repository, the
user gives the package manager the ability to install any of the packages the
repository contains.

---
## CRDs

### PackageMetadata CR

The PackageMetadata CR is a place to store information that isn't specific to a
particular version of the package and instead describes the package at a high
level, similar to a github README.

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  # Must consist of three segments separated by a '.'
  # Cannot have a trailing '.'
  name: fluent-bit.vmware.com
  # The namespace this package metadata is available in
  # See Namespacing section below for details on global packages
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
  # Currently only supports the name key. (optional; array of maintner info)
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

### Package CR

For any version specific information, such as where to fetch manifests, how to
install them, and whats changed since the last version, there is the
Package CR. This CR is what will be used when kapp-controller actually
installs a package to the cluster.

**Note:** for the initial release, dependency management is not handled by kapp-controller

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  # Must be of the form '<spec.refName>.<spec.version>' (Note the period)
  name: fluent-bit.carvel.dev.1.5.3
  # The namespace this package is available in
  # See Namespacing section below for details on global packages
  namespace: my-ns
spec:
  # The name of the PackageMetadata associated with this version
  # Must be a valid PackageMetadata name (see PackageMetadata CR for details)
  # Cannot be empty
  refName: fluent-bit.carvel.dev
  # Package version; Referenced by PackageInstall;
  # Must be valid semver (required)
  # Cannot be empty
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
  # valuesSchema can be used to show template values that
  # can be configured by users when a Package is installed.
  # These values should be specified in an OpenAPI schema format. (optional)
  valuesSchema:
    # openAPIv3 key can be used to declare template values in OpenAPIv3
    # format
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
          - "-"
          - .imgpkg/images.yml
      deploy:
      - kapp: {}
```

### PackageRepository CR

This CR is used to point kapp-controller to a package repository (which contains
Package and PackageMetadata CRs). Once a PackageRepository has been added to the
cluster, kapp-controller will automatically make all packages within the store
available for installation on the cluster.

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  # Any user-chosen name that describes package repository
  name: basic.carvel.dev
  # The namespace to make packages available to
  # See  Namespacing section below for details on global repos
  namespace: my-ns
spec:
  # pauses _future_ reconcilation; does _not_ affect
  # currently running reconciliation (optional; default=false)
  paused: true
  # specifies the length of time to wait, in time + unit
  # format, before reconciling.(optional; default=5m)
  syncPeriod: 1m
  # Must have only one directive.
  fetch:
    # pulls imgpkg bundle from Docker/OCI registry
    imgpkgBundle:
      # Docker image url; unqualified, tagged, or
      # digest references supported (required)
      image: host.com/username/image:v0.1.0
    # pulls image containing packages from Docker/OCI registry
    image:
      # Image url; unqualified, tagged, or
      # digest references supported (required)
      url: host.com/username/image:v0.1.0
      # grab only portion of image (optional)
      subPath: inside-dir/dir2
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
```

Example usage:

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: my-pkg-repo.corp.com
  namespace: my-ns
spec:
  fetch:
    imgpkgBundle:
      image: registry.corp.com/packages/my-pkg-repo:1.0.0
```

### PackageInstall CR

This CR is used to install a particular package, which ultimately results in
installation of the underlying resources onto a cluster. It must reference an
existing Package CR.

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: fluent-bit
  # The namespace to install the package in to
  namespace: my-ns
spec:
  # specifies service account that will be used to install underlying package contents
  serviceAccountName: fluent-bit-sa
  packageRef:
    # Specifies the name of the package to install (required)
    refName: fluent-bit.vmware.com
    # Selects version of a package based on constraints provided (optional)
    # Either version or versionSelection is required.
    versionSelection:
      # Constraint to limit acceptable versions of a package;
      # Latest version satisying the constraint is chosen;
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

**Note:** In this alpha release, values will only be included in the first
templating step of the package, though we intend to improve this experience in
later alpha releases.

## Namespacing

In the packaging APIs, all the CRs are namespaced, which can create a lot of
duplication when wanting to share packages across the cluster. To account for
this, kapp-controller accepts a flag `-packaging-global-namespace`, which
configures kapp-controller to treat the provided namespace as a global namespace
for packaging resources. This means any Package and PackageMetadata CRs within
that namespace will be included in all other namespaces on the cluster, without
duplicating them. This does not apply to PackageRepositories or PackageInstalls.

For client discoverability, the namespace should also be present as an
annotation on the PackageRepository CRD under the
`kapp-controller.carvel.dev/packaging-global-namespace`. Kapp controller's release
yaml comes preconfigured with this annotation.

If users would like to exclude the global packages from their namespace, the
annotation `kapp-controller.carvel.dev/exclude-global-packages` can be added to
the namespace.

## Versioning PackageInstalls

The following sections cover aspects of how to approach versioning when using PackageInstalls.

### Constraints

PackageInstalls offer a property called `constraints` under
`.spec.packageVersionRef.versionSelection`.  This `constraints` property can be
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

---
## Artifact formats

### Package bundle format

A package bundle is an [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) that
holds package contents such as Kubernetes YAML configuration, ytt templates,
Helm templates, etc.

Filesystem structure used for package bundle creation:

```bash
my-pkg/
└── .imgpkg/
    └── images.yml
└── config/
    └── deployment.yml
    └── service.yml
    └── ingress.yml
```

- `.imgpkg/` directory (required) is a standard directory for any imgpkg bundle
  - `images.yml` file (required) contains container image refs used by configuration (typically generated with `kbld`)
- `config/` directory (optional) should contain arbitrary package contents such as Kubernetes YAML configuration, ytt templates, Helm templates, etc.
  - Recommendations:
    - Group Kubernetes configuration into a single directory (`config/` is our
      recommendation for the name) so that it could be easily referenced in the
      Package CR (e.g. using `ytt` template step against single directory)

See [Creating a package](package-authoring.md#creating-a-package) for example creation steps.

### Package Repository bundle format

A package repository bundle is an [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) that holds PackageMetadata and Package CRs.

Filesystem structure used for package repository bundle creation:

```bash
my-pkg-repo/
└── .imgpkg/
    └── images.yml
└── packages/
    └── simple-app.corp.com
        └── metadata.yml
        └── 1.0.0.yml
        └── 1.2.0.yml
```

- `.imgpkg/` directory (required) is a standard directory for any imgpkg bundle
  - `images.yml` file (required) contains package bundle refs used by Package CRs (typically generated with `kbld`)
- `packages/` directory (required) should contain zero or more YAML files describing available packages
  - Each file may contain one or more PackageMetadata or Package CRs (using standard YAML document separator)
  - Files may be grouped in directories or kept flat
  - File names do not have any special meaning
  - Recommendations:
    - Separate packages in to directories with the package name
    - Keep each PackageMetadata CR in a `metadata.yml` file in the package's
      directory.
    - Keep each versioned package in a file with the version name inside the package's
      directory
    - Always have a PackageMetadata CR if you have Package CRs

See [Creating a Package Repository](package-authoring.md#creating-a-package-repository) for example creation steps.
