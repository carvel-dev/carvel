---
title: FAQ
---

This documentation covers frequently asked questions for kapp-controller. It is
divided into three sections: [App Developer](#app-developer), [Package
Author](#package-author), and [Package Consumer](#package-consumer).  This is
done to organize questions based on how users are working with kapp-controller.

## App Developer

This section covers questions for users directly using the [App](app-spec.md)
custom resource.

### How can I control App CR reconciliation (pause, force, adjust frequency...)?

You can set and unset spec.paused
([example](https://github.com/vmware-tanzu/carvel-kapp-controller/blob/d94984a77fa907ac5ecc681e9a842b9877766a6b/test/e2e/pause_test.go#L91))
or fiddle with spec.syncPeriod ([example](
https://github.com/vmware-tanzu/carvel-kapp-controller/blob/d94984a77fa907ac5ecc681e9a842b9877766a6b/test/e2e/app_secret_configmap_reconcile_test.go#L133)), which
defaults to 30 seconds.


## Package Author

This section covers questions for users packaging software for Kubernetes.

None available at this time.

## Package Consumer

This section covers questions for users installing software packages for
Kubernetes.

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
