---
title: OSS Carvel Packages
---

This page provides a list of Carvel Packages and Package Repositories that are available to open source users. 

Do you have a Package or Package Repository you'd like to add to this list? Please make a PR with details to our [docs](https://github.com/carvel-dev/carvelmain/site/content/kapp-controller/docs/latest/oss-packages.md).

## Tanzu Community Edition
Tanzu Community Edition provides several open source [Carvel Packages](https://tanzucommunityedition.io/packages/). These are actively contributed to and maintained by contributors to Tanzu Community Edition. A list of the Package CRs can be found [here](https://github.com/vmware-tanzu/community-edition/tree/main/addons/packages). You can add the Package Repository to your cluster by creating a PackageRepository CR.

```yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: tce-repo
spec:
  fetch:
    imgpkgBundle:
      # Check out the latest version from Tanzu Community Edition docs
      image: projects.registry.vmware.com/tce/main:0.9.1
```