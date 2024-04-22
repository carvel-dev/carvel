---
aliases: [/imgpkg/docs/latest/working-directly-with-images]
title: Working directly with images
---

In rare cases imgpkg's [bundle](resources.md#bundle) concept is not wanted (or necessary). imgpkg provides a `--image` flag for push, pull and copy commands. When the `--image` flag is used, there is no need for a `.imgpkg` directory to store metadata.

For most use cases, we suggest using the bundle concept and `--bundle` flag.
