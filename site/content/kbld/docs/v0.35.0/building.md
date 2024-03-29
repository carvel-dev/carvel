---

title: Building images
---

## Building images from source

kbld can be used to orchestrate build tools such as [Docker](https://docs.docker.com/engine/reference/commandline/cli/) and [pack](https://github.com/buildpacks/pack) to build images from source and record resulting image reference in a YAML file. This is especially convenient during local development when working with one or more changing applications.

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
        image: simple-app #! <-- unresolved image ref
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test2
spec:
  selector:
    matchLabels:
      app: kbld-test2
  template:
    metadata:
      labels:
        app: kbld-test2
    spec:
      containers:
      - name: my-app
        image: another-simple-app #! <-- unresolved image ref
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
sources:
- image: simple-app
  path: src/simple-app
- image: another-simple-app
  path: src/another-simple-app
```

(See [Configuration](config.md) for more details about `Sources`.)

Running above example via `kbld -f file.yml` will start two `docker build` processes and produce following output

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
        image: kbld:1556053998479026000-simple-app #! <-- resolved image ref
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test2
spec:
  selector:
    matchLabels:
      app: kbld-test2
  template:
    metadata:
      labels:
        app: kbld-test2
    spec:
      containers:
      - name: my-app
        image: kbld:1556053998479039000-another-simple-app #! <--resolved image ref
```

Note that because we are using Docker daemon for local images and are not pushing them into a remote registry we cannot unfortunately use digest reference form (a limitation of Docker daemon); however, tags generated by kbld uniquely identify produced images. As soon as images are pushed to a remote registry, tags are converted into digest references.

**Hint**: [Minikube](https://kubernetes.io/docs/setup/minikube/) comes with Docker daemon inside its VM. You can expose by running `eval $(minikube docker-env)` before executing kbld.

## Pushing images

As long as building tool has proper push access (run `docker login` for Docker), kbld can push out built images to specified repositories. Just add following configuration:

```yaml
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
destinations:
- image: simple-app
  newImage: docker.io/dkalinin/simple-app
- image: another-simple-app
  newImage: docker.io/dkalinin/another-simple-app
```

With addition of above configuration, kbld will produce following YAML:

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
        image: index.docker.io/dkalinin/simple-app@sha256:f7988fb6c02e... #! <-- pushed image ref
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test2
spec:
  selector:
    matchLabels:
      app: kbld-test2
  template:
    metadata:
      labels:
        app: kbld-test2
    spec:
      containers:
      - name: my-app
        image: index.docker.io/dkalinin/another-simple-app@sha256:a7355fb1007e... #! <-- pushed image ref
```
