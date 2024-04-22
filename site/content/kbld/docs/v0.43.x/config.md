---
aliases: [/kbld/docs/latest/config]
title: Configuration
---

## Overview

Customize how `kbld`:
- searches for image references,
- resolves image names,
- builds images from source, and
- pushes built images to container registries.

This is done by supplying one or more configuration files. These files are in the Kubernetes resource format (i.e. has `apiVersion` and `kind`). `kbld` consumes and removes such files from its output.

A `kbld` configuration file is structured like so:

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
minimumRequiredVersion: 0.31.0

searchRules: ...
overrides: ...
sources: ...
destinations: ...
```

where:
- `minimumRequiredVersion` (optional; semver) — specifies the minimum required version of `kbld` needed to work with this configuration.

and any combination of the follow four sections:
- `searchRules` — a list of [Search Rules](#search-rules) that `kbld` follows to locate container image references within the input files.
- `overrides` — a list of [Overrides](#overrides) that `kbld` applies to found container image references before it attempts to resolve or build the actual image.
- `sources` — a list of [Sources](#sources), each of which describes where to find the source that makes up the contents of a given image _and_ which build tool to use to construct it.
- `destinations` — a list of [Destinations](#destinations), each of which describes where (i.e. to which container registry) to publish a given image.

_(Note: prior to v0.28.0, different types of configuration were supplied in different `kind` of files: `kind: Sources`, `kind: ImageDestinations`, `kind: ImageOverrides`, `kind: ImageKeys`. Since v0.28.0, all such configuration can be specified in one kind of file: `kind: Config`; this  is recommended.)_

---
## Search Rules

`kbld` scans input files for references to container images. Search rules describe how `kbld` should identify those references and how to process them.

A search rule has two parts:
- conditions for matching (either by key, by value, or both), and
- a strategy for how to parse and update a matched item.

A search rule is expressed like this:

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
searchRules:
- keyMatcher: ...
  valueMatcher: ...
  updateStrategy: ...
```

