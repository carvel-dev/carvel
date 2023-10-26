---
aliases: [/kapp-controller/docs/latest/private-registry-auth]
title: Authenticating to Private Registries
---

## Scenario

As a package consumer you may need to provide registry credentials if you are consuming package repository (and/or packages) from a registry that requires authenticated access. That may involve providing registry credentials to multiple parts of the system:

- credentials for pulling package repository bundle (via PackageRepository CR)
    - consumed by imgpkg running inside kapp-controller Pod
- credentials for pulling package contents bundle (via PackageInstall CR)
    - consumed by imgpkg running inside kapp-controller Pod
- credentials for pulling container images used by the package
    - credentials consumed by Kubelets
    - e.g. needed by cert-manager controller Pod
- credentials for pulling container images used by packages operator
    - credentials consumed by Kubelets
    - e.g. needed by Kafka cluster Pods created for KafkaInstance CR

Providing credentials manually to each one of these parts of the system can become a hassle. kapp-controller v0.24.0+ when installed together with [secretgen-controller](https://github.com/carvel-dev/secretgen-controller) v0.5.0+ allow package consumers and package authors to simplify such configuration.

Note that if you are using an IaaS provided Kubernetes cluster already preauthenticated with an IaaS provided registry, then there is no need to provide credentials manually in the cluster. kapp-controller v0.25.0+ is able to automatically pick up provided credentials to satisfy first two bullet points above. Last two bullet points are already satisfied by the Kubernetes kubelet.

## secretgen-controller's placeholder secrets and SecretExport CR

For this specific use case, secretgen-controller allows package consumer to specify registry credentials in one namespace and allows to export that secret to the entire cluster (or subset of namespaces) via [SecretExport CR](https://github.com/carvel-dev/secretgen-controller/blob/develop/docs/secret-export.md#secretexport-and-secretrequest). Registry credentials could be consumed in different namespaces via "placeholder secrets".

A placeholder secret is:
- plain Kubernetes Secret
- with `kubernetes.io/dockerconfigjson` type (more about this secret type [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#registry-secret-existing-credentials))
- has `secretgen.carvel.dev/image-pull-secret` annotation

secretgen-controller will populate placeholder Secrets with a combined registry credentials. For example:

- within `reg-creds` Namespace
  - Secret `dockerhub-reg` includes DockerHub credentials for `index.docker.io` domain
  - SecretExport CR `dockerhub-reg` specifies that same-named secret will be exported to all namespaces
  - Secret `corp-reg` includes registry credentials for `registry.corp.com` domain
  - SecretExport CR `corp-reg` specifies that same-named secret will be exported to all namespaces
- within `cert-manager-install` Namespace
  - Secret `reg-creds` has `secretgen.carvel.dev/image-pull-secret` annotation indicating to secretgen to continuously ensure that this secret is filled with combination of registry credentials that allow export to this namespace (in this case both `dockerhub-reg` and `corp-reg`)

Known limitation: Currently Secrets with type `kubernetes.io/dockerconfigjson` do not allow specifying multiple credentials for the same domain, hence you cannot provide multiple credentials for the same registry.

**Warning** Since SecretExport CR allows you to export registry credentials to other namespaces, they will become visible to users of such namespaces. We **strongly recommend** to ensure that registry credentials you are exporting only allow read-only access to the registry and are minimally scoped within the registry.

## kapp-controller CRs and placeholder secrets

As of kapp-controller v0.24.0+, PackageRepository and PackageInstall CRs automatically create placeholder secrets for `image` and `imgpkgBundle` fetch types, if no explicit `secretRef.name` is provided. (These placeholder secrets are named as `<resource-name>-fetch-<i>`.) If secretgen-controller is present on the cluster, these secrets will be populated with combined registry credentials; otherwise, they will remain empty.

## Package authoring and placeholder secrets

We encourage all package authors to include placeholder secrets within your package configuration already preconfigured to be used by your Deployments, StatefulSets, DaemonSets, Pods, etc (and any other resources that consume image pull secrets). This removes a need for package consumers to worry about configuring packages in any special way if it's being consumed from a registry that requires authentication. Note that even if you are distributing package repository from a registry that support anonymous access, package consumers may still copy it (via imgpkg copy) into a private registry that does require authentication.

Note: In future we could provide a feature to automatically inject placeholder secrets as part of package installation (e.g. via Pod webhook); however, that is a bit more intrusive, hence we are recommending explicit usage of placeholder secrets for now.

Example of a placeholder secret package authors should add next other resources:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: reg-creds
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K
```

Note: `e30K` is base64 encoded `{}`. Valid `.dockerconfigjson` value is required when creating a Secret.

## Operator writing and placeholder secrets

If you are an owner of an operator, similar to the above section, we encourage you to create a placeholder secret for Pods (or other resources that consume image pull secrets) that may be created by your operator in other namespaces. More general operator packaging docs will come soon.

---
## Bringing it all together

- Ensure kapp-controller v0.24.0+ is installed

- Install secretgen-controller v0.5.0+

    ```bash
    kapp deploy -a sg -f https://github.com/carvel-dev/secretgen-controller/releases/download/v0.5.0/release.yml
    ```

- Create registry credential Secret and use SecretExport CR to make it available for all namespaces (Note: if you use `kubectl create secret docker-registry` and you want to auth with DockerHub, please specify `--docker-server=index.docker.io` explicitly instead of relying on default server value.)

    ```yaml
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: reg-creds        # could be any name
      namespace: secrets-ns  # could be any namespace
    type: kubernetes.io/dockerconfigjson  # needs to be this type
    stringData:
      .dockerconfigjson: |
        {
          "auths": {
            "index.docker.io": {
              "username": "user...",
              "password": "password...",
              "auth": ""
            }
          }
        }

    ---
    apiVersion: secretgen.carvel.dev/v1alpha1
    kind: SecretExport
    metadata:
      name: reg-creds        # must match source secret name
      namespace: secrets-ns  # must match source secret namespace
    spec:
      toNamespaces:
      - "*"  # star means export is available for all namespaces
    ```

- Use PackageRepository and PackageInstall CRs without specifying secrets explicitly

    ```yaml
    ---
    apiVersion: packaging.carvel.dev/v1alpha1
    kind: PackageRepository
    metadata:
      name: e2e-repo.test.carvel.dev
      namespace: kapp-controller-packaging-global
    spec:
      fetch:
        imgpkgBundle:
          image: k14stest/private-repo@sha256:ddd93b...
    ---
    apiVersion: packaging.carvel.dev/v1alpha1
    kind: PackageInstall
    metadata:
      name: pkg-demo
    spec:
      serviceAccountName: default-ns-sa
      packageRef:
        refName: pkg.test.carvel.dev
        versionSelection:
          constraints: 1.0.0
    ```

Assuming registry credentials specified are correct and both package repository bundle and package contents bundle use the same registry

---
## Manual configuration (without secretgen-controller)

### PackageRepository

If the registry containing the PackageRepository imgpkg bundle or image  is private and secretgen-controller is not installed on your cluster, a secretRef can be added to the fetch stage for PackageRepository CR. For example:

```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: simple-package-repository
spec:
  fetch:
    imgpkgBundle:
      image: k8slt/corp-com-pkg-repo:1.0.0
      secretRef:
        name: my-registry-creds
```

This secret will need to be located in the namespace where the PackageRepository
is created and be in the format described in the [fetch docs](app-overview.md/#specfetch).

### PackageInstall

As of kapp-controller v0.23.0, support for adding an annotation on the PackageInstall was added to allow users to set a secret on the PackageInstall's underlying App custom resource. Before creating a PackageInstall, users can look at the Package definition that they want to install and see what fetch stages a Package has defined like below:

```yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: simple-app.corp.com.1.0.0
spec:
  refName: simple-app.corp.com
  version: 1.0.0
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: registry.corp.com/packages/simple-app:1.0.0
      # ...
```

In the example above, the Package has a single fetch stage to retrieve an imgpkg bundle. To use a PackageInstall
to specify what secret to use for this fetch stage, an annotation is added to the PackageInstall as shown below:

```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: simple-app-with-secret
  annotations:
    ext.packaging.carvel.dev/fetch-0-secret-name: simple-app-secret
spec:
  serviceAccountName: default-ns-sa
  packageRef:
    refName: simple-app.corp.com
    versionSelection:
      constraints: 1.0.0
```

The annotation shown above `ext.packaging.carvel.dev/fetch-0-secret-name: simple-app-secret` has a format that allows users to specify the specific fetch stage by how it is defined in the Package definition. In this case, the PackageInstall being created will add a secretRef to the App's first fetch stage (i.e. `fetch-0-secret-name`) for the imgpkg bundle. If the Package definition had an additional fetch stage, the secret annotation could be added in the following format: `ext.packaging.carvel.dev/fetch-1-secret-name: simple-app-additional-secret`.

To use this annotation with a PackageInstall, associated secrets will need to be located in the namespace where the PackageInstall is created and be in the format described in the [fetch docs](app-overview.md/#specfetch).
