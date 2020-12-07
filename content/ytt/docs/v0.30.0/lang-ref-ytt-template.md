---
title: Template Module
---

## `@template` Functions

The `@ytt:template` module provides a function that can be used to update templates.

To use these functions, include the `@ytt:template` module:

```python
#@ load("@ytt:template", "template")
```

The functions exported by this module are:
- [template.replace()](#templatereplace)

### template.replace()
Replace existing yaml node with
  yaml nodes provided or returned from a function call


**Examples:**

Add new map items to the `labels` map
```yaml
#@ load("@ytt:template", "template")

labels:
  another-label: true
  key-will-disapear: #@ template.replace({"key3": "value3"})
```


Use a function instead of explicitly providing the map items
```yaml
#@ load("@ytt:template", "template")

labels:
  another-label: true
  _: #@ template.replace(my_labels())
```


See also [replace example](https://carvel.dev/ytt/#example:example-replace) in the ytt Playground.
