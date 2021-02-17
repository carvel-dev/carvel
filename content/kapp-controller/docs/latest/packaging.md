---
title: Packaging (v0.17.0-alpha.1+)
---

The new alpha release of kapp-controller adds new apis to
bring common package management workflows to a kubernetes cluster.
This is done using three new CRs, PackageRepository, Package, and
InstalledPackage, which are described further in their respective sections.
As this is still an alpha feature, we would love any and all feedback regarding these
apis or any documentation relating to them!

**Disclaimer:** These apis are still very much in an alpha stage, so changes
will almost certainly be made and no backwards compatibility is guaranteed
between alpha versions.

## Installation

Just run:

```
$ kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/tree/dev-packaging/alpha-releases/v0.17.0-alpha.1.yml
```

or

```
$ kubectl apply -f https://github.com/vmware-tanzu/carvel-kapp-controller/tree/dev-packaging/alpha-releases/v0.17.0-alpha.1.yml
```

## Terminology

To ensure understanding of the newly introduced CRDs and their uses,
establishing a shared vocabulary of some terms commonly used
in package management may be necessary.

### Packages
Packages are collections of metadata which inform the package manager
where to find all the necessary resources for installation of some underlying
workload or workloads (executables, apps, etc) as well as how to
install them. For example, a simple curl package would instruct the package
manager where to download the curl binary from and how to place that
downloaded binary on to the PATH. Once the manager has gone through the
installation steps and the underlying resources have been installed, the
package is considered installed as well. Concisely, installing a package on the
system == installing the package's underlying workload(s) on the system.

### Package Repositories
These are simply collections of packages that can be found at a single location.
By informing the package manager of the location of a package repository, the
user gives the package manager the ability to install any of the packages the
repository contains.

## The CRDs

### Package CR

In kapp-controller, a package is represented by the Package CR. The Package CR
contains versioned metadata which tells kapp-controller where to find the
kubernetes manifests which make up the package's underlying workload and how
to template and install those manifests.

**Note:** for this alpha release, dependency management is not handled by kapp-controller

Package Spec:

```yaml
apiVersion: packages.carvel.dev/v1alpha1
kind: Package
metadata:
  # Resource name. Should not be referenced by InstalledPackage.
  # Should only be populated to comply with Kubernetes resource schema.
  # spec.publicName/spec.version fields are primary identifiers
  # used in references from InstalledPackage
  name: fluent-bit.v1.5.3
  # cluster scoped resource so no namespace
spec:
  # Name of the package; Referenced by InstalledPackage (required)
  publicName: fluent-bit
  # Package version; Referenced by InstalledPackage;
  # Must be valid semver (required)
  version: v1.5.3
  # App template used to create the underlying app. See 'App CR Spec' docs for more
  # info
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: registry.tkg.vmware.run/tkg-fluent-bit@sha256:...
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
```

### PackageRepository CR

This CR is used to point kapp-controller to a store of Package CRs. Once a
PackageRepository has been added to the cluster, kapp-controller will automatically
make any packages within the store available for installation on the cluster.

PackageRepository Spec:

```yaml
apiVersion: install.package.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: basic.vmware.com
  # cluster scoped resource so no namespace
spec:
  # Must have only one directive.
  fetch:
    # pulls content from imgpkg bundle stored in Docker/OCI registry
    imgpkgBundle:
      # Image url; unqualified, tagged, or
      # digest references supported (required)
      image: host.com/username/image:v0.1.0
      # secret with auth details (optional)
      secretRef:
        name: secret-name
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
### InstalledPackage

This CR is added when a user wants to install a particular package.
Once kapp-controller notices an InstalledPackage has been added to the
desired state, it will work to make it a reality. This is done by ensuring the
referenced Package CR's underlying workload is installed on the cluster,
which equates to the package being installed.

InstalledPackage Spec:
```yaml
apiVersion: install.package.carvel.dev/v1alpha1
kind: InstalledPackage
metadata:
  name: fluent-bit
  namespace: my-ns
spec:
  # specifies that app should be deployed authenticated via
  # given service account, found in this namespace (optional)
  serviceAccountName: default-cluster-admin
  packageRef:
    # Public name of the package to install. (required)
    publicName: fluent-bit
    # Specifies a specific version of a package to install (optional)
    version: v1.5.3
    # Selects version of a package based on constraints provided (optional)
    versionSelection:
      # Constraint to limit acceptable versions of a package;
      # Latest version satisying the contraint is chosen;
      # Newly available, acceptable later versions are picked up and installed automatically. (optional)
      constraint: ">v1.5.3"
      # Include prereleases when selecting version. (optional)
	    prereleases: {}
  # Values to be included in package's templating step (currently only included
  # in the first templating step)
  values:
    secretRef:
      name: ...
# Populated by the controller
status:
  PackageRef:
    # Resource name of the package chosen against the constraints
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

