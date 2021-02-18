---
title: Packaging
---

Available in v0.17.0-alpha.1+

**Disclaimer:** These APIs are still very much in an alpha stage, so changes
will almost certainly be made and no backwards compatibility is guaranteed
between alpha versions.

The new alpha release of kapp-controller adds new APIs to
bring common package management workflows to a Kubernetes cluster.
This is done using three new CRs: PackageRepository, Package, and
InstalledPackage, which are described further in their respective sections.
As this is still an alpha feature, we would love any and all feedback regarding these
APIs or any documentation relating to them! (Ping us on Slack)

## Install alpha release of kapp-controller

Run:

```bash
$ kapp deploy -a kc -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/dev-packaging/alpha-releases/v0.17.0-alpha.1.yml
```

## Terminology

To ensure understanding of the newly introduced CRDs and their uses,
establishing a shared vocabulary of some terms commonly used
in package management may be necessary.

### Package

A single package is a combination of configuration metadata and OCI images that ultimately inform the package manager what software it holds and how to install it into a Kubernetes cluster. For example, an nginx-ingress package would instruct the package manager where to download the nginx container image, how to configure associated Deployment, and install it into a cluster.

### Package Repositories

A package repository is a collection of packages that are grouped together.
By informing the package manager of the location of a package repository, the
user gives the package manager the ability to install any of the packages the
repository contains.

---
## CRDs

### Package CR

In kapp-controller, a package is represented by the Package CR. The Package CR
contains versioned metadata which tells kapp-controller where to find the
kubernetes manifests which make up the package's underlying workload and how
to template and install those manifests.

**Note:** for this alpha release, dependency management is not handled by kapp-controller

```yaml
apiVersion: packages.carvel.dev/v1alpha1
kind: Package
metadata:
  # Resource name. Should not be referenced by InstalledPackage.
  # Should only be populated to comply with Kubernetes resource schema.
  # spec.publicName/spec.version fields are primary identifiers
  # used in references from InstalledPackage
  name: fluent-bit.vmware.com.1.5.3
  # Package is a cluster scoped resource, so no namespace
spec:
  # Name of the package; Referenced by InstalledPackage (required)
  publicName: fluent-bit.vmware.com
  # Package version; Referenced by InstalledPackage;
  # Must be valid semver (required)
  version: 1.5.3
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
          - -
          - .imgpkg/images.yml
      deploy:
      - kapp: {}
```

### PackageRepository CR

This CR is used to point kapp-controller to a package repository (which contains Package CRs). Once a PackageRepository has been added to the cluster, kapp-controller will automatically make all packages within the store available for installation on the cluster.

```yaml
apiVersion: install.package.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  # Any user-chosen name that describes package repository
  name: basic.vmware.com
  # PackageRepository is a cluster scoped resource, so no namespace
spec:
  # Must have only one directive.
  fetch:
    # TODO support imgpkgBundle
    # pulls image containing packages from Docker/OCI registry
    image:
      # Image url; unqualified, tagged, or
      # digest references supported (required)
      url: host.com/username/image:v0.1.0
      # secret with auth details (optional)
      secretRef:
        name: secret-name
      # grab only portion of image (optional)
      subPath: inside-dir/dir2
    # uses http library to fetch file containing packages
    http:
      # http and https url are supported;
      # plain file, tgz and tar types are supported (required)
      url: https://host.com/archive.tgz
      # checksum to verify after download (optional)
      sha256: 0a12cdef83...
      # secret to provide auth details (optional)
      secretRef:
        name: secret-name
      # grab only portion of download (optional)
      subPath: inside-dir/dir2
    # uses git to clone repository containing package list
    git:
      # http or ssh urls are supported (required)
      url: https://github.com/k14s/k8s-simple-app-example
      # branch, tag, commit; origin is the name of the remote (required)
      ref: origin/develop
      # secret with auth details. allowed keys: ssh-privatekey, ssh-knownhosts, username, password (optional)
      # (if ssh-knownhosts is not specified, git will not perform strict host checking)
      secretRef:
        name: secret-name
      # grab only portion of repository (optional)
      subPath: config-step-2-template
      # skip lfs download (optional)
      lfsSkipSmudge: true
```

### InstalledPackage CR

This CR is used to install a particular package which ultimately results in installation of package resources onto a cluster. It must reference one of the Package CRs.

```yaml
apiVersion: install.package.carvel.dev/v1alpha1
kind: InstalledPackage
metadata:
  name: fluent-bit
  namespace: my-ns
spec:
  # specifies service account that will be used to install underlying package contents
  serviceAccountName: fluent-bit-sa
  packageRef:
    # Public name of the package to install. (required)
    publicName: fluent-bit
    # Specifies a specific version of a package to install (optional)
    # Either version or versionSelection is required.
    version: 1.5.3
    # Selects version of a package based on constraints provided (optional)
    # Either version or versionSelection is required.
    versionSelection:
      # Constraint to limit acceptable versions of a package;
      # Latest version satisying the contraint is chosen;
      # Newly available, acceptable later versions are picked up and installed automatically. (optional)
      constraint: ">v1.5.3"
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
