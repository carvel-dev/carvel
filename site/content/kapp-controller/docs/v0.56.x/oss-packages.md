---
aliases: [/kapp-controller/docs/latest/oss-packages]
title: OSS Carvel Packages
---

This page provides a list of Carvel Packages and Package Repositories that are available to open source users. 

Do you have a Package or Package Repository you'd like to add to this list? Please make a PR with details to our [docs](https://github.com/carvel-dev/carvel/blob/develop/site/content/kapp-controller/docs/develop/oss-packages.md).

## kapp-controller package
kapp-controller can itself be installed as a package, this is sometimes useful to bootstrap other clusters by installing kapp-controller package from a management cluster where kapp-controller is already installed. The package can be found in the release artifacts of kapp-controller [releases](https://github.com/carvel-dev/kapp-controller/releases).

## secretgen-controller package
Similar to kapp-controller, secretgen-controller can also be installed via a package and it can be found in the release artifacts of secretgen-controller [releases](https://github.com/carvel-dev/secretgen-controller/releases). These packages are created via kctrl's package authoring commands.
