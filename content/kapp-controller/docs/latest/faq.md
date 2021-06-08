---
title: FAQ
---

This documentation covers frequently asked questions for kapp-controller. It is divided into two sections: 
[Package Author](#package-author) and [Package Consumer](#package-consumer). This is done to organize questions 
based on how users are working with kapp-controller.

## Package Author

None available at this time.

## Package Consumer

### How does kapp-controller handle InstalledPackages when a PackageRepository is removed from the cluster?

If an InstalledPackage has been installed successfully from a Package/PackageVersion that are part of a PackageRepository and if 
that PacakgeRepository is ever deleted after the successful install, the InstalledPackage will eventually report the following error: 
`Reconcile failed: Expected to find at least one version, but did not`. This error occurs due to how InstalledPackages regularly 
syncs with its Package/PackageVersion to pick up changes that have occurred so the latest changes are always deployed.

Even though the error above is reported, the Package/PackageVersion will still be installed and should work as expected. It can also 
still be uninstalled by deleting the InstalledPackage. The PackageRepository can be recreated and the InstalledPackage will sync and 
reconcile without any updates needed to resolve the error.
