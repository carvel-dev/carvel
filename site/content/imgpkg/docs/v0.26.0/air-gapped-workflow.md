---
aliases: [/imgpkg/docs/latest/air-gapped-workflow]
title: Air-gapped Workflow
---

## Scenario

You want to ensure Kubernetes application does not rely on images from external registries when deployed.

This scenario _also_ applies when trying to ensure that all images are consolidated into a single registry, even if that registry is not air-gapped.

## Prerequisites

To complete this workflow you will need access to an OCI registry like Docker Hub, and optionally, 
a Kubernetes cluster. (If you would like to use a local registry and Kubernetes cluster, try using [Kind](https://kind.sigs.k8s.io/docs/user/local-registry/))

If you would like to deploy the results of this scenario to your Kubernetes cluster, you will additionally need [`kbld`](/kbld) and kubectl.

If any of your bundles contain [non-distributable layers](commands.md#non-distributable-or-foreign-layers) you will need to include
the `--include-non-distributable-layers` flag to each copy command in the examples provided.

---
## Step 1: Finding bundle in source registry

If you have already pushed a bundle to the registry, continue to the next step.

If you are trying to bundle your own or third-part software, you will need to create a bundle. Refer to basic workflow's ["Step 1: Creating the bundle" and "Step 2: Pushing the bundle to registry"](basic-workflow.md#step-1-creating-the-bundle).

---
## Step 2: Two methods of copying bundles

You have two options how to transfer bundle from one registry to another:

- Option 1: From a common location connected to both registries. This option is more efficient because only changed image layers will be transfered between registries.
- Option 2: With intermediate tarball. This option works best when registries have no common network access.

### Option 1: From a location connected to both registries

1. Get to a location that can access both registries

    This may be a server that has access to both internal and external networks. If there is no such location, you will have to use "Option 2" below.

1. [Authenticate](auth.md) with both source, and destination registries

1. Run following command to copy bundle from one registry to another:

    ```bash-plain
    $ imgpkg copy -b index.docker.io/user1/simple-app-bundle:v1.0.0 --to-repo registry.corp.com/apps/simple-app-bundle

    copy | exporting 2 images...
    copy | will export index.docker.io/user1/simple-app-bundle@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
    copy | will export index.docker.io/user1/simple-app-bundle@sha256:70225df0a05137ac385c95eb69f89ded3e7ef3a0c34db43d7274fd9eba3705bb
    copy | exported 2 images
    copy | importing 2 images...
    copy | importing index.docker.io/user1/simple-app-bundle@sha256:70225df0a05137ac385c95eb69f89ded3e7ef3a0c34db43d7274fd9eba3705bb
           -> registry.corp.com/apps/simple-app-bundle@sha256:70225df0a05137ac385c95eb69f89ded3e7ef3a0c34db43d7274fd9eba3705bb...
    copy | importing index.docker.io/user1/simple-app-bundle@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
           -> registry.corp.com/apps/simple-app-bundle@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0...
    copy | imported 2 images
    Succeeded
    ```

    The bundle, and all images referenced in the bundle, are copied to the destination registry.

    Flags used in the command:
      * `-b` (`--bundle`) indicates the bundle location in the source registry
      * `--to-repo` indicates the registry where the bundle and associated images should be copied to

### Option 2: With intermediate tarball

1. Get to a location that can access source registry

1. [Authenticate with the source registry](auth.md)

1. Save the bundle to a tarball

    ```bash-plain
    $ imgpkg copy -b index.docker.io/user1/simple-app-bundle:v1.0.0 --to-tar /tmp/my-image.tar

    copy | exporting 2 images...
    copy | will export index.docker.io/user1/simple-app-bundle@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
    copy | will export index.docker.io/user1/simple-app-bundle@sha256:70225df0a05137ac385c95eb69f89ded3e7ef3a0c34db43d7274fd9eba3705bb
    copy | exported 2 images
    copy | writing layers...
    copy | done: file 'manifest.json' (13.71µs)
    copy | done: file 'sha256-233f1d0dbdc8cf675af965df8639b0dfd4ef7542dfc9fcfd03bfc45c570b0e4d.tar.gz' (47.616µs)
    copy | done: file 'sha256-8ece9ac45f2b7228b2ed95e9f407b4f0dc2ac74f93c62ff1156f24c53042ba54.tar.gz' (43.204905ms)
    Succeeded
    ```

    Flags used in the command:
      * `-b` (`--bundle`) indicates the bundle location in the source registry
      * `--to-tar` indicates the local location to write a tar file containing the bundle assets

1. Transfer the local tarball `/tmp/my-image.tar` to a location with access to the destination registry

1. [Authenticate with the destination registry](auth.md)

1. Import the bundle from your tarball to the destination registry:

    ```bash-plain
    $ imgpkg copy --tar /tmp/my-image.tar --to-repo registry.corp.com/apps/simple-app-bundle

    copy | importing 2 images...
    copy | importing index.docker.io/user1/simple-app-bundle@sha256:70225df0a05137ac385c95eb69f89ded3e7ef3a0c34db43d7274fd9eba3705bb -> registry.corp.com/apps/simple-app-bundle@sha256:70225df0a05137ac385c95eb69f89ded3e7ef3a0c34db43d7274fd9eba3705bb...
    copy | importing index.docker.io/user1/simple-app-bundle@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0 -> registry.corp.com/apps/simple-app-bundle@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0...
    copy | imported 2 images
    Succeeded
    ```

    The bundle, and all images referenced in the bundle, are copied to the destination registry.

    Flags used in the command:
      * `--tar` indicates the path to a tar file containing the assets to be copied to a registry
      * `--to-repo` indicates destination bundle location in the registry

---
## Step 3: Pulling bundle from destination registry

1. [Authenticate with the destination registry](auth.md)

1. Pull the bundle from the destination registry:

    ```bash-plain
    $ imgpkg pull -b registry.corp.com/apps/simple-app-bundle:v1.0.0 -o /tmp/bundle

    Pulling image 'registry.corp.com/apps/simple-app-bundle@sha256:70225df0a05137ac385c95eb69f89ded3e7ef3a0c34db43d7274fd9eba3705bb'
    Extracting layer 'sha256:233f1d0dbdc8cf675af965df8639b0dfd4ef7542dfc9fcfd03bfc45c570b0e4d' (1/1)
    Locating image lock file images...
    All images found in bundle repo; updating lock file: /tmp/bundle/.imgpkg/images.yml

    Succeeded
    ```

    Flags used in the command:
      * `-b` (`--bundle`) indicates to pull a particular bundle from a registry
      * `-o` (`--output`) indicates the local folder where the bundle will be unpacked

    Note that the `.imgpkg/images.yml` file was updated with the destination registry locations of the images. This happened because, in the prior step, the images referenced by the bundle were copied into the destination registry.

    ```bash-plain
    $ cat /tmp/bundle/.imgpkg/images.yml
    apiVersion: imgpkg.carvel.dev/v1alpha1
    kind: ImagesLock
    images:
    - image: registry.corp.com/apps/simple-app-bundle@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
      annotations:
        kbld.carvel.dev/id: docker.io/dkalinin/k8s-simple-app
    ```

---
## Step 4: Use pulled bundle contents

Regardless which location the bundle is downloaded from, source registry or destination registry, use of the pulled bundle contents remains the same. Continue with ["Step 4: Use pulled bundle contents"](basic-workflow.md#step-4-use-pulled-bundle-contents) in the basic workflow.
