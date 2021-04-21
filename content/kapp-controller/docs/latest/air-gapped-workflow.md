---
title: Air-gapped Workflow
---

The documentation below covers topics from the [imgpkg air-gapped workflow docs](/imgpkg/docs/latest/air-gapped-workflow) 
more concisely in order to focus on applying these workflows to kapp-controller PackageRepositories. 

## Scenario

You have a [PackageRepository](packaging#packagerepository-cr) bundle or image in an external OCI registry that you would like 
to move into an OCI registry in an air-gapped environment. Once relocated, you would like to deploy the bundle or image as part 
of a PackageRepository to a Kubernetes cluster.

## Prerequisites

In order to go through this process of moving an [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) or image to an 
air-gapped environment, you will need to have [imgpkg](/imgpkg) installed. More information on installing Carvel tools, 
including `imgpkg` can be found [here](/#whole-suite).

## PackageRepository Format

When going through this air-gapped scenario for kapp-controller PackageRepositories, you will most commonly be relocating a bundle of bundles 
(i.e. a recursive bundle) from an external OCI registry to an OCI registry in your air-gapped environment. 

When working with kapp-controller PackageRepositories, it is recommended to use the [PackageRepository bundle format](packaging#package-repository-bundle-format). 
In this format, a PackageRepository is represented as an imgpkg bundle. It is also recommended that Packages that are part of a PackageRepository be imgpkg bundles 
as documented [here](packaging#package-bundle-format). 

## Copy PackageRepository bundle or image to new location

Most of the steps documented for the [imgpkg air-gapped workflow docs](/imgpkg/docs/latest/air-gapped-workflow#step-1-finding-bundle-in-source-registry) 
still apply in the case of working with kapp-controller PackageRepositories. A summary of these docs is that you will need to copy your PackageRepository 
bundle or image with `imgpkg` via one of the following options:

- Option 1: From a common location connected to both registries. This option is more efficient because only changed image layers will be transfered between registries.
- Option 2: With intermediate tarball. This option works best when registries have no common network access.

More detailed documents for [`Option 1`](/imgpkg/docs/latest/air-gapped-workflow/#option-1-from-a-location-connected-to-both-registries) and 
[`Option 2`](/imgpkg/docs/latest/air-gapped-workflow/#option-2-with-intermediate-tarball) can be found at the attached links. 

A summary of steps for relocating a PackageRepository bundle or image to an air-gapped environment are documented for both options below:

For `Option 1`: 
* Get to a location that can access both registries. If there is no such location, you will have to use `Option 2` steps.
* [Authenticate](/imgpkg/docs/latest/auth.md) with both source and destination registries
* Run `imgpkg copy -b index.docker.io/user1/simple-app-bundle:v1.0.0 --to-repo registry.corp.com/apps/simple-app-bundle` (Replace `-b` with `-i` for images)

For `Option 2`:
* Get to a location that can access source registry
* [Authenticate] with the source registry(/imgpkg/docs/latest/auth.md)
* Run `imgpkg copy -b index.docker.io/user1/simple-app-bundle:v1.0.0 --to-tar /tmp/my-image.tar` (Replace `-b` with `-i` for images)

Once you have your bundle or image in a location where you can access the registry in your air-gapped environment, move the bundle or image to its 
final location:

For `Option 1`: 
* Run `imgpkg copy -b registry.corp.com/apps/simple-app-bundle --to-repo final-registry.corp.xyz/apps/simple-app-bundle` (Replace `-b` with `-i` for images)

For `Option 2`:
* `imgpkg copy --tar /tmp/my-image.tar --to-repo final-registry.corp.xyz/apps/simple-app-bundle` (Replace `-b` with `-i` for images)

## Use Relocated Bundle or Image with PackageRepository

Once you have relocated the PackageRepository bundle or image into the destination OCI registry in your air-gapped environment, you can 
now reference the relocated bundle or image in the PackageRepository definition:

```yaml
---
apiVersion: install.package.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: air-gapped-repo
spec:
  fetch:
    imgpkgBundle:
      image: final-registry.corp.xyz/apps/simple-app-bundle
```

In the event your PackageRepository needs authentication to pull the bundle or image, you can specify credentials via a `secretRef`:

```yaml
---
apiVersion: install.package.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: simple-package-repository
spec:
  fetch:
    imgpkgBundle:
      image: final-registry.corp.xyz/apps/simple-app-bundle
      secretRef:
        name: my-registry-creds
```

The secret for the `secretRef` property must be created in the `kapp-controller` namespace for the PackageRepository to use this secret, 
but this may change in the future. Supported secret keys are documented [here](config#imgpkgbundle-authentication).

After applying the PackageRepository definition above to your Kubernetes cluster, you will be able to check that the PackageRepository and 
its associated Packages were successfully deployed by checking the PackageRepository status:

```bash
$ kubectl get pkgr simple-package-repository
```

You will see a message of `ReconcileSucceeded` in the `DESCRIPTION` column of the output from `kubectl` if the PackageRepository was deloyed 
successfully. You can also run `kubectl get packages` to see that all Packages were introduced successfully.
