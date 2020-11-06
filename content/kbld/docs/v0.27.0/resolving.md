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