---
title: "How it works"
---

## Overview

Let's look at how `ytt` works. At a high level, it's a pipeline in four steps.

## The Pipeline

When you invoke `ytt` ...

```console
$ ytt -f (input files)
```

it looks something like this:

![ytt pipeline overview](/images/ytt/ytt-pipeline-overview.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457357774380591&cot=14 --> 

where ...
- each "input file" can have one or more YAML documents in them (separated by `---`). \
  _(from here on out, we'll refer to YAML documents as just "documents".)_
- if a document contains one or more `ytt` annotations (i.e. lines that start with `#@`), it's called a "template".
  ```yaml
  # No annotations to be seen; just a plain old YAML document, here.
  ---
  foo: 14
  bar:
  - Hello, Alice
  - Hello, Bob
  - Hello, world
  ```
  vs.
  ```yaml
  #! This is a ytt template.
  
  ---
  foo: 14
  bar:
  #@ for/end name in ["Alice", "Bob", "world"]:
  - #@ "Hello, " + name
  ```
- when a template starts with the [`@data/values`](ytt-data-values.md#declaring-and-using-data-values) annotation, it's called a "Data Values":
  ```yaml
  #@data/values
  ---
  instances: 8
  ...
  ```
- when a template _starts_ with the [`@overlay/match...`](lang-ref-ytt-overlay.md#overlays-as-files) annotation (i.e. above the `---`), it's referred to as an "overlay":
  ```yaml
  #@overlay/match by=overlay.all
  ---
  metadata:
    #@overlay/match missing_ok=True
    namespace: staging
  ...
  ``` 
  _(the details here are unimportant, just know this is an example of an overlay)_
  
- the remaining templates (i.e. _without_ either of those annotations at the top of the document) are known as "the Templates" (capital 'T'). These are the files that, when evaluated, results in the output of the pipeline: the desired YAML files you expect to come out.
  ```yaml
  #@ load("@ytt:data", "data")
  
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: my-app
  spec:
    replicas: #@ data.values.instances
  ... 
  ```
  _(again, the details don't matter, yet; just know this is a "Template")_

Now that we have a sense of each kind of input file, let's explore what happens at each step in the pipeline.

### Step 1: Calculate Data Values

First,

1. from the input files, grab all the "Data Values" templates;
1. evaluate those templates, yielding a list of documents;
1. merge those documents, [in order](ytt-data-values.md#splitting-data-values-into-multiple-files). That is, start with the first document and then overlay the second one onto it; then overlay the third document on top of _that_, and so on...

The result of all this is the final set of values that will be available to other templates: the "final Data Values", [above](#the-pipeline).

### Step 2: Evaluate Templates

Next, evaluate the remaining templates:
1.  "evaluate" means executing all of the Starlark code: loops are run, conditionals decided, expressions evaluated.
1.  one notable exception are the overlay annotations (i.e. those that start with `@overlay/...`), these are deferred until the next step.
1.  a template accesses input variables (i.e. the Data Values calculated in the previous step) via the [`@ytt:data` module](lang-ref-ytt.md#data);
    
The result of all this evaluation is a set of YAML documents, customized by the inputs (shown as "Evaluated DocSet" in the diagram, [above](#the-pipeline)).

### Step 3: Apply Overlays

Next...

1. split the "Evaluated Document Set" into two groups:
    - "Overlay Documents" — documents annotated with [`@overlay/match...`](lang-ref-ytt-overlay.md#overlays-as-files)
    - "Template Documents" — the remaining documents (remember, these are what will ultimately be the output of this pipeline)
1. apply each "Overlay Document" on top of the set of "Template Documents".\
   You can think of each overlay as like a SQL `update` command:
   - the value of it's `by` argument is like a `where` clause that selects over the whole collection of "Template Documents". For example, 
     ```yaml
     #@overlay/match by=overlay.subset({"kind": "Deployment"}), ...
     ---
     ```
      selects all of the documents which contain a key `"kind"` whose value is `"Deployment"`
   - for each of the documents selected, apply the overlay on top of it. This is like a series of `set` clauses, each updating a portion of the document. For example,
     ```yaml
     #@overlay/match by=overlay.subset({"kind": "Deployment"}), ...
     ---
     #@overlay/match-child-defaults missing_ok=True
     metadata:
       labels:
         app: frontend
     ```
     sets each "Deployment"'s `metadata.labels.app` to be `"frontend"`.
1. repeat that process for each "Overlay Document", [in order](lang-ref-ytt-overlay.md#overlay-order).
   
The result is (shown as "Output DocSet" in the diagram, [above](#the-pipeline)) — the finalized set of YAML documents, in memory. Which leaves one last step...

### Step 4: Print

This is simply iterating over the "Output Document Set", rendering each YAML Document ("Output Files", [above](#the-pipeline)).

The result is sent to standard out (suitable for piping into other tools). If desired the output can be sent instead to disk using the [`--output...` flags](outputs.md).

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
