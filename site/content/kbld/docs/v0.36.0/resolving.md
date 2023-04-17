---
aliases: [/kbld/docs/latest/resolving]
title: Resolving images
---

## Resolving image references to digests

kbld looks for `image` keys within YAML documents and tries to resolve image reference to its full digest form.

For example, following

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test1
spec:
  selector:
    matchLabels:
      app: kbld-test1
  template:
    metadata:
      labels:
        app: kbld-test1
    spec:
      containers:
      - name: my-app
        image: nginx:1.14.2
        #!      ^-- image reference in its tag form
```

will be transformed to

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test1
spec:
  selector:
    matchLabels:
      app: kbld-test1
  template:
    metadata:
      labels:
        app: kbld-test1
    spec:
      containers:
      - name: my-app
        image: index.docker.io/library/nginx@sha256:f7988fb6c02e0ce69257d9bd9cf37ae20a60f1df7563c3a2a6abe24160306b8d
        #!      ^-- resolved image reference to its digest form
```

via

```bash
kbld -f file.yml
```

Few other variations

```bash
pbpaste | kbld -f-
kbld -f .
kbld -f file.yml -f config2.yml
```

### Resolving image references to digests

Available in 0.35.0+

Use `--platform` flag to resolve image indexes (a type of OCI artifact) to their particular child image based on a platform (architecture, OS, OS variant) associated with an image. If platform flag is specified and image is not an image index, no special resolution is performed.

Examples:

- `kbld -f ... --platform linux/386` selects based on an OS (`linux`) and an architecture (`386`)
- `kbld -f ... --platform linux/arm/v6` selects based on an OS (`linux`), architecture (`arm`) and variant (`v6`)

### Generating resolution `imgpkg` lock output

Available in 0.28.0+

Using the `--imgpkg-lock-output` flag, users are able to create an [ImagesLock](https://github.com/carvel-dev/imgpkg/blob/develop/docs/resources.md#imageslock) file that can be used as input for the packaging and distribution tool: [`imgpkg`](https://github.com/carvel-dev/imgpkg)

For example, the command `kbld -f input.yml --imgpkg-lock-output /tmp/imgpkg.lock.yml` with `input.yml`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test1
spec:
  selector:
    matchLabels:
      app: kbld-test1
  template:
    metadata:
      labels:
        app: kbld-test1
    spec:
      containers:
      - name: my-app
        image: nginx:1.14.2
        #!      ^-- image reference in its tag form
```

will produce `/tmp/imgpkg.lock.yml`:

```yaml
apiVersion: imgpkg.carvel.dev/v1alpha1
kind: ImagesLock
images:
- image: index.docker.io/library/nginx@sha256:f7988fb6c02e0ce69257d9bd9cf37ae20a60f1df7563c3a2a6abe24160306b8d
  annotations:
    kbld.carvel.dev/id: nginx:1.14.2
```

An ImagesLock can be included with configuration via `-f` to produce same resolved configuration, for example, `kbld -f input.yml -f /tmp/imgpkg.lock.yml` produces:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test1
spec:
  selector:
    matchLabels:
      app: kbld-test1
  template:
    metadata:
      labels:
        app: kbld-test1
    spec:
      containers:
      - name: my-app
        image: index.docker.io/library/nginx@sha256:f7988fb6c02e0ce69257d9bd9cf37ae20a60f1df7563c3a2a6abe24160306b8d
```

### Generating resolution lock output

In some cases recording resolution results may be useful. To do so add `--lock-output /path-to-file` to the `kbld` command.

For example, command `kbld -f input.yml --lock-output /tmp/kbld.lock.yml` with `input.yml`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test1
spec:
  selector:
    matchLabels:
      app: kbld-test1
  template:
    metadata:
      labels:
        app: kbld-test1
    spec:
      containers:
      - name: my-app
        image: nginx:1.14.2
        #!      ^-- image reference in its tag form
```

will produce `/tmp/kbld.lock.yml`:

```yaml
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
minimumRequiredVersion: 0.17.0
overrides:
- image: nginx:1.14.2
  newImage: index.docker.io/library/nginx@sha256:f7988fb6c02e0ce69257d9bd9cf37ae20a60f1df7563c3a2a6abe24160306b8d
  preresolved: true
```

Lock content can be included with configuration via `-f` to produce same resolved configuration, for example, `kbld -f input.yml -f /tmp/kbld.lock.yml` produces:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test1
spec:
  selector:
    matchLabels:
      app: kbld-test1
  template:
    metadata:
      labels:
        app: kbld-test1
    spec:
      containers:
      - name: my-app
        image: index.docker.io/library/nginx@sha256:f7988fb6c02e0ce69257d9bd9cf37ae20a60f1df7563c3a2a6abe24160306b8d
```
