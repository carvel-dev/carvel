---
title: Configuration
---

## Overview

You can configure kbld by adding configuration resources (they follow Kubernetes resource format, but are removed from kbld output). Configuration resources may be specified multiple times.

## Schema

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config

minimumRequiredVersion: 0.15.0

sources:
- image: adservice
  path: src/

destinations:
- image: adservice
  newImage: docker.io/dkalinin/microservices-demo-adservice

searchRules:
- keyMatcher:
    name: sidecarImage
- valueMatcher:
    image: exact-image
    imageRepo: gcr.io/some/repo

overrides:
- image: nginx
  newImage: docker.io/library/nginx:1.14.2
```

- `minimumRequiredVersion` (optional) specify minimume required version of kbld needed to work with this configuration
- `sources` (optional; array) allows to specify how to build certain images. See details in sections below.
  - `image` (required; string) image matcher
  - `path` (required; string) path to source location
  - `docker` (optional; default) use Docker to build source. [Details](#docker).
  - `pack` (optional) use pack CLI to build source. [Details](#pack).
  - `kubectlBuildkit` (optional) use Buildkit CLI for kubectl to build source. [Details](#buildkit-cli-for-kubectl).
  - `ko` (optional) use `ko` to build source. [Details](#ko).
- `destinations` (optional; array) allows to specify one or more destination where images should be pushed
  - `image` (optional) image matcher
  - `newImage` (optional) image destination (e.g. docker.io/dkalinin/app-demo)
  - `tags` (optional; array of strings) tags to apply to pushed images (e.g. `[latest, tag2]`) (v0.26.0+)
- `searchRules` (optional; array) allows to specify one or more matchers for finding image references. Key and value matchers could be specified together or separately. If key and value matchers are specified together, both matchers must succeed. This functionality supersedes `ImageKeys` kind. 
  - `keyMatcher` (optional) key matcher
    - `name` (optional; string) specifies key name (e.g. `sidecarImage`)
    - `path` (optional; array) specifies key path from the root of the YAML document (e.g. `[data, sidecarImage]`, `[spec, images, {allIndexes: true}]`)
  - `valueMatcher` (optional) value matcher
    - `image` (optional; string) matches values exactly
    - `imageRepo` (optional; string) matches values that follow image reference format (`[registry]repo[:tag]\[@sha256:...]`) and expects `repo` portion to match (e.g. `gcr.io/project/app`)
  - `updateStrategy` (optional) strategy for finding and updating image references within value (v0.21.0+)
    - `none` (optional) excludes value from processing (v0.22.0+)
    - `entireString` (optional; default) uses entire value as an image ref
    - `json` (optional) parses JSON and identifies image refs by specified search rules
      - `searchRules` ... (recursive)
    - `yaml` (optional) parses YAML and identifies image refs by specified search rules
      - `searchRules` ... (recursive)
- `overrides` (optional; array) configures kbld to rewrite image location before trying to build image or resolve it to a digest.
  - `image` (optional) image matcher
  - `newImage` (optional) could be image without tag/digest, image tag ref, or image digest ref
  - `preresolved` (optional; bool) specifies if `newImage` should be used as is
  - `tagSelection` (optional; VersionSelection) specifies how to resolve tag for `newImage`. `newImage` in this case is expected to not specify tag or digest (e.g. `gcr.io/my-corp/app`) without a tag. [See `VersionSelection` type details](https://github.com/vmware-tanzu/carvel-vendir/blob/develop/docs/versions.md#versionselection-type). Available as of v0.28.0+

---
## Sources

Sources configure kbld to execute image building operation based on specified path.

(Note: We recommend using `Config` kind with `sources` key instead of `Sources` kind. `sources` key in both kind `Config` and `Sources` has same functionality.)

Currently supported builders:

- `docker`: [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/) (default)
- `pack`: [Pack CLI](https://github.com/buildpacks/pack)
- `kubectlBuildkit`: [BuildKit CLI for kubectl](https://github.com/vmware-tanzu/buildkit-cli-for-kubectl)
- `ko`: [ko CLI](https://github.com/google/ko)

### Docker

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: src/
  docker:
    # all options shown; none are required
    build:
      target: "some-target"
      pull: true
      noCache: true
      file: "hack/Dockefile.dev"
      rawOptions: ["--squash"]
```

- `docker.build.target` (string): Set the target build stage to build (no default)
- `docker.build.pull` (bool): Always attempt to pull a newer version of the image (default is false)
- `docker.build.noCache` (bool): Do not use cache when building the image (default is false)
- `docker.build.file` (string): Name of the Dockerfile (default is Dockerfile)
- `docker.build.rawOptions` ([]string): Refer to https://docs.docker.com/engine/reference/commandline/build/ for all available options

