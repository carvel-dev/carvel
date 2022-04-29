---
aliases: [/kapp-controller/docs/latest/package-install-extensions]
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

Example secret resource with a ytt overlay that adds a label to all Namespaces added by this package:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-overlay-secret
  namespace: my-ns
stringData:
  add-ns-label.yml: |
    #@ load("@ytt:overlay", "overlay")
    #@overlay/match by=overlay.subset({"kind":"Namespace"}),expects="1+"
    ---
    metadata:
      #@overlay/match missing_ok=True
      labels:
        #@overlay/match missing_ok=True
        custom-lbl: custom-lbl-value
```

