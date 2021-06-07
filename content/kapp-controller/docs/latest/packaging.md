---
title: Packaging
---

Available in [v0.17.0-alpha.1+](https://github.com/vmware-tanzu/carvel-kapp-controller/tree/dev-packaging/alpha-releases)

**Disclaimer:** These APIs are still very much in an alpha stage, so changes
will almost certainly be made and no backwards compatibility is guaranteed
between alpha versions.

The new alpha release of kapp-controller adds new APIs to bring common package
management workflows to a Kubernetes cluster.  This is done using four new CRs:
PackageRepository, Package, PackageVersion, and InstalledPackage, which are
described further in their respective sections.  As this is still an alpha
feature, we would love any and all feedback regarding these APIs or any
documentation relating to them! (Ping us on Slack)

## Install

See the documentation on [installing the alpha release of kapp-controller](install-alpha.md).

## Terminology

To ensure understanding of the newly introduced CRDs and their uses,
establishing a shared vocabulary of some terms commonly used
in package management may be necessary.

### Package

A single package is a combination of configuration metadata and OCI images that
ultimately inform the package manager what software it holds and how to install
it into a Kubernetes cluster. For example, an nginx-ingress package would
instruct the package manager where to download the nginx container image, how to
configure associated Deployment, and install it into a cluster.

### Package Repositories

A package repository is a collection of packages that are grouped together.
By informing the package manager of the location of a package repository, the
user gives the package manager the ability to install any of the packages the
repository contains.

---
## CRDs

### Package CR

The Package CR is a place to store metadata and information that isn't specific
to a particular version of the package and instead describes the package at a
high level, similar to a github README.

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  # Must consist of three segments separated by a '.'
  # Cannot have a trailing '.'
  name: fluent-bit.vmware.com
  # Package is a cluster scoped resource, so no namespace
spec:
  # Human friendly name of the package (optional; string)
  displayName: "Fluent Bit"
  # Long description of the package (optional; string; alpha.7+)
  longDescription: "Fluent bit is an open source..."
  # Short desription of the package (optional; string; alpha.7+)
  shortDescription: "Log processing and forwarding"
  # Base64 encoded icon (optional; string; alpha.7+)
  iconSVGBase64: YXNmZGdlcmdlcg==
  # Name of the entity distributing the package (optional; string; alpha.7+)
  providerName: VMware
  # List of maintainer info for the package.
  # Currently only supports the name key. (optional; array of maintner info; alpha.7+)
  maintainers:
  - name: "Person 1"
  - name: "Person 2"
  # Classifiers of the package (optional; Array of strings; alpha.7+)
  categories:
  - "logging"
  - "daemon-set"
  # Description of the support available for the package (optional; string; alpha.7+)
  supportDescription: "..."
```

### PackageVersion CR

For any version specific information, such as where to fetch manifests, how to
install them, and whats changed since the last version, there is the
PackageVersion CR. This CR is what will be used when kapp-controller actually
installs a package to the cluster.

**Note:** for this alpha release, dependency management is not handled by kapp-controller

```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageVersion
metadata:
  # Must begin with '<spec.packageName>.' (Note the period)
  name: fluent-bit.carvel.dev.1.5.3
spec:
  # The name of the package this version belongs to
  # Must be a valid package name (see Package CR for details)
  # Cannot be empty
  packageName: fluent-bit.carvel.dev
  # Package version; Referenced by InstalledPackage;
  # Must be valid semver (required)
  # Cannot be empty
  version: 1.5.3
  # Version release notes (optional; string; alpha.7+)
  releaseNotes: "Fixed some bugs"
  # System requirements needed to install the package.
  # Note: these requirements will not be verified by kapp-controller on
  # installation. (optional; string; alpha.7+)
  capacityRequirementsDescription: "RAM: 10GB"
  # Description of the licenses that apply to the package software
  # (optional; Array of strings; alpha.7+)
  licenses:
  - "Apache 2.0"
  - "MIT"
  # Timestamp of release (iso8601 formatted string; optional)
  releasedAt: 2021-05-05T18:57:06Z
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

This CR is used to point kapp-controller to a package repository (which contains Package CRs). Once a PackageRepository has been added to the cluster, kapp-controller will automatically make all packages within the store available for installation on the cluster.

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  # Any user-chosen name that describes package repository
  name: basic.vmware.com
  # PackageRepository is a cluster scoped resource, so no namespace
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
spec:
  fetch:
    imgpkgBundle:
      image: registry.corp.com/packages/my-pkg-repo:1.0.0
```

### InstalledPackage CR

This CR is used to install a particular package which ultimately results in
installation of package resources onto a cluster. It must reference one of the
PackageVersion CRs.

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: InstalledPackage
metadata:
  name: fluent-bit
  namespace: my-ns
spec:
  # specifies service account that will be used to install underlying package contents
  serviceAccountName: fluent-bit-sa
  packageVersionRef:
    # Specifies the name of the package to install (required)
    packageName: flluent-bit.vmware.com
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

---
## Artifact formats

### Package bundle format

Package bundle is an [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) that holds package contents such as Kubernetes YAML configuration, ytt templates, Helm templates, etc.

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
    - Group Kubernetes configuration into a single directory (`config/` is our recommendation for the name) so that it could be easily referenced in Package CR (e.g. using `ytt` template step against single directory)

See [Creating a package](package-authoring.md#creating-a-package) for example creation steps.

### Package Repository bundle format

Package repository bundle is an [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) that holds Package CRs.

Filesystem structure used for package repository bundle creation:

```bash
my-pkg-repo/
└── .imgpkg/
    └── images.yml
└── packages/
    └── simple-app.corp.com
        └── package.yml
        └── 1.0.0.yml
        └── 1.2.0.yml
```

- `.imgpkg/` directory (required) is a standard directory for any imgpkg bundle
  - `images.yml` file (required) contains package bundle refs used by PackageVersion CRs (typically generated with `kbld`)
- `packages/` directory (required) should contain zero or more YAML files describing available packages
  - Each file may contain one or more Package or PackageVersion CRs (using standard YAML document separator)
  - Files may be grouped in directories or kept flat
  - File names do not have any special meaning
  - Recommendations:
    - Separate packages in to directories with the package name
    - Keep each Package CR in a `package.yml` file in the package's
      directory.
    - Keep each package version in a file with the version name in the package's
      directory
    - Always have a Package CR if you have PackageVersion CRs

See [Creating a Package Repository](package-authoring.md#creating-a-package-repository) for example creation steps.