where a rule consists of one or both of the following...
- `keyMatcher` a [Key Matcher](#key-matcher) — identifies container image references based on an item's key.
- `valueMatcher` a [Value Matcher](#value-matcher) — identifies container image references based on an item's value.
 
_(If both are specified, their results are "and'ed" together.)_

...and optionally,
- `updateStrategy` an [Update Strategy](#update-strategy) — what `kbld` should do with the matched container image reference.

**Multiple Matching search rules** \
If multiple search rules match the same item, the rule that was defined first is applied.

Note: `kbld` includes its own [Default Search Rules](#default-search-rules)

### Key Matcher

Specifies whether a given key indicates that its corresponding value is an image reference.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
searchRules:
- keyMatcher:
    name:
    path:
```

where:
- `name` (string) specifies the key name (e.g. `sidecarImage`)
- `path` (array) specifies key path from the root of the YAML document.\
  Each path part can be one of:
  - the literal key name. (e.g. `[data, sidecarImage]` maps to `data.sidecarImage`)
  - an array indexing tactic (choose one):
    - `index:` (int) — search one element in the array at the (zero-based) index given. \
      (example: `[spec, template, spec, containers, {index: 0}, image]`)
    - `allIndexes:` (bool) — search all elements in the array. \
      (example: `[spec, images, {allIndexes: true}]`)

### Value Matcher

Specifies whether a given value contains an image reference.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
searchRules:
- valueMatcher:
    ( image | imageRepo ):
```
where (choose one):
- `image` (string) value to match exactly
- `imageRepo` (string) of values in the format (`[registry]repo[:tag]\[@sha256:...]`), the value of the `repo` portion. \
  (example: `imageRepo: gcr.io/project/app` \
  matches `gcr.io/projects/app:v1.1` and `gcr.io/projects/app@sha256:f33e111...` \
  but not `gcr.io/projects/app_v1`)

### Update Strategy

Given a container image reference identified by one or more matchers, an Update Strategy describes how to update that value (v0.21.0+).

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
searchRules:
- ( keyMatcher | valueMatcher ): ...
  updateStrategy:
    yaml:
      searchRules: ...
    json:
      searchRules: ...
    none: {}
    entireValue: {}
```

where (choose one):
- `yaml` parses YAML and identifies image refs by specified search rules
  - `searchRules` — one or more [Search Rules](#search-rules), scoped to the parsed content.
- `json` parses JSON and identifies image refs by specified search rules
  - `searchRules` — one or more [Search Rules](#search-rules), scoped to the parsed content.
- `none` (empty) excludes value from processing (v0.22.0+)
- `entireValue` (empty; default) uses the exact value as the image reference.

#### Example for `updateStrategy` that parses YAML

```yaml
---
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

Note that in the `ConfigMap`, that `/data/data.yml` holds a multi-line string. That string happens to also be in YAML format. When _that_ YAML is parsed, the `image` key holds a container image reference.


### Default Search Rules

After custom search rules have been processed, `kbld` appends the following search rule:

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
searchRules:
- keyMatcher:
    name: image
  updateStrategy:
    entireValue: {}
```

---
## Overrides

After `kbld` searches for container image references, it applies a set of "overrides" which effectively rewrite those references. It does this _before_ attempting to build the corresponding image or resolve it to a digest reference.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
overrides:
- image:
  newImage:
  preresolved:
  tagSelection: ...
  platformSelection: ...
```

where:
- `image` (required; string) exact value found while searching for container image references.
- `newImage` (required; string) value with which to replace/override. This ought to be an image reference in the format `[registry]repo[:tag]\[@sha256:...]`. \
   Examples:
  - `nginx`
  - `quay.io/bitnami/nginx`
  - `nginx:1.21.1`
  - `nginx@sha256:a05b0cd...`
  - `index.docker.io/library/nginx@sha256:a05b0cd...`
- `preresolved` (optional; bool) specifies if `newImage` should be used as is (rather than be [re]resolved to a digest reference).
- `tagSelection` (optional; [VersionSelection](/vendir/docs/latest/versions/#versionselection-type)) when `newImage` _is_ being resolved, specifies how to select the tag part of the reference before resolving to a digest reference. (Available as of v0.28.0+)
  - In this case, `newImage` must not have a tag or digest part (e.g. `gcr.io/my-corp/app`).
- `platformSelection` (optional; map) specifies a way to select particular image within an image index. Available in 0.35.0+.
  - `architecture` (string) selects via CPU architecture. ex: `amd64`
  - `os` (string) selects via OS name. ex: `linux`
  - `os.version` (string) selects via OS version (commonly used for Windows). ex: `10.0.10586`
  - `os.features` (string array) selects via OS features (commonly used for Windows). ex: `["win32k"]`
  - `variant` (string) selects via architecture variant. ex: `armv6l`
  - `features` (string array) selects via architecture features. ex: `["sse4"]`

**Example: Static Rewrite**

With the following configuration, any container image reference of the value `"unknown"` will get rewritten to `"docker.io/library/nginx:1.14.2"` before being resolved to a digest reference.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
overrides:
- image: unknown
  newImage: docker.io/library/nginx:1.14.2
```

**Example: Preresolved**

This configuration replaces references of `"unknown"` with `"docker.io/library/nginx:1.14.2"`. It short-circuits any building, resolution, or even connecting to a registry to obtain metadata about the image reference.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
overrides:
- image: unknown
  newImage: docker.io/library/nginx:1.14.2
  preresolved: true
```

**Example: Dynamic Tag Selection**

This configuration first rewrites references of `"unknown"` with `"docker.io/library/nginx"`. It then queries the registry to locate the latest version just prior to 1.15.0 (which turns out to be 1.14.2).

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


---
## Sources

Rather than resolve an image reference, `kbld` can build the image from source. More precisely, `kbld` can be configured to use one of the many image building tools it integrates with to construct the image from source. For an overview, see [Building Images](building.md).

Such integration is enabled by configuring a "Source":

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: src/
  ( docker | pack | kubectlBuildkit | ko | bazel ): ...
```

where:
- `image` (required; string) exact value found while searching for container image references.
- `path` (required; string) filesystem path to the source for the to-be-built image.
  This path also acts as the container file context; therefore, any paths in the
  container file (when one is present) must be relative to the value of the field
  `path`.
- a builder configuration (optional; choose one) — name/configure a specific image builder tool:
  - `docker:` (default) use [Docker](#docker) or [Docker buildx](#docker-buildx) to build from source.
  - `pack:` use [Pack](#pack) to build the image via buildpacks from source.
  - `kubectlBuildkit:` use [Buildkit CLI for kubectl](#buildkit-cli-for-kubectl) to build the image via a Kubernetes cluster form source.
  - `ko:` use [ko](#ko) to build the image from Go source.
  - `bazel:` use [Bazel](#bazel) to build the image via Bazel Container Image Rules.
  

### Docker

Using this integration requires:
- Docker — https://docs.docker.com/get-docker

The [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/) must be on the `$PATH`.
 
To configure an image to be built via Docker, include a `docker:`-flavored [Source](#sources):
```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: src/
  docker:
    build:
      target: some-target
      pull: true
      noCache: true
      file: hack/Dockerfile.dev
      buildkit: true
      rawOptions: ["--squash", "--build-arg", "ARG_IN_DOCKERFILE=value"]
```
where (all options are optional):
- `target` (string): the target build stage to build (no default)
- `pull` (bool): always attempt to pull a newer version of the image (default is false)
- `noCache` (bool): do not use cache when building the image (default is false)
- `file` (string): name of the Dockerfile (default is Dockerfile)
- `buildkit` (bool): enable [Builtkit](https://docs.docker.com/develop/develop-images/build_enhancements) for this build. (Also see [Docker buildx](#docker-buildx) integration.)
- `rawOptions` ([]string): Refer to [`docker build` reference](https://docs.docker.com/engine/reference/commandline/build/) for all available options

### Docker buildx

Available as of v0.34.0+

Using this integration requires:
- Docker - https://docs.docker.com/get-docker
- Docker buildx plugin

The [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/) must be on the `$PATH`.

To configure an image to be built via Docker buildx, include a `docker:`-flavored [Source](#sources):
```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: src/
  docker:
    buildx:
      target: some-target
      pull: true
      noCache: true
      file: hack/Dockerfile.dev
      rawOptions: ["--platform=linux/amd64,linux/arm64,linux/arm/v7"]
```
where (all options are optional):
- `target` (string): the target build stage to build (no default)
- `pull` (bool): always attempt to pull a newer version of the image (default is false)
- `noCache` (bool): do not use cache when building the image (default is false)
- `file` (string): name of the Dockerfile (default is Dockerfile)
- `rawOptions` ([]string): Refer to [`docker buildx build` reference](https://docs.docker.com/engine/reference/commandline/buildx_build/) for all available options

### Pack

Using this integration requires:
- Docker — https://docs.docker.com/get-docker
- Pack — https://buildpacks.io/docs/tools/pack/

The [Pack CLI](https://buildpacks.io/docs/tools/pack/cli/pack/) must be on the `$PATH`.

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
where (all options are optional):
- `builder` (string): Set builder image (required)
- `buildpacks` ([]string): Set list of buildpacks to be used (no default)
- `clearCache` (bool): Clear cache before building image (default is false)
- `rawOptions` ([]string): Refer to `pack build -h` for all available flags

### BuildKit CLI for kubectl

Available as of v0.28.0+

Using this integration requires:
- `kubectl` — https://kubernetes.io/docs/tasks/tools/
- Buildkit for kubectl — https://github.com/vmware-tanzu/buildkit-cli-for-kubectl#installing-the-tarball \
  _(`kbld` v0.28.0+ is tested with buildkit-for-kubectl v0.1.0, but may work well with other versions.)_

The [`kubectl` CLI](https://kubernetes.io/docs/reference/kubectl/kubectl/) must be on the `$PATH`.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: src/
  kubectlBuildkit:
    build:
      target: "some-target"
      pull: true
      noCache: true
      file: "hack/Dockefile.dev"
      rawOptions: ["--platform=..."]
```

where (all options are optional):
- `target` (string): Set the target build stage to build (no default)
- `pull` (bool): Always attempt to pull a newer version of the image (default is false)
- `noCache` (bool): Do not use cache when building the image (default is false)
- `file` (string): Name of the Dockerfile (default is Dockerfile)
- `rawOptions` ([]string): Refer to `kubectl buildkit build -h` for all available options

#### Authenticating to Registry for Pushing Images

To provide registry credentials to the builder, create a Kubernetes `docker-registry` secret:

```
kubectl create secret docker-registry buildkit --docker-server=https://index.docker.io/v1/ --docker-username=my-user --docker-password=my-password
```

See project site for details: [buildkit-cli-for-kubectl](https://github.com/vmware-tanzu/buildkit-cli-for-kubectl).

### ko

Available as of v0.28.0+

Using this integration requires:
- `ko` — https://github.com/google/ko \
  (`kbld` v0.28.0+ is tested with `ko` v0.8.0, but may work well with other versions.)

The `ko` CLI must be on the `$PATH`.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: image1
  path: ./src/
  ko:
    build:
      rawOptions: ["--disable-optimizations"]
```

where:
- `rawOptions` (optional; []string): Refer to `ko publish -h` for all available options.

By default `kbld` provides the `--local` flag

### Bazel

Available as of v0.31.0+

Using this integration requires:
- Docker — https://docs.docker.com/get-docker
- Bazel — https://docs.bazel.build/versions/main/install.html \
  _(`kbld` v0.31.0+ is tested with Bazel v4.2.0 and [Container Image Rules](https://github.com/bazelbuild/rules_docker/tree/v0.18.0) v0.18.0,  but may work well with other versions.)_

The `bazel` CLI must be on the `$PATH`.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
  - image: image1
    path: ./src/
    bazel:
      run:
        target: :image1-go-container
        rawOptions: ["--platforms=@io_bazel_rules_go//go/toolchain:linux_amd64"]
```

where:
- `target` (string): bazel build target; when passed to `bazel run` will build and load the desired image.
- `rawOptions` ([]string): Refer to https://docs.bazel.build/versions/main/user-manual.html for all available options.

#### Using Language-specific Container Rules

This integration invokes the `bazel run` command (as opposed to the `bazel build` command). 

Typically, when configuring the Bazel integration with `kbld`, the specified target is one of the [Container Image Rules](https://github.com/bazelbuild/rules_docker/tree/master#bazel-container-image-rules).

With such rules, the `bazel build` command _produces_ the artifacts that make up all images described in the `BUILD`, but stops short of loading any image into the Docker daemon.  In order for an image to be pushed to a registry (i.e. published), it must first be loaded into the local Docker daemon. The `bazel run` command takes that additional step to execute the script that performs that `docker load` _for the named target, only_.

For so-called [`lang_image` rules](https://github.com/bazelbuild/rules_docker/tree/master#language-rules), this also results in launching a container from that image (i.e. `docker run` the built image). For our purposes, this is undesirable because it effectively halts the build.

To skip this that launching step, append the args `-- --norun` via the `rawOptions:` key:

```yaml
...
    bazel:
      run:
        target: :image1-go-container
        rawOptions: ["--", "--norun"]
```

See also https://github.com/bazelbuild/rules_docker#using-with-docker-locally.

---
## Destinations

Once `kbld` has processed the found container image references (either resolved or built them), it can publish those images to a different registry (on an image-by-image basis).

Pushing images to registries through this configuration requires:
- Docker — https://docs.docker.com/get-docker

(In the case where all published images are built through [BuildKit CLI for kubectl](#buildkit-cli-for-kubectl), Docker is not required; publishing happens from within the Kubernetes cluster).

Do this by configuring one or more "destinations":

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
destinations:
- image: adservice
  newImage: docker.io/dkalinin/microservices-demo-adservice
  tags: [latest, tag2]
```

where:
- `image` (required; string) exact value found while searching for container image references.
- `newImage` (required; string) image destination (i.e. fully qualified registry location for the image)
- `tags` (optional; array of strings) tags to apply to pushed images (v0.26.0+)
