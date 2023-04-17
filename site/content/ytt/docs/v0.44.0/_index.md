---
aliases: [/ytt/docs/latest/]
title: "About ytt"
cascade:
  version: v0.44.0
  toc: "true"
  type: docs
  layout: docs
---

## Overview

`ytt` is a command-line tool used to template and patch YAML files. It also provides the means to collect fragments and piles of YAML into modular chunks for easy re-use.

In practice, these YAML files are [Kubernetes configuration](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/), [Concourse Pipeline](https://concourse-ci.org/pipelines.html#schema.pipeline), [Docker Compose](https://github.com/compose-spec/compose-spec/blob/master/spec.md#compose-file), [GitHub Action workflow](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions) files..., really anything that is in YAML format.

`ytt` is most useful when manually maintaining these files has or will become too much work.

## Templating

A plain YAML file is turned into a `ytt` template by adding specially formatted comments, that is: annotating. Through these annotations, one can inject input values, logic like conditionals and looping, and perform transformations on the content.

Those "input values" are called "Data Values" in `ytt`. Such inputs are included in a separate file.

For more:
* see it in action in the [load data files](/ytt/#example:example-load-data-values) 
example on the playground
* check out the [Using Data Values](how-to-use-data-values.md) guide
- look up reference details of the programming language used in templates in [Language](lang.md).

## Patching (aka Overlaying)

`ytt` can also be used to patch YAML files. These edits are called "Overlays" and are themselves written in YAML.

For more around overlaying...
- see overlaying in action through a progressive set of examples in [the `ytt` Playground](/ytt/#example:example-match-all-docs);
- learn more about Overlays in [ytt Overlays overview](ytt-overlays.md);
- for a reference of all Overlay functionality, see [Overlay module](lang-ref-ytt-overlay.md);
- for a screencast-formatted in-depth introduction to writing and using overlays, watch [Primer on `ytt` Overlays](/blog/primer-on-ytt-overlays/).

## Modularizing

`ytt` provides powerful techniques for extracting and reusing chunks of YAML and logic.

Functions in `ytt` capture either a calculation or fragment of YAML. Functions can be used in the same templates that define them, or — if defined in a module file — loaded into any template. Entire sets of templates, overlays, and library code can be encapsulated in a `ytt` library.

For more about modular code...
- see live examples in the `ytt` Playground around [functions](ytt/#example:example-function) and [`ytt` libraries](/ytt/#example:example-ytt-library-module);
- read further about [functions](lang-ref-def.md), [YAML Fragments](lang-ref-yaml-fragment.md), and [loading reusable modules and libraries](lang-ref-load.md);
- catch-up on a particularly relevant [discussion about using modules and libraries in `ytt`](https://github.com/carvel-dev/ytt/discussions/392#discussioncomment-766445).

## Further Reading

Hopefully, the pointers above helped get you started. If you're looking to go either deeper or broader, here are some resources we can recommend.

### Documentation

- [How it Works](how-it-works.md) \
  _a more detailed look of how all these parts fit together._
  
- [ytt vs. X](ytt-vs-x.md) \
  _how `ytt` differs from similar tools._

### Articles

- [ytt: The YAML Templating Tool that simplifies complex configuration management](https://developer.ibm.com/blogs/yaml-templating-tool-to-simplify-complex-configuration-management/) \
  _a complete introduction of `ytt` including motivations and contrasts with other tools._
  
- [Deploying Kubernetes Applications with ytt, kbld, and kapp](/blog/deploying-apps-with-ytt-kbld-kapp) \
  _how `ytt` works well with other Carvel tools._

### Presentations and Interviews

- IBM Developer podcast: [Introducing the YAML Templating Tool (ytt)](https://www.youtube.com/watch?v=KbB5tI_g3bo) \
  _a thorough introduction to `ytt` especially contrasted with Helm._
  
- TGI Kubernetes: [#079: YTT and Kapp](https://www.youtube.com/watch?v=CSglwNTQiYg) \
  _Joe Beda puts both `ytt` and sister tool `kapp` through their paces._
  
- Helm Summit 2019: [ytt: An Alternative to Text Templating of YAML Configuration in Helm](https://www.youtube.com/watch?v=7-PqgpkxC7E)
  ([slides](https://github.com/k14s/meetups/blob/develop/ytt-2019-sep-helm-summit.pdf)) \
  _in-depth review of the philosophy behind `ytt` and how it differs from other YAML templating approaches._
  
- Kubecon 2020: [Managing Applications in Production: Helm vs ytt & kapp @ Kubecon 2020](https://www.youtube.com/watch?v=WJw1MDFMVuk) \
  _how `ytt` and `kapp` can provide an alternative way to manage the lifecycle of application on Kubernetes._
  
- Rawkode Live: [Introduction to Carvel](https://www.youtube.com/watch?v=LBCmMTofNxw) \
  _Dmitriy joins David McKay to talk through many tools in the Carvel suite, including `ytt`._
