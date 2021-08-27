---
title: Authenticating to Private Registries
---

To pull imgpkg bundles or images from registries requiring authentication, kapp-controller (v0.24.0+) 
supports a workflow to more easily manage Kubernetes secrets and use them as part of working 
with PackageRepositories or PackageInstalls. 

In addition to having kapp-controller installed, when [secretgen-controller](https://github.com/vmware-tanzu/carvel-secretgen-controller) 
is installed on the same cluster, kapp-controller will create [placeholder secrets](#placeholder-secrets) that are used when PackageRepositories or 
PackageInstalls are created. These secrets are then populated by secretgen-controller and will contain all "exported" 
registry credentials stored on a cluster as Kubernetes secrets. 

By simply adding the credentials as Kubernetes secrets in the flows mentioned below, kapp-controller will be able 
to successfully authenticate to registries without needing to manage secret references in PackageRepositories 
or PackageInstalls.

### Installing secretgen-controller

To use the authentication flows mentioned below, install secretgen-controller on the cluster where kapp-controller is installed:

```bash
kapp deploy -a sg -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.5.0/release.yml
```

### Create Registry Credentials

**NOTE:** Currently the only secret type supported for this workflow is `type: kubernetes.io/dockerconfigjson`. All 
secrets created for this approach should be in this format. More on the dockerconfigjson type can be found [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#registry-secret-existing-credentials).

After installing secretgen-controller on the same cluster as where kapp-controller is installed, registry 
credentials can be created as Kubernetes secrets and exported to specific namespaces on a cluster as shown below:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: regcred
  namespace: packagerepo-ns
type: kubernetes.io/dockerconfigjson
stringData:
  .dockerconfigjson: |
    {
      "auths": {
        "index.docker.io": {
          "username": "user",
          "password": "password",
          "auth": ""
        }
      }
    }
---
apiVersion: secretgen.k14s.io/v1alpha1
kind: SecretExport
metadata:
  name: regcred
  namespace: packagerepo-ns
spec:
  toNamespaces:
  - packagerepo-ns
```

By creating the Kubernetes secret above with registry authentication details and the [SecretExport](https://github.com/vmware-tanzu/carvel-secretgen-controller/blob/develop/docs/secret-export.md#secretexport-and-secretrequest) CRD with the 
same name as the Kubernetes secret, secretgen-controller will be able to populate a secret that is created 
by kapp-controller with these credentials. Afterwards, any PackageRepository or PackageInstall created will 
use these credentials when fetching the contents.

### Placeholder Secrets

The workflow described under the [Create Registry Credentials](#create-registry-credentials) section mentions 
that kapp-controller will create secrets when PackageRepositories or PackageInstalls are created. These secrets 
are referred to as placeholder secrets. kapp-controller will look at the PackageRepository/Package fetch 
stages to determine whether any secretRefs have been provided. 

If no secretRef is specified on the PackageRepository or Package to be installed by a PackageInstall, kapp-controller 
will always add placeholder secrets containing all the exported secrets (i.e. any secret sharing the same name as a SecretExport) 
on the Kubernetes cluster. This will also happen if no registry authentication is needed but will not affect the result of 
pulling the public bundle or image.

### PackageRepository Authentication without secretgen-controller

If the registry containing the PackageRepository imgpkg bundle or image 
is private and secretgen-controller is not installed on your cluster, a 
secretRef can be added to the fetch stage for PackageRepositories. For example:

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
is created and be in the format described in the [fetch docs](config.md#image-authentication).

### PackageInstall Authentication without secretgen-controller

In kapp-controller v0.23.0, support for adding an annotation on the PackageInstall was added to 
allow users to set a secret on the PackageInstall's underlying App custom resource. Before creating 
a PackageInstall, users can look at the Package definition that they want to install and see what 
fetch stages a Package has defined like below:

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
      template:
      - ytt:
          paths:
          - "config/"
      - kbld:
          paths:
          - "-"
          - ".imgpkg/images.yml"
      deploy:
      - kapp: {}
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
    "ext.packaging.carvel.dev/fetch-0-secret-name": "simple-app-secret"
spec:
  serviceAccountName: default-ns-sa
  packageRef:
    refName: simple-app.corp.com
    versionSelection:
      constraints: 1.0.0
```

The annotation shown above `"ext.packaging.carvel.dev/fetch-0-secret-name": "simple-app-secret"` has a format that allows 
users to specify the specific fetch stage by how it is defined in the Package definition. In this case, the PackageInstall 
being created will add a secretRef to the App's first fetch stage (i.e. `fetch-0-secret-name`) for the imgpkg bundle. If the 
Package definition had an additional fetch stage, the secret annotation could be added in the following format: `"ext.packaging.carvel.dev/fetch-1-secret-name": "simple-app-additional-secret"`.

To use this annotation with a PackageInstall, associated secrets will need to be located in the namespace where the PackageInstall
is created and be in the format described in the [fetch docs](config.md#image-authentication).
