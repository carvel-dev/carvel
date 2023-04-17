---
aliases: [/imgpkg/docs/latest/automation-workflow]
title: Automation Workflow
---

## Scenario

When using an automated CI tool you might want to promote a given Bundle between steps of the pipeline

## Prerequisites

To complete this workflow you will need access to an OCI registry like Docker Hub.

### Step 1: Creating the Bundle

1. Prepare bundle contents

   The [examples/basic-step-1/](https://github.com/carvel-dev/imgpkg/tree/develop/examples/basic-step-1)
   directory has a `config.yml` file, which contains a very simple Kubernetes application. Your application may have as
   many configuration files as necessary in various formats such as plain YAML, ytt templates, Helm templates, etc.

   In our example `config.yml` includes an image reference to `docker.io/dkalinin/k8s-simple-app`. This reference does
   not point to an exact image (via digest) meaning that it may change over time. To ensure we get precisely the bits we
   expect, we will lock it down to an exact image next.

1. Add `.imgpkg/` directory

   [examples/basic-step-2](https://github.com/carvel-dev/imgpkg/tree/develop/examples/basic-step-2) shows what
   a `.imgpkg/` directory may look like. It contains:

    - **optional** [bundle.yml](resources.md#bundle-metadata): a file which records informational metadata
    - **required** [images.yml](resources.md#imageslock): a file which records image references used by the
      configuration

    ```bash-plain
    examples/basic-step-2
    ├── .imgpkg
    │   ├── bundle.yml
    │   └── images.yml
    └── config.yml
    ```

   Note that `.imgpkg/images.yml` contains a list of images, each with fully resolved digest reference (
   e.g `index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4...`) and a some additional metadata (
   e.g. `annotations` section). See [ImagesLock configuration](resources.md#imageslock-configuration) for details.

    ```yaml
    apiVersion: imgpkg.carvel.dev/v1alpha1
    kind: ImagesLock
    images:
    - image: index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
      annotations:
        kbld.carvel.dev/id: docker.io/dkalinin/k8s-simple-app
    ```

---

### Step 2: Creating the Bundle

1. [Authenticate with a registry](auth.md) where we will push our bundle

2. Push the bundle to the registry

   You can push the bundle with our specified contents to an OCI registry using the following command:

    ```bash-plain
    $ imgpkg push -b index.docker.io/user1/simple-app-bundle:v1.0.0 -f examples/basic-step-2 --lock-output /tmp/bundle-lock.yml

    dir: .
    dir: .imgpkg
    file: .imgpkg/bundle.yml
    file: .imgpkg/images.yml
    file: config.yml
    Pushed 'index.docker.io/user1/simple-app-bundle@sha256:5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511'

    Succeeded
    ```

   Flags used in the command:
    - `-b` (`--bundle`) refers to a location for a bundle within an OCI registry
    - `-f` (`--file`) indicates directory contents to include
    - `--lock-output` indicates the destination of the [BundleLock](resources.md#bundlelock-configuration) file

---

## Step 3: Promoting the BundleLock file

Since in the previous step we generated a BundleLock we can promote this file and in the next steps of the pipeline we
can reference it.

Examples of usage:

1. Promote the Bundle to a different registry

   ```bash-plain
   $ imgpkg copy --lock /tmp/bundle-lock.yml --to-repo production.registry.io/simple-app-bundle
   copy | exporting 2 images...
   copy | will export index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
   copy | will export production.registry.io/simple-app-bundle@sha256:5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511
   copy | exported 2 images
   copy | importing 2 images...
   
   3.56 MiB / 3.57 MiB [========================================================================================================================================================================]  99.68% 8.80 MiB/s 0s
   
   copy | done uploading images
   
   Succeeded
   ```

   Flags used in the command:
    - `--lock` refers to a location for a BundleLock file
    - `--to-repo` indicates the destination Repository where the Bundle is copied to

2. Download the Bundle contents to disk

    ```bash-plain
    $ imgpkg pull --lock /tmp/bundle-lock.yml -o  /tmp/simple-app-bundle

    Pulling image 'index.docker.io/user1/simple-app-bundle@sha256:ec3f870e958e404476b9ec67f28c598fa8f00f819b8ae05ee80d51bac9f35f5d'
      Extracting layer 'sha256:7906b9650be657359ead106e354f2728e16c8f317e1d87f72b05b5c5ec3d89cc' (1/1)
   
    Locating image lock file images...
    The bundle repo (index.docker.io/user1/simple-app-bundle@sha256:5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511) is hosting every image specified in the bundle's Images Lock file (.imgpkg/images.yml)

    Succeeded
    ```

   Flags used in the command:
    - `--lock`e`) refers to a location for a BundleLock file
    - `-o` (`--output`) indicates the destination directory on your local machine where the bundle contents will be
      placed

   Bundle contents will be extracted into `/tmp/simple-app-bundle` directory:

    ```bash-plain
    /tmp/simple-app-bundle
    ├── .imgpkg
    │   ├── bundle.yml
    │   └── images.yml
    └── config.yml
    ```
