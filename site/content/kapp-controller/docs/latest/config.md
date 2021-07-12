---
title: App Config
---

## Example

See [App Spec](app-spec.md) for details.

```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: simple-app
spec:
  serviceAccountName: default
  fetch:
  - git:
      url: https://github.com/k14s/k8s-simple-app-example
      ref: origin/develop
      subPath: config-step-2-template
  template:
  - ytt: {}
  deploy:
  - kapp: {}
```

## spec.fetch

Fetches set of files from various sources. Multiple sources can be used (for example, `helmChart` and `inline`).

- `inline`: specify one or more files within resource
- `imgpkgBundle`: download [imgpkg bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle) from registry (available in v0.17.0+)
- `image`: download Docker image from registry
- `http`: download file at URL
- `git`: clone Git repository
- `helmChart`: fetch Helm chart from Helm repository

Pull helm chart via `helm fetch`

```yaml
spec:
  fetch:
  - helmChart:
      name: stable/concourse
  # ...
```

Pull helm chart via git

```yaml
spec:
  fetch:
  - git:
      url: https://github.com/bitnami/charts
      ref: origin/master
      subPath: bitnami/nginx
  # ...
```

Note, following sections describes contents of Secret resources referenced by various fetch strategies. kapp-controller does not check for `type` value of Secret resource.

### `image` authentication

Allowed secret keys:

- `username` and `password`
- `token`: Alternative to username/password authentication

Also supports [dockerconfigjson secret type](https://kubernetes.io/docs/concepts/configuration/secret/#docker-config-secrets) (v0.19.0+)

### `imgpkgBundle` authentication

Allowed secret keys:

- `username` and `password`
- `token`: Alternative to username/password authentication

Also supports [dockerconfigjson secret type](https://kubernetes.io/docs/concepts/configuration/secret/#docker-config-secrets) (v0.19.0+)

### `git` authentication

Allowed secret keys:

- `ssh-privatekey`: PEM-encoded key that will be provided to SSH
- `ssh-knownhosts`: Optional, set of known hosts allowed to connect (if not specified, all hosts are allowed)
- `username` and `password`: Alternative to private key authentication

### `http` authentication

Allowed secret keys:

- `username` and `password`

### `helmChart` authentication

Allowed secret keys:

- `username` and `password`

Also supports [dockerconfigjson secret type](https://kubernetes.io/docs/concepts/configuration/secret/#docker-config-secrets) (v0.19.0+)

---
## spec.template

Transform set of files.

- `helmTemplate`: uses `helm template` command to render chart
- `ytt`: uses [ytt](/ytt) to rended templates
- `kbld`: uses [kbld](/kbld) to resolve image URLs to include digests
- `kustomize`: (not implemented yet) uses kustomize to render configuration
- `jsonnnet`: (not implemented yet) renders jsonnet files
- `sops`: uses [sops](https://github.com/mozilla/sops) to decrypt secrets. [More details](sops.md). Available in v0.11.0+.

Template source via `helm template`

```yaml
spec:
  # ...
  template:
  - helmTemplate:
      valuesFrom:
      - secretRef:
          name: redis-values
  # ...
```

Template source via `helm template` and then modify via `ytt` overlay

```yaml
spec:
  # ...
  template:
  - helmTemplate: {}
  - ytt:
      ignoreUnknownComments: true
      inline:
        paths:
          remove-lb.yml: |
            #@ load("@ytt:overlay", "overlay")
            #@overlay/match by=overlay.subset({"kind":"Service","metadata":{"name":"nginx"}})
            ---
            spec:
              type: ClusterIP
              #@overlay/remove
              externalTrafficPolicy:
  # ...
```

---
## spec.deploy

Deploys resources.

- `kapp`: uses [kapp](/kapp) to deploy resources

```yaml
spec:
  # ...
  deploy:
  - kapp: {}
```
