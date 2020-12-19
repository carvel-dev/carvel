---
title: "About vendir"
toc: "false"
cascade:
  version: latest
  toc: "true"
  type: docs
  layout: docs
---

vendir allows to declaratively state what should be in a directory. It was designed to easily manage libraries for [ytt](https://get-ytt.io); however, it is a generic tool and does not care how files within managed directories are used.

Supported sources for fetching:

- git
- http
- image (image from OCI registry)
- githubRelease
- helmChart
- directory

Examples could be found in [carvel-vendir's `examples/` directory](https://github.com/vmware-tanzu/carvel-vendir/tree/develop/examples).
