---

title: "How it works"
---

## Overview

Let's get an idea of how `ytt` works by looking at the high-level concepts and flow.

## The `ytt` Pipeline

When you invoke `ytt` ...

```console
$ ytt -f config/ --data-values-file values/
```

... you can think of it as a pipeline in four stages, looking something like this:

![ytt pipeline overview](/images/ytt/ytt-pipeline-overview.jpg)
<!-- source: https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457361130201021&cot=14 --> 

_(Configuration documents (grey, pale yellow and blue) flow through four pipeline steps (black), into evaluated intermediary documents (bright yellow and blue), and combined ultimately into plain YAML output (green).)_

A quick note about files and documents, in general, followed by a detailed description of the elements in this diagram.

**About YAML files and their documents**

Each YAML file can have one or more YAML documents in them (separated by `---`). _(from here on, we'll refer to YAML documents as just "documents".)_

```yaml
foo: here's the first document (the initial `---` is optional)
---
bar: this is a separate document
---
qux: third document's a charm!
```

If a given "configuration file" contains one or more `ytt` annotations (i.e. lines that contain `#@`), it's a `ytt` template.

This is a `ytt` template...
```yaml
---
foo: 14
bar:
#@ for/end name in ["Alice", "Bob", "world"]:
- #@ "Hello, " + name
```
... and, this is plain YAML ...
```yaml
---
foo: 14
bar:
- Hello, Alice
- Hello, Bob
- Hello, world
```


### Configuration

The top-left section of [the diagram](#the-ytt-pipeline) shows the configuration files: the templated configuration and supporting files.

These files are written and maintained by those who understand how the final result should be shaped. We refer to these folks as Configuration Authors.

Configuration includes a mixture of these kinds of files:

- [Data Values Schema Documents](#data-value-schema-documents)
- [Data Values Documents](#data-values-documents)
- [Plain Documents](#plain-documents)
- [Templated Documents](#templated-documents)
- [Overlay Documents](#overlay-documents)

Now, let's look at each type of document, in turn.

#### Data Value Schema Documents

If a document begins with the [`@data/values-schema`](how-to-write-schema.md#starting-a-schema-document) annotation, we call it a "Data Values Schema Document" (the light grey dashed box in the illustration, [above](#the-ytt-pipeline)).

```yaml
#@data/values-schema
---
instances: 1
...
```

These files _declare_ variables (Data Values) by setting their name, default value, and type.

#### Data Values Documents

When a document starts with the [`@data/values`](how-to-use-data-values.md) annotation, it's called a "Data Values Document" (the light grey dashed box in the illustration, [above](#the-ytt-pipeline)).

```yaml
#@data/values
---
instances: 8
...
```

These contain the variables that provide values for templates (explained in more detail, in [Step 2: Evaluate Templates](#step-2-evaluate-templates)).

#### Plain Documents

If a document has _no_ `ytt` annotations, we'll call those "Plain Documents" (like the bright yellow item in "Configuration", [above](#the-ytt-pipeline)).
```yaml
---
notes:
- this will be part of the output
- it does get parsed as YAML, but that's about it
```
These documents need no processing (outside of being parsed as YAML), and are included as part of the output of the pipeline.

#### Templated Documents

If a document _does_ contain templating (i.e. lines containing `#@`) it's known as a "Templated Document" (the _pale_ yellow one, [above](#the-ytt-pipeline)).
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
These documents are — after being processed — also included as part of the output of the pipeline.

#### Overlay Documents

When a document _starts_ with the [`@overlay/match...`](lang-ref-ytt-overlay.md#overlays-as-files) annotation (i.e. above the `---`), it's referred to as an "Overlay Document" (denoted as a pale blue item, [above](#the-ytt-pipeline)):
  ```yaml
  #@overlay/match by=overlay.all
  ---
  metadata:
    #@overlay/match missing_ok=True
    namespace: staging
  ...
  ``` 
These documents describe edits to apply just before generating the output (described in detail, below).
  
#### Kinds of Documents in Configuration

Note that most configuration files can contain any combination of "Plain Documents", "Templated Documents", and "Overlay Documents".

The exceptions are "Data Values Schema Documents" and "Data Values Documents". These documents must be in their own file, as illustrated [above](#the-ytt-pipeline).

### Custom Values

The top-middle section of [the diagram](#the-ytt-pipeline) shows where custom values are injected.

These are values supplied by those who use `ytt` to generate the final output. We refer to these people as Configuration Consumers.

They customize the result by supplying their situation-specific settings for Data Values. This can be done as command-line arguments, OS environment variables, and/or plain YAML files. In all cases, these override Data Values that must first be declared in [Data Values Schema Documents](#data-value-schema-documents).

### Step 1: Calculate Data Values

Let's explore what happens at each step in the pipeline.

As the first pipeline step (black box) shows, [above](#the-ytt-pipeline) : <!-- wokeignore:rule=blackbox -->

1. process all the "Data Values Schema" documents (light grey input) — evaluating any templating in them;
2. merge those documents, [in order](lang-ref-ytt-schema.md#multiple-schema-documents), generating a "Data Values Schema" document populated with default values and type information.
3. process all the "Data Values" documents (light grey input) — evaluating any templating in them;
4. merge those documents, [in order](ytt-data-values.md#splitting-data-values-overlays-into-multiple-files). That is, start with the first document and then overlay the second one onto it; then overlay the third document on top of _that_, and so on...
5. finally, override values with the "Custom Values" input, as described in [How to Use Data Values > Configuring Data Values](how-to-use-data-values.md#configuring-data-values). \
   The result of all this is the final set of values that will be available to templates: the dark grey "final Data Values".
6. lastly, if there are any [validations declared in the schema](how-to-write-validations.md), all such rules are evaluated over this final result.

_(Note the data in-flow arrows into this pipeline step are deliberately ordered, left-to-right, reinforcing the sequence in which values are set: defaults from schema, data values documents, and custom values; last source wins.)_


### Step 2: Evaluate Templates

Next, evaluate the remaining templates (all the other kinds of "Configuration" documents):
1.  "evaluate" means executing all of the [Starlark code](lang.md): loops are run, conditionals decided, expressions evaluated.
1.  one notable exception is overlay annotations (i.e. those that start with `@overlay/...`), these are deferred until the next step.
1.  a template accesses input variables (i.e. the Data Values calculated in the previous step) via the [`@ytt:data` module](lang-ref-ytt.md#data);
    
The result of all this evaluation is a set of YAML documents, configured with the Data Values (shown as "Evaluated Document Set" in the diagram, [above](#the-ytt-pipeline)).

### Step 3: Apply Overlays

Note that the "Evaluated Document Set" (see the output from the second step in [the diagram](#the-ytt-pipeline)) contains two groups:
- "Evaluated Documents" — these are the pile of "Plain Documents" and evaluated "Template Documents" (bright yellow) from the previous step.
- "Overlay Documents" — these are the configuration file "Overlay Documents" (bright blue) wherein everything except the `@overlay/...` annotations have been evaluated.

With these in hand:
1. apply each "Overlay Document" on top of the full set of "Evaluated Documents".\
   You can think of each overlay as like a SQL `update` command:
   - the value of it's `by` argument is like a `where` clause that selects over the whole collection of "Evaluated Documents". For example, 
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
   
The result is (shown as "Output Document Set" in the diagram, [above](#the-ytt-pipeline)) — the finalized set of YAML documents, in memory. Which leaves one last step...

### Step 4: Serialize

This is simply iterating over the "Output Document Set", rendering each YAML Document ("Output Files", [above](#the-ytt-pipeline)).

The result is sent to standard out (suitable for piping into other tools). If desired, the output can be sent instead to disk using the [`--output...` flags](outputs.md).

## Further Reading

We've scratched the surface: an end-to-end flow from pre-processing inputs, processing templates, post-processing overlays, and finally rendering the resulting output.

To learn more about...
- **Data Values Schema**
  - learn about [writing Schema](how-to-write-schema.md) for Data Values
  - read-up on the details in the "[Data Values Schema Referce](lang-ref-ytt-schema.md)" material
  - work with a complete example from the source: \
    [carvel-dev/ytt/../examples/schema](https://github.com/carvel-dev/ytt/tree/develop/examples/schema)
- **Data Values**...
  - poke at a working example in the ytt Playground: [Load Data Values](/ytt/#example:example-load-data-values) example
  - read-up on the details in "[Using Data Values](how-to-use-data-values.md)"
  - work with a complete example from the source: \
    [carvel-dev/ytt/../examples/data-values](https://github.com/carvel-dev/ytt/tree/develop/examples/data-values)
- **Templates**...
  - learn Starlark by example in the first bunch of ["Basics" examples](/ytt/#example:example-plain-yaml).
  - read-up on [`ytt`'s built-in libraries](lang-ref-ytt.md) to encode/decode, hash, regex match over data.
  - get an helpfully abridged tour of Starlark in "[Language](lang.md)"
- **Overlays**...
  - walk through the "Overlays" group of examples:
    1. go to the [ytt Playground](/ytt/#example:example-match-all-docs)
    2. find the "Overlays" group header, click on it to reveal the group _(you can close the "Basics" group by clicking on it)_.
  - read an introduction at "[Using Overlays](ytt-overlays.md)"
  - watch [Primer on `ytt` Overlays](/blog/primer-on-ytt-overlays/) for a screencast-formatted in-depth introduction to writing and using overlays.

This overview has meant to provide an end-to-end tour of the core functionality of `ytt`.

There's more to it:
[modularizing configuration files](how-to-modularize/#extract-functionality-into-custom-library) into reusable Libraries, [text templating](ytt-text-templating.md), and
overriding file processing with [file marks](file-marks.md), and more. Use the left navigation to discover more.
