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
Replaces the existing yaml node with the yaml node(s) provided or returned from a function call, of the same type.
Underscore (`_`) is the conventional replacement key, though any key can be used.

```
template.replace(node)
```

* `node` ([`yamlfragment`](lang-ref-yaml-fragment.md)) — yaml fragment that will replace the existing node

**Examples:**

##### Add a new item to the `labels` mapping
```yaml
#@ load("@ytt:template", "template")

labels:
  another-label: true
  _: #@ template.replace({"key2": "value2"})
```
results in:
```yaml
labels:
  another-label: true
  key2: value2
```

Notice that the argument to the function entirely replaces the `_` map item.

##### Use a function instead of providing the item(s) inline
```yaml
#@ load("@ytt:template", "template")

#@ def my_labels():
#@   return {"key2": "value2"}
#@ end

labels:
  another-label: true
  key-will-disappear: #@ template.replace(my_labels())
```
results in:
```yaml
labels:
  another-label: true
  key2: value2
```

Notice that the argument to the `replace` function entirely replaces the `key-will-disappear` map item.

So, regardless of the node's key or value, `template.replace` will overwrite it with the argument provided.

See also: [Replace example](/ytt/#example:example-replace) in the ytt Playground.
