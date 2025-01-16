---
aliases: [/vendir/docs/latest/]
title: "About vendir"
toc: "false"
cascade:
  version: v0.43.x
  toc: "true"
  type: docs
  layout: docs
---

vendir allows to declaratively state what should be in a directory. It was designed to easily manage libraries for [ytt](/ytt); however, it is a generic tool and does not care how files within managed directories are used.

Supported sources for fetching:

- git
- hg (Mercurial)
- http
- image (image from OCI registry)
- imgpkgBundle (bundle from OCI registry)
- githubRelease
- helmChart
- directory

Examples could be found in [carvel-vendir's `examples/` directory](https://github.com/carvel-dev/vendir/tree/develop/examples).
