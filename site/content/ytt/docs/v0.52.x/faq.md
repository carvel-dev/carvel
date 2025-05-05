---
aliases: [/ytt/docs/latest/faq]
title: FAQ
---

## Data Values

[Data values doc](ytt-data-values.md)

## Is it possible to add a new key to my values via the `--data-value` command line argument?
No. As with all data values, those passed through `--data-value` must be overrides, not new values. Instead, overlays are the intended way to provide new keys. 
See the [data values vs overlays doc](data-values-vs-overlays.md) for more information.

## How can I dynamically set or replace map key as a data value in my template?
You can use data.values value as a key in a map by using [Text Templating](ytt-text-templating.md) feature.
That way, you can dynamically set keys in a map using data values.
```yaml
#@yaml/text-templated-strings
(@= data.values.some_key @): some-value
```
Additionally, see this [playground example](/ytt/#example:example-text-template) which illustrates the use of text templating to set key of a map item.


## How do I load json for use as a data value?
An important note here is that json is valid yaml. yaml syntax is a superset of json syntax.\
ytt can naturally parse json by passing it through `--data-value-yaml`, or json can be loaded by passing the file as a `--data-value-file`.

Additional resources: [json is valid yaml](https://gist.github.com/pivotaljohn/debe4596df5b4158c7c09f6f1841dd47), [loading by file](https://gist.github.com/pivotaljohn/d3468c3239f79fea7e232751757e779a)

## How do I check if a key is set?
You can check for the existence of a key by using `hasattr`.\
For example, to check if struct `foo` has attribute `bar`, use `hasattr(foo, "bar")`.

## How do I provide a default for a data value when it may not be defined?
When a value may be null, you can use `or` to specify a default.
```yaml
#@ data.values.foo or "bar"
```

## How do I error if a data value is not provided?

ytt library's `assert` package is useful for such situations. It can be used like so:

```yaml
password: #@ data.values.env.mysql_password if data.values.env.mysql_password else assert.fail("missing env.mysql_password")
```

or even more compactly,

```yaml
password: #@ data.values.env.mysql_password or assert.fail("missing env.mysql_password")
```

Note that empty strings are falsy in Starlark.

---

## Overlays

[Overlays doc](lang-ref-ytt-overlay.md)

## How do I remove a document subset?

`#@overlay/remove` in conjunction with `#@overlay/match by=overlay.subset()` annotations are useful for removing a subset of a document.

Additional resources: [overlay remove docs](lang-ref-ytt-overlay.md#overlayremove), [overlay subset docs](lang-ref-ytt-overlay.md#overlaysubset)

## How do I add items to an existing array?  

Using v0.32.0 or later, the default behavior of overlays is to append array items. Simply put your array item in an overlay. 

Prior to v0.32.0, To add an item, either provide the matching annotation (eg. `#@overlay/match by="field_name"`), or use the `#@overlay/append` annotation to add to the end of the list. Note that the append annotation must be applied to each item you want to insert.

Additional resources: [overlay append docs](lang-ref-ytt-overlay.md#overlayappend), [example gist on playground](/ytt/#gist:https://gist.github.com/pivotaljohn/8c7f48e183158ce12107f576eeab937c), [replace-list gist](/ytt/#gist:https://gist.github.com/pivotaljohn/2b3a9b3367137079195971e1409d539e), [edit-list gist](/ytt/#gist:https://gist.github.com/pivotaljohn/217e8232dc080bb764bfd064ffa9c115)

## Why am I getting an exception when trying to append to an array?

A common append issue is incorrectly setting the `#@overlay/match missing_ok=True` annotation on the key which gets replaced by new key-values. Instead, it should be applied to each child (made convenient with the `#@overlay/match-child-defaults missing_ok=True` annotation). See this [illustrative gist](https://gist.github.com/cppforlife/bf42f2d3d23dacf07affcd4150370cb9) for an example.

## How do I rename a key without changing the value?

An `#@overlay/replace` annotation with a lambda `via`. For example, to replace the key `bad_name` with `better_name` while retaining the value, you can use:
```yaml
#@overlay/replace via=lambda a,b: {"better_name": a["bad_name"]}
```
See [this gist](/ytt/#gist:https://gist.github.com/gcheadle-vmware/3c41645a80201caaeefa878e84fff958) for the full example.

## How do I add or replace a value in a dictionary?

A `#@ template.replace()` annotation can be used for these purposes. See [this example](/ytt/#example:example-replace). You can also use overlays to edit a dictionary, an example can be found on [this gist playground](/ytt/#gist:https://gist.github.com/gcheadle-vmware/af8aeb3120386e58922c816d76f47ab6).

## How do I match a field.name that starts with a string?

```yaml
overlay/match by=lambda a,_: a["field"]["name"].startswith("string")
```

## How do I match a struct based on the presence of a key?

To match a dictionary from a list of dictionaries if the `foo` key is present, you can use 
```#@overlay/match by=lambda idx,old,new: "foo" in old, expects="1+"```.

## How do I modify only part of a multi-line string?

An `#@overlay/replace` annotation with a lambda `via` function can modify part of a string. See this [modify-string gist](/ytt/#gist:https://gist.github.com/cppforlife/7633c2ed0560e5c8005e05c8448a74d2) for an example.

## How can I match a regex pattern in the subset matcher?

The subset matcher does not directly support regex patterns. Instead, a custom matcher can be written. See this [playground gist](/ytt/#gist:https://gist.github.com/ewrenn8/3409e44252f93497a9b447900f3fb5b7) for an example.

---

## When should I include a space in my ytt comment? Does it matter? Is it `#@load` or `#@ load`? `#@overlay/match` or `#@ overlay/match`
The space is subtly meaningful, and directly, load needs a space, while overlay/match does not – but why?

ytt wraps two concepts in its comment syntax:
1. Annotations on a node
1. Directives for ytt

Annotations do not have a space, and they refer to a given node in the tree. These comments attach metadata to the annotated node, which can be used during templating.
Some examples of annotations are:
- When inserting a node via an [overlay](#ytt-overlays.md), we would annotate that node with `#@overlay/insert`.
- When we want to mark a document as containing [data values](#ytt-data-values.md), we annotate the document start marker with `#@data/values`.

Directives, on the other hand, do include a space, and are used to _direct_ ytt to execute the arguments.
Some examples of directives are:
- [Loading](#lang-ref-load.md) a library, we add the `#@ load` directive to the doc, unattached to any particular node.
- To begin and end a [for loop](#lang-ref-for.md) or [conditional](lang-ref-if.md), we use the `#@ for`, `#@ if`, and `#@ end` directives.

For further exploration, investigate what happens when you move an annotation comment and compare it with moving a directive comment!

## Why is `ytt` complaining about "Unknown comment syntax"; can't I write standard YAML comments (#)? 

You can, but it is discouraged to avoid tricky errors that can go unchecked.

The recommended approach is when writing `ytt` templated files, use `ytt` comments:

```
#! this is a ytt comment; it's like she-bang!
```

If for some reason you need to disable this "linting" check (e.g. you're gradually migrating an existing YAML file to become a `ytt` template and it's onerous to convert all those comments at once), include the `--ignore-unknown-comments` flag.

For a detailed explanation of how `ytt` detects and processes YAML files, see [File Marks > type detection for YAML files](file-marks.md#type-detection-for-yaml-files).


## Why is my anchor reference null despite my anchor's successful template?

This is a [known limitation](known-limitations.md) of ytt.

## Can I generate random strings with ytt?
No. A design goal of ytt is determinism, which keeps randomness out of scope.

If you want to generate secrets, see the [injecting secrets doc](injecting-secrets.md) or the [kubernetes secretgen-controller](https://github.com/carvel-dev/secretgen-controller)

## Can I load multiple functions without having to name each one?

Yes! Functions can be stored in a struct which can be imported all together. You can then call individual functions from within that struct. Note that because Starlark does not provide forward references, you must declare the struct that collects the functions to export at the end of the file.

Storing functions in struct:

```yaml
#@ load("@ytt:struct", "struct")
#@ mod = struct.make(func1=func1, func2=func2)
```

Loading and calling functions in template:

```yaml
#@ load("helpers.lib.yml", "mod")
something: #@ mod.func1()
```

Additional resources: [Load Statement doc](lang-ref-load.md)

## How do I inject secrets?
See the [injecting secrets doc](injecting-secrets.md).

## How do I template values within text?
See the [text templating doc](ytt-text-templating.md). Additionally, see this [playground example](/ytt/#example:example-text-template) which illustrates some ways text templating can be done.

## How can I use files that are symlinks?
ytt takes a secure by default approach to symlinks. It disables use of symlinks to avoid [the risk](security.md#attack-vectors) of malicious template code loading symlinked file contents from sensitive locations.

If you would like to override this behavior, use `--allow-symlink-destination` flag for allowing symlinks in specific directories or files, or `--dangerous-allow-all-symlink-destinations` to allow all symlinks.

## What templating language does ytt use?

ytt uses a fork of [Starlark](https://github.com/bazelbuild/starlark), with a few changes. See the [Language reference](lang.md#Language) for more information.
