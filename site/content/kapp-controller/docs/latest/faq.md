---
title: FAQ
---

## App CR

This section covers questions for users directly using the [App](app-spec.md)
custom resource.

### How can I control App CR reconciliation (pause, force, adjust frequency...)?

You can set and unset spec.paused
([example](https://github.com/vmware-tanzu/carvel-kapp-controller/blob/d94984a77fa907ac5ecc681e9a842b9877766a6b/test/e2e/pause_test.go#L91))
or fiddle with spec.syncPeriod ([example](
https://github.com/vmware-tanzu/carvel-kapp-controller/blob/d94984a77fa907ac5ecc681e9a842b9877766a6b/test/e2e/app_secret_configmap_reconcile_test.go#L133)), which
defaults to 30 seconds.

### How can I tell which version of kapp-controller is installed?

kapp-controller sets the annotation `kapp-controller.carvel.dev/version` on the deployment to the version deployed,
so e.g. `kubectl describe deployment kapp-controller -n kapp-controller | grep version` will show the installed version.

## Package Management CRs

This section covers questions for users directly using the [Package Management CRs](packaging.md)
custom resource.

### How does kapp-controller handle PackageInstall when a PackageRepository is removed from the cluster?

If a PackageInstall has been installed successfully from a Package that is part
of a PackageRepository, and if that PacakgeRepository is ever deleted after the
successful install, the PackageInstall will eventually report the following
error: `Reconcile failed: Expected to find at least one version, but did not`.
This error occurs due to the regular syncing of a PackageInstall  with its
Package.

Even though the error above is reported, the Package will still be installed and
should work as expected. It can also still be uninstalled by deleting the
PackageInstall. The PackageRepository can be recreated and the PackageInstall
will sync and reconcile without any updates needed to resolve the error.
