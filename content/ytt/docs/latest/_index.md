---
title: "About ytt"
toc: "false"
cascade:
  version: latest
  toc: "true"
  type: docs
  layout: docs
---

`ytt` is a templating tool that understands YAML structure. It helps to easily configure complex software via reusable templates and user provided values.

A comparison to similar tools can be found in the [ytt vs X doc](ytt-vs-x.md).

## Templating

`ytt` performs templating by accepting "templates" (which are annotated YAML files) and "data values" 
(also annotated YAML files) and rendering those templates with the given values. 

For more:
* see it in action in the [load data files](/ytt/#example:example-load-data-values) 
example on the playground
* check out the [Using Data Values](how-to-use-data-values.md) guide

## Patching

`ytt` can also be used to patch YAML files. It does this by accepting overlay files (also in YAML) which describe
edits. This allows for configuring values beyond what was exposed as data values. 

For more:
* navigate to the [overlay files](/ytt/#example:example-overlay-files)
example on the playground
* take a look at the [ytt Overlays overview](ytt-overlays.md)

## Go Deeper

- For a more detailed look, see [How it Works](how-it-works.md).

## Further Reading

### Blog posts

- [ytt: The YAML Templating Tool that simplifies complex configuration management](https://developer.ibm.com/blogs/yaml-templating-tool-to-simplify-complex-configuration-management/)
- [Deploying Kubernetes Applications with ytt, kbld, and kapp](/blog/deploying-apps-with-ytt-kbld-kapp)

### Talks

- [Introducing the YAML Templating Tool (ytt)](https://www.youtube.com/watch?v=KbB5tI_g3bo) on IBM Developer podcast
- [YTT and Kapp @ TGI Kubernetes 079](https://www.youtube.com/watch?v=CSglwNTQiYg) with Joe Beda
- [ytt: An Alternative to Text Templating of YAML Configuration @ Helm Summit 2019](https://www.youtube.com/watch?v=7-PqgpkxC7E)
  - [presentation slides](https://github.com/k14s/meetups/blob/develop/ytt-2019-sep-helm-summit.pdf)
- [Managing Applications in Production: Helm vs ytt & kapp @ Kubecon 2020](https://www.youtube.com/watch?v=WJw1MDFMVuk)
- [Introduction to Carvel @ Rawkode Live](https://www.youtube.com/watch?v=LBCmMTofNxw)
