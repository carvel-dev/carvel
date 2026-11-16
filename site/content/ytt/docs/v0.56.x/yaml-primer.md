---
aliases: [/ytt/docs/latest/yaml-primer]
title: "YAML and Annotations"
---

## Overview

Templates in `ytt` — rather than being YAML-like text files with templating injected _in_ — are well-formed YAML files with templating annotated _on_.

It's reasonable to have expectations of how to write templates, especially if we have prior experience. But in the shift from a free-form text file to a structured YAML document set, some of those expectations are foiled. And when they are, it can be rather frustrating.

If we take a few minutes to cover:

- [what YAML is](#what-is-yaml) — its format and constituent parts; and 
- [how to annotate YAML in `ytt`](#annotating-yaml),
  
it can mitigate much of that frustration.

## What is YAML?

YAML is a tree of nodes. Each node is of one of these six types:

- a **Document Set** (which is list of **Documents**)
- a **Map** that has **Map Items**
- an **Array** that has **Array Items**

We'll start from the top of the tree...

### Documents and Document Sets

A file containing text in YAML format is parsed into a **Document Set**: a collection of **Document**s.

![a file containing two YAML documents](/images/ytt/yaml-primer/two-docs.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 1: A file, parsed into a **document set** (dotted blue) containing two **documents** (solid blue)._

Note: `---` marks the start of a new document.

The corresponding tree of nodes looks something like this:

![](/images/ytt/yaml-primer/two-docs-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 2: Corresponding tree: this document set has two documents._

A given document has exactly one (1) value. It is usually either:
- a **Map**,
- an **Array**, or
- a **Scalar**

We'll look at each of these, in turn. Maps are most common...

### Maps and Map Items

A "map" is collection of key-value pairs. Each pair is referred to as a "map item".

![](/images/ytt/yaml-primer/two-maps-and-items.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 3: Each document has a **map** (dotted green) each containing two **map items** (solid green)._

The complete tree of nodes looks like this:

![](/images/ytt/yaml-primer/two-maps-and-items-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 4: Corresponding tree: each document has a map for its value; each map has two items._

Let's zoom in on the first document, and explicitly reveal the contents of a map item: 

![](/images/ytt/yaml-primer/map-items-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 5: Each map item has a **key** and a **value**; here, both map items' key is a string and their value is an integer._

Like documents, a map item has exactly one (1) value. And just like documents, it's either:
- a **Map**,
- an **Array**, or
- a **Scalar**

Let's see what it looks like for a **map item** to have a **map**, itself.

![](/images/ytt/yaml-primer/map-item-has-map-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 6: The document's value is a map with two map items; the second map item has a key of "metadata" and a value that is another map._


### Arrays and Array Items

An "array" is a list of "array items" (zero-indexed).

Like documents (and map items), an array item has exactly one (1) value. Once more, it's either:
- a **Map**
- an **Array**, or
- a **Scalar**

![](/images/ytt/yaml-primer/map-item-has-array-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 7: The **map item** "foo" has an **array** (dotted gold) for a value; that array has three **array items** (solid gold)._

Let's see what it looks like when an **array item**'s value is a **map**...

![](/images/ytt/yaml-primer/array-item-has-map-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 8: "foo" has an **array** with one **array item** whose value is a **map** containing two **map item**s: `name` and `factor`._

We've seen scalars in use above. Let's cover them explicitly.

### Scalars

A "scalar" is a fundamental value. YAML supports:
- integers (e.g. 13, 42, 137, 32767)
- floating point numbers (e.g. 1.0, 3.14, 137.03599913)
- strings (e.g. "", "fine structure", "$ecr3t")
- boolean values: `true` or `false`
- `null` (when a value is omitted, that implies `null`; `~` == `null`)

### Summary

In short:

- a YAML file is parsed into a **Document Set** which is merely a list of **Document**s.
- a given **Document** has one _value_.
- Both **Map**s and **Array**s are nothing more than collections of items.
  - a **Map Item** has a _key_ and a _value_
  - an **Array Item** has a _value_
- a _value_ (whether held by a document, map item, or array item) is either a **Map**, an **Array**, or a **Scalar**.

With this structure in mind, we can now look into how `ytt` annotates it.

## Annotating YAML

A `ytt` "annotation" is a YAML comment of a specific format; it attaches behavior to a node.

For example:

![](/images/ytt/yaml-primer/map-item-with-value.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 9: A YAML file with a `ytt` annotation._

Can be understood to mean that the value of `foo` is the result of evaluating the expression `13 + 23 + 6`.

The diagram reveals how the annotation is attached to the YAML tree:

![](/images/ytt/yaml-primer/map-item-ann-with-value-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 10: The annotation (dotted black) is attached to the **map item** (solid green)._

This is a document, whose value is a map, that contains a single map item. To the right of the map item is an annotation that contains an expression that, when evaluated, becomes a _value_. The annotation is attached to the map item.

### How an Annotation Finds its Node

When attaching annotations, `ytt` follows these two rules (in order):
1. the annotation is attached to the value-holding node **on its left**, if there is one; otherwise,
2. the annotation is attached to the value-holding node **directly below** it.

In the example above, the value-holding node to the left of the annotation is the map item.

As noted in the summary [above](#summary), "value-holding" nodes are:
- **Document**s,
- **Map Item**s, and
- **Array Item**s.

#### Example: Annotating Map Items

Let's see these rules at play:

![](/images/ytt/yaml-primer/overlay-ann-on-doc-and-map.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 11: A templated document with three annotations._

We'll ignore _what_ these annotations mean, for now, and focus on _where_ they attach. There are three annotations in total.

Visualizing the YAML tree can help:

![](/images/ytt/yaml-primer/overlay-ann-on-doc-and-map-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 12: Each annotation attaches to the value-holding node to its left or bottom._

Taking each annotation in turn:
- `@overlay/match by=overlay.all`:
  - is in the document set, but that is not a value-holding node
  - has a **document** node just below it and so is attached to _that_ node.
- `@overlay/replace`:
  - has no node to its left;
  - has a **map** just below it but maps are _not_ value-holding;
  - the next node is a **map item**, and so attaches to _that_ node.
- `@ 13 + 23 + 6`:
  - has a **map item** to its left, and so attaches to _that_ node.
  - there _is_ another **map item** below it (i.e. `bar: true`), but a home has already been found for this annotation.
    
#### Example: Annotating an Array

When an **array item** contains a **map**, it can be tricky to know which item a particular annotation attaches to.

In this example, we reinforce the value of knowing the two rules that determine [how an annotation finds its node](#how-an-annotation-finds-its-node).

![](/images/ytt/yaml-primer/overlay-ann-on-array-and-map.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 13: An overlay ensuring each book has been marked as reviewed. The blank line after the array item is intentional._

There are three annotations in this example. The first one clearly annotates the document. But what about the next two?

Visualizing the layer, it can start to become more clear...

![](/images/ytt/yaml-primer/overlay-ann-on-array-and-map-ast.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14 -->
_Figure 14: The newline after the **array item** ensures the last annotation attaches to the **map item**._

Taking each annotation in turn:
- the first `@overlay/match by=overlay.all`:
  - has a **document** node just below it and so is attached to _that_ node.
- the second `@overlay/match by=overlay.all`:
  - has a **map item** (`books:`), but that is _above_ this annotation;
  - `books:` contains an **array**, but arrays are _not_ value-holding nodes;
  - that array's **array item** (denoted by `-`) is just below the annotation and so is attached to _that_ node. 
- finally, `@overlay/match missing_ok=True`:
  - if this _had_ been the same line as the **array item**, it _would_ have also attached to the same node as the previous annotation (but it is not, and is it won't);
  - the next node is a **map**, but again, maps are _not_ value-holding;
  - the next node is a **map item** (`reviewed:`), so the annotation attaches to _that_ node.


## Further Exploration

While we've thoroughly covered the fundamentals here, these concepts only become real with use:

- put your understanding to the test by picking an example from [the Playground](https://carvel.dev/ytt/#example:example-demo) and tweaking it in various ways to see what _actually_ happens.
- take a simple example and run it through `ytt --debug` and study the `### ast` section of the output. Note:
  - in this output, annotations are referred to as `meta`.
  - "AST" is short for "Abstract Syntax Tree" which is the technical name for the trees we've been visualizing in this guide.
  - we recommend making small changes and study how it modifies the "AST"
- if you'd like to obsess over YAML itself, look no further than the [YAML spec](https://yaml.org/spec/1.2/spec.html).
