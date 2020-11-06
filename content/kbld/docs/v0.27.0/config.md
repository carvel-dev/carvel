## Config

You can configure kbld by adding configuration resources (they follow Kubernetes resource format, but are removed from kbld output). Configuration resources may be specified multiple times.

### Sources

Sources resource configures kbld to execute image building operation based on specified path.

Two builders are currently supported: [Docker](https://docs.docker.com/engine/reference/commandline/cli/) (default) and [pack](https://github.com/buildpack/pack).

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Sources
sources:
- image: image1
  path: src/
```

#### Docker

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Sources
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

#### Pack

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Sources
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

### ImageDestinations

ImageDestinations resource configures kbld to push built images to specified location.

Currently images are pushed via Docker daemon for both Docker and pack built images (since pack also uses Docker daemon).

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: ImageDestinations
destinations:
- image: adservice
  newImage: docker.io/dkalinin/microservices-demo-adservice
```

As of v0.26.0+, additional tags could be specified to be associated with pushed image (applied via registry API):

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: ImageDestinations
destinations:
- image: adservice
  newImage: docker.io/dkalinin/microservices-demo-adservice
  tags:
  - v0.10.3
  - latest-staging
```

### ImageOverrides

ImageOverrides resource configures kbld to rewrite image location before trying to build it or resolve it.

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: ImageOverrides
overrides:
- image: unknown
  newImage: docker.io/library/nginx:1.14.2
```

It can also hold `preresolved` new image, so no building or resolution happens:

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: ImageOverrides
overrides:
- image: unknown
  newImage: docker.io/library/nginx:1.14.2
  preresolved: true
```

For preresolved images, kbld will not connect to registry to obtain any metadata.

### ImageKeys

(Deprecated as of v0.18.0+, use `searchRules` within `Config` kind to specify custom image reference matching rules.)

ImageKeys resource configures kbld to look for additional keys that reference images (in addition to using default `image` key).

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: ImageKeys
keys:
- sidecarImage
```

### Config

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
minimumRequiredVersion: 0.15.0
searchRules:
- keyMatcher:
    name: sidecarImage
- valueMatcher:
    image: exact-image
    imageRepo: gcr.io/some/repo
```

- `searchRules` (optional) allows to specify one or more matchers for finding image references. Key and value matchers could be specified together or separately. If key and value matchers are specified together, both matchers must succeed. This functionality supersedes `ImageKeys` kind. 
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

#### Example for `updateStrategy` that parses YAML

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

### Matching images

Available as of 0.15.0+

`Sources`, `ImageDestinations`, and `ImageOverrides` have ability to match images in following ways:

- via `image` to match exact content
  - e.g. `image: image1` which would only match `image1`
- via `imageRepo` to match only by registry+repo combination
  - e.g. `imageRepo: gcr.io/org/app1` which would match `gcr.io/org/app1:latest` or `gcr.io/org/app1@sha256:...` or just `gcr.io/org/app1`
