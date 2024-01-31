---
aliases: [/imgpkg/docs/latest/basic-workflow]
title: Basic Workflow
---

## Scenario

You want to create an immutable artifact containing Kubernetes configuration and images used in that configuration. Later, you want to grab that artifact and deploy it to Kubernetes.

## Prerequisites

To complete this workflow you will need access to an OCI registry like Docker Hub, and optionally, 
a Kubernetes cluster. (If you would like to use a local registry and Kubernetes cluster, try using [Kind](https://kind.sigs.k8s.io/docs/user/local-registry/))

If you would like to deploy the results of this scenario to your Kubernetes cluster, you will additionally need [`kbld`](/kbld) and kubectl.

## Step 1: Creating the bundle

1. Prepare bundle contents

    The [examples/basic-step-1/](https://github.com/carvel-dev/imgpkg/tree/develop/examples/basic-step-1) directory has a `config.yml` file, which contains a very simple Kubernetes application. Your application may have as many configuration files as necessary in various formats such as plain YAML, ytt templates, Helm templates, etc.

    In our example `config.yml` includes an image reference to `docker.io/dkalinin/k8s-simple-app`. This reference does not point to an exact image (via digest) meaning that it may change over time. To ensure we get precisely the bits we expect, we will lock it down to an exact image next.

1. Add `.imgpkg/` directory

    [examples/basic-step-2](https://github.com/carvel-dev/imgpkg/tree/develop/examples/basic-step-2) shows what a `.imgpkg/` directory may look like. It contains:

    - **optional** [bundle.yml](resources.md#bundle-metadata): a file which records informational metadata
    - **required** [images.yml](resources.md#imageslock): a file which records image references used by the configuration

    ```bash-plain
    examples/basic-step-2
    ├── .imgpkg
    │   ├── bundle.yml
    │   └── images.yml
    └── config.yml
    ```

    Note that `.imgpkg/images.yml` contains a list of images, each with fully resolved digest reference (e.g `index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4...`) and a little bit of additional metadata (e.g. `annotations` section). See [ImagesLock configuration](resources.md#imageslock-configuration) for details.

    ```yaml
    apiVersion: imgpkg.carvel.dev/v1alpha1
    kind: ImagesLock
    images:
    - image: index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
      annotations:
        kbld.carvel.dev/id: docker.io/dkalinin/k8s-simple-app
    ```

    This allows us to record the exact image that will be used by our Kubernetes configuration. We expect that `.imgpkg/images.yml` would be created either manually, or in an automated way. Our recommendation is to use [kbld](/kbld) to generate `.imgpkg/images.yml`:

    ```bash-plain
    $ cd examples/basic-bundle/

    $ kbld -f config.yml --imgpkg-lock-output .imgpkg/images.yml
    ```

---
## Step 2: Pushing the bundle to a registry

1. [Authenticate with a registry](auth.md) where we will push our bundle

1. Push the bundle to the registry

    You can push the bundle with our specified contents to an OCI registry using the following command:

    ```bash-plain
    $ imgpkg push -b index.docker.io/user1/simple-app-bundle:v1.0.0 -f examples/basic-step-2

    dir: .
    dir: .imgpkg
    file: .imgpkg/bundle.yml
    file: .imgpkg/images.yml
    file: config.yml
    Pushed 'index.docker.io/user1/simple-app-bundle@sha256:ec3f870e958e404476b9ec67f28c598fa8f00f819b8ae05ee80d51bac9f35f5d'

    Succeeded
    ```

    Flags used in the command:
      * `-b` (`--bundle`) refers to a location for a bundle within an OCI registry
      * `-f` (`--file`) indicates directory contents to include

1. The pushed bundle is now available at `index.docker.io/user1/simple-app-bundle:v1.0.0`

---
## Step 3: Pulling the bundle from registry

Now that we have pushed a bundle to a registry, other users can pull it.

1. [Authenticate with the registry](auth.md) from which we'll pull our bundle

1. Download the bundle by running the following command:

    ```bash-plain
    $ imgpkg pull -b index.docker.io/user1/simple-app-bundle:v1.0.0 -o  /tmp/simple-app-bundle

    Pulling image 'index.docker.io/user1/simple-app-bundle@sha256:ec3f870e958e404476b9ec67f28c598fa8f00f819b8ae05ee80d51bac9f35f5d'
    Extracting layer 'sha256:7906b9650be657359ead106e354f2728e16c8f317e1d87f72b05b5c5ec3d89cc' (1/1)
    Locating image lock file images...
    One or more images not found in bundle repo; skipping lock file update

    Succeeded
    ```

    Flags used in the command:
      * `-b` (`--bundle`) refers to a location for a bundle within an OCI registry
      * `-o` (`--output`) indicates the destination directory on your local machine where the bundle contents will be placed

    Bundle contents will be extracted into `/tmp/simple-app-bundle` directory:

    ```bash-plain
    /tmp/simple-app-bundle
    ├── .imgpkg
    │   ├── bundle.yml
    │   └── images.yml
    └── config.yml
    ```

    __Note:__ The message `One or more images not found in bundle repo; skipping lock file update` is expected, and indicates that `/tmp/simple-app-bundle/.imgpkg/images.yml` (ImagesLock configuration) was not modified.

    If imgpkg had been able to find all images that were referenced in the [ImagesLock configuration](resources.md#imageslock-configuration) in the registry where bundle is located, then it would update `.imgpkg/images.yml` file to point to the registry-local locations.

    See what happens to the lock file if you run the same pull command after [copying](air-gapped-workflow.md#option-1-from-a-location-connected-to-both-registries) the bundle to another registry!

---
## Step 4: Use pulled bundle contents

1. Now that we have have pulled bundle contents to a local directory, we can deploy Kubernetes configuration:

    Before we apply Kubernetes configuration, let's use [kbld](/kbld) to ensure that Kubernetes configuration uses exact image reference from `.imgpkg/images.yml`. (You can of course use other tools to take advantage of data stored in `.imgpkg/images.yml`).

    ```bash-plain
    $ cd /tmp/simple-app-bundle/

    $ kbld -f ./config.yml -f .imgpkg/images.yml | kubectl apply -f-

    resolve | final: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0 -> index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
    resolve | final: index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0 -> index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0

    service/simple-app configured
    deployment/simple-app configured
    ```

    kbld found `docker.io/dkalinin/k8s-simple-app` in Kubernetes configuration and replaced it with `index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0` before forwarding configuration to kubectl.

## Next steps

In this workflow we saw how to publish and download a bundle to distribute a Kubernetes application. Next, follow the [Air-gapped workflow](air-gapped-workflow.md) to see how we can use the `imgpkg copy` command to copy a bundle between registries.
