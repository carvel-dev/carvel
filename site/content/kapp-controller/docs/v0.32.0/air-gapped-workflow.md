---
aliases: [/kapp-controller/docs/latest/air-gapped-workflow]
title: Install Packages in an air-gapped (offline) environment
---

The documentation below covers topics from the [imgpkg air-gapped workflow docs](/imgpkg/docs/latest/air-gapped-workflow)
more concisely in order to focus on applying these workflows to kapp-controller package repositories.

## Scenario

You have a [PackageRepository](packaging#packagerepository-cr) in an [imgpkg bundle format](/imgpkg/docs/latest/resources/#bundle)
in an external OCI registry that you would like to move into an OCI registry in an air-gapped environment. Once relocated, you would
like to deploy the bundle as part of a PackageRepository to a Kubernetes cluster.

## Prerequisites

In order to go through this process of moving an imgpkg bundle to an air-gapped environment, you will need to have [imgpkg](/imgpkg)
installed. More information on installing Carvel tools, including `imgpkg`, can be found [here](/#whole-suite).

## Copy PackageRepository bundle to new location

Most of the steps documented for the [imgpkg air-gapped workflow docs](/imgpkg/docs/latest/air-gapped-workflow#step-1-finding-bundle-in-source-registry)
still apply in the case of working with kapp-controller package repositories. A summary of these docs is that you will need to copy your package repository
bundle with `imgpkg` via one of the following options:

- **Option 1:** From a common location connected to both registries. This option is more efficient because only changed image layers will be transferred between registries.
- **Option 2:** With intermediate tarball. This option works best when registries have no common network access.

More detailed documents for [Option 1](/imgpkg/docs/latest/air-gapped-workflow/#option-1-from-a-location-connected-to-both-registries) and
[Option 2](/imgpkg/docs/latest/air-gapped-workflow/#option-2-with-intermediate-tarball) can be found at the attached links.

A summary of steps for relocating a package repository bundle to an air-gapped environment are documented for both options below:

For **Option 1**:

1. Navigate to a location that can access both registries. If there is no such location, you have to use **Option 2** steps.
1. [Authenticate](/imgpkg/docs/latest/auth.md) with both source and destination registries.
1. Copy PackageRepository bundle to the new location by running:

    ```
    imgpkg copy -b index.docker.io/user1/simple-app-bundle:v1.0.0 --to-repo final-registry.corp.com/apps/simple-app-bundle
    ```

For **Option 2**:

1. Navigate to a location that can access the source registry.
1. [Authenticate](/imgpkg/docs/latest/auth.md) with the source registry.
1. Compress PackageRepository bundle into a tarball file by running:

    ```
    imgpkg copy -b index.docker.io/user1/simple-app-bundle:v1.0.0 --to-tar /tmp/my-image.tar
    ```

    **Note:** Make sure the tar file is in a location that has access to the destination registry.

1. [Authenticate](/imgpkg/docs/latest/auth.md) with the destination registry.

1. Copy the tarball file to the new location by running:

    ```
    imgpkg copy --tar /tmp/my-image.tar --to-repo final-registry.corp.com/apps/simple-app-bundle
    ```

## Use Relocated Bundle or Image with PackageRepository

Once you have relocated the package repository bundle into the destination OCI registry in your air-gapped environment, you can
now reference the relocated bundle in a PackageRepository definition:

```yaml
---
apiVersion: install.package.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: simple-package-repository
spec:
  fetch:
    imgpkgBundle:
      image: final-registry.corp.com/apps/simple-app-bundle
```

In the event your PackageRepository needs authentication to pull the bundle, you can read more about kapp-controller's
[private authentication workflows using secretgen-controller](private-registry-auth.md) or [without secretgen-controller](private-registry-auth.md#packagerepository-authentication-without-secretgen-controller).

After applying the PackageRepository definition above to your Kubernetes cluster, you will be able to check that the PackageRepository and
its associated Packages were successfully deployed by checking the PackageRepository status:

```bash
$ kubectl get packagerepository/simple-package-repository
```

You will see a message of `Reconcile Succeeded` in the `DESCRIPTION` column of the output from `kubectl` if the PackageRepository was deloyed
successfully. You can also run `kubectl get packages` to see that all Packages were introduced successfully.
