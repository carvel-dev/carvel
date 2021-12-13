---
title: Package Command
---

## Overview
Package command provides options to interact with package repositories, available packages and package installs.

## package available
`package available` can be used to get or list packages available in a namespace or all namespaces.

### package available list
`package available list` can be used to get a list of packages available in one or all namespaces.

Example:
```bash
$ kctrl package available list
Target cluster 'https://192.168.64.53:8443' (nodes: minikube)

Available summarized packages in namespace 'default'

Name                 Display name  
test-pkg.carvel.dev  Carvel Test Package  

Succeeded

```
