---
title: Overlays with PackageInstall
---

PackageInstalls expose the ability to customize package installation using
annotations recognized by kapp-controller.

## Adding Paths to YTT (overlays)

Since it is impossible for package configuration and exposed data values to meet
every consumer's use case, we have added an annotation which enables
consumers to extend the package configuration with custom ytt paths. The most
likely use case for this is providing overlays to tweak configuration that is
not exposed via data values, but it can be used to provide any kind of ytt file.

The extension annotation is called `ext.packaging.carvel.dev/ytt-paths-from-secret-name`
and can be suffixed with a `.X`, where X is some number, to allow for specifying
it multiple times. For example,

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: fluent-bit
  namespace: my-ns
  annotations:
    ext.packaging.carvel.dev/ytt-paths-from-secret-name.0: my-overlay-secret
spec:
  serviceAccountName: fluent-bit-sa
  packageRef:
    refName: fluent-bit.vmware.com
    versionSelection:
      constraints: ">v1.5.3"
      prereleases: {}
  values:
  - secretRef:
      name: fluent-bit-values

```

will include the overlay stored in the secret `my-overlay-secret` during the
templating steps of the package. This will allow users to further customize a
package installation in advanced cases.

## Using Data Values Overlays

Since kapp-controller exposes a consistent interface to specify data values
for a package, which might use helm or ytt, it requires all data values
secrets to contain plain yaml, that is, not to contain any ytt annotations. This
restricts that abilities of consumers since they are no longer able to use some
features exposed via data values overlays when specifying values for packages.
To address this, we have added the
`ext.packaging.carvel.dev/ytt-data-values-overlays` extension annotation. This annotation
tells kapp-controller to provide the data from the secret as data values
overlays, which are able to contain ytt annotations, instead of data values
files, which are not. Check out the [docs on data value overlays](/ytt/docs/latest/ytt-data-values/#configuring-data-values-via-data-values-overlays) to learn more.

For example, if a consumer would like to use a secret that contains a ytt
annotation, like the following,

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: fluent-bit-values
stringData:
  values.yml: |
    #@data/values
    ---
    ...
```

they would also need to add the extension annotation to their package install, like so,

```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: fluent-bit
  namespace: my-ns
  annotations:
    ext.packaging.carvel.dev/ytt-data-values-overlays: ""
spec:
  serviceAccountName: fluent-bit-sa
  packageRef:
    refName: fluent-bit.vmware.com
    versionSelection:
      constraints: ">v1.5.3"
      prereleases: {}
  values:
  - secretRef:
      name: fluent-bit-values
```