### Pack

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: src/
  pack:
    build:
      builder: cloudfoundry/cnb:bionic
```

- `pack.build.builder` (string): Set builder image (required)
- `pack.build.buildpacks` ([]string): Set list of buildpacks to be used (no default)
- `pack.build.clearCache` (bool): Clear cache before building image (default is false)
- `pack.build.rawOptions` ([]string): Refer to `pack build -h` for all available flags

### BuildKit CLI for kubectl

Available as of v0.28.0+

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: src/
  kubectlBuildkit:
    # all options shown; none are required
    build:
      target: "some-target"
      pull: true
      noCache: true
      file: "hack/Dockefile.dev"
      rawOptions: ["--platform=..."]
```

- `kubectlBuildkit.build.target` (string): Set the target build stage to build (no default)
- `kubectlBuildkit.build.pull` (bool): Always attempt to pull a newer version of the image (default is false)
- `kubectlBuildkit.build.noCache` (bool): Do not use cache when building the image (default is false)
- `kubectlBuildkit.build.file` (string): Name of the Dockerfile (default is Dockerfile)
- `kubectlBuildkit.build.rawOptions` ([]string): Refer to `kubectl buildkit build -h` for all available options

To provide registry credentials to the builder, create a Kubernetes docker secret:

```
kubectl create secret docker-registry buildkit --docker-server=https://index.docker.io/v1/ --docker-username=my-user --docker-password=my-password
```

See project site for details: [buildkit-cli-for-kubectl](https://github.com/vmware-tanzu/buildkit-cli-for-kubectl).

### ko

Available as of v0.28.0+

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: ./src/
  ko:
    build: # all options shown; none are required
      rawOptions: ["--disable-optimizations"]
```

- `ko.build.rawOptions` ([]string): Refer to `ko publish -h` for all available options.

  By default `kbld` provides the `--local` flag

---
## Destinations

Destinations configure kbld to push built images to specified location.

Currently images are pushed via Docker daemon for both Docker and pack built images (since pack also uses Docker daemon).

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
destinations:
- image: adservice
  newImage: docker.io/dkalinin/microservices-demo-adservice
```

As of v0.26.0+, additional tags could be specified to be associated with pushed image (applied via registry API):

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
destinations:
- image: adservice
  newImage: docker.io/dkalinin/microservices-demo-adservice
  tags:
  - v0.10.3
  - latest-staging
```

### ImageDestinations

We recommend using `Config` kind with `destinations` key instead of `ImageDestinations` kind. `destinations` key in both kind `Config` and `ImageDestinations` has same functionality.

---
## Overrides

Overrides configure kbld to rewrite image location before trying to build it or resolve it to a digest.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
overrides:
- image: unknown
  newImage: docker.io/library/nginx:1.14.2
```

It can also hold `preresolved` new image, so no building or resolution happens (for preresolved images, kbld will not connect to registry to obtain any metadata):

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
overrides:
- image: unknown
  newImage: docker.io/library/nginx:1.14.2
  preresolved: true
```

`tagSelection` can be used for dynamic selection of a tag based on various strategies. Currently only `semver` strategy is available.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
overrides:
- image: unknown
  newImage: docker.io/library/nginx
  tagSelection:
    semver:
      constraints: "<1.15.0"
```

### ImageOverrides

We recommend using `Config` kind with `overrides` key instead of `ImageOverrides` kind. `overrides` key in both kind `Config` and `ImageOverrides` has same functionality.

---
### Example for `updateStrategy` that parses YAML

```yaml
kind: ConfigMap
metadata:
  name: config
data:
  data.yml: |
    name: nginx
    image: nginx # <-- below config finds and updates this image
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
minimumRequiredVersion: 0.15.0
searchRules:
- keyMatcher:
    name: data.yml
  updateStrategy:
    yaml:
      searchRules:
      - keyMatcher:
          name: image
```

---
## Matching images

Available as of 0.15.0+

`Sources`, `ImageDestinations`, and `ImageOverrides` have ability to match images in following ways:

- via `image` to match exact content
  - e.g. `image: image1` which would only match `image1`
- via `imageRepo` to match only by registry+repo combination
  - e.g. `imageRepo: gcr.io/org/app1` which would match `gcr.io/org/app1:latest` or `gcr.io/org/app1@sha256:...` or just `gcr.io/org/app1`
