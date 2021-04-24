---
title: "How it works"
---

## Overview

Having a picture of how your inputs are processed in `ytt` can be helpful.

## The Pipeline

When you invoke `ytt`, 

```console
$ ytt -f (input files)
```

it looks something like this:

![ytt pipeline overview](/images/ytt/ytt-pipeline-overview.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457357774380591&cot=14 --> 

Where:
- each file can have one or more YAML documents in them (separated by `---`). \
  _(from here on out, we'll refer to YAML documents as just "documents".)_
- within a document, there are (usually) annotations and/or code. `ytt` refers to these kinds of documents as "templates".
- when a template is annotated with [`@data/values`](ytt-data-values.md#declaring-and-using-data-values), we call them "Data Values":
  ```yaml
  #@data/values
  ---
  ...
  ```
- when a template is annotated with [`@overlay/match...`](lang-ref-ytt-overlay.md#overlays-as-files), we refer to those as "Overlays":
  ```yaml
  #@overlay/match by=...
  ---
  ...
  ``` 
- the remaining templates (i.e. those without an annotation at the top of the document) are the primary objects of the pipeline; here we will call them simply "the Templates". The result of the Templates is the output of the pipeline.

In the description, below,
- "template" is any document with annotations/code, and 
- "the Templates" are the set of templates that just happen to _not_ have any special annotation at the top.

`ytt` processes these various flavors of templates in four (4) steps:

### Step 1: Calculate Data Values

First, determine the data that will be injected in the other templates. In `ytt`, these are called "data values".

1. from all input files, pluck all the "Data Values" templates and evaluate them into documents;
1. using the first evaluated Data Value document as the base, overlay each subsequent document, [in order](ytt-data-values.md#splitting-data-values-into-multiple-files) — merging all of them into a single YAML Document: the "final Data Values".

Explicitly: the data values are fully calculated before `ytt` proceeds to the next step.

### Step 2: Evaluate Templates

Next, evaluate the remaining templates: execution the code in each.

1. evaluate the remaining templates
    - templates access _the_ Data Values via the [`@ytt:data` module](lang-ref-ytt.md#data)`)
    - `@overlay/...` annotations are retained and deferred to the next step
    - all other expressions are evaluated, resulting in a intermediate YAML document
1. the full result is the "Evaluated Document Set" — the set of YAML documents implied by the templates, held in memory.

By the end of this step, all templates have been evaluated.

### Step 3: Apply Overlays

The penultimate step is to apply "Overlays" onto the evaluated "Templates"

1. split the "Evaluated Document Set" into two groups:
    - "Overlay Documents" — documents annotated with [`@overlay/match...`](lang-ref-ytt-overlay.md#overlays-as-files)
    - "Template Documents" — the remaining documents
1. apply each Overlay on top of the "Template Documents", [in order](lang-ref-ytt-overlay.md#overlay-order).
1. the result is the "Output Document Set" — the finalized set of YAML documents, in memory.

### Step 4: Print
- iterate over the "Output Document Set", rendering each file's set of YAML Documents.

## Further Reading

To learn more about...
- **Data Values**...
  - poke at a working example in the ytt Playground: [Load Data Values](/ytt/#example:example-load-data-values) example
  - read-up on the details in "[Using data values](ytt-data-values.md)"
  - work with a complete example from the source: \
    [vmware-tanzu/carvel-ytt/../examples/data-values](https://github.com/vmware-tanzu/carvel-ytt/tree/develop/examples/data-values)
- **Templates**...
  - learn Starlark by example in the first bunch of ["Basics" examples](/ytt/#example:example-plain-yaml).
  - read-up on [`ytt`'s built-in libraries](lang-ref-ytt.md) to encode/decode, hash, regex match over data.
  - get an helpfully abridged tour of Starlark in "[Language](lang.md)"
- **Overlays**...
  - walk through the "Overlays" group of examples:
    1. go to the [ytt Playground](/ytt/#example:example-match-all-docs)
    2. find the "Overlays" group header, click on it to reveal the group _(you can close the "Basics" group by clicking on it)_.
  - read an introduction at "[Using Overlays](ytt-overlays.md)"
