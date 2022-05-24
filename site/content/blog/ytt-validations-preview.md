---
title: "Preview of ytt Validations"
slug: ytt-validations-preview
date: 2022-05-23
author: John Ryan
excerpt: "Announcing a pre-release preview of a new ytt feature: Validations. We show about how to enable this 'experiment', take it for a spin, and influence how it all shakes out."
image: /img/ytt.svg
tags: ['ytt', 'data values', 'validation', 'preview', 'experiments']
---

### 📣 Announcing! 📣
We are excited to announce that in `ytt` v0.41.0, we are including a _preview_ of a powerful new feature:

**`ytt` Validations!**

### What are `ytt` Validations?

Validations are constraints that you can declare on your Data Values to ensure that what's supplied is not just well-formed, but in the expected range of values.

Like this:

```yaml
#@data/values-schema
---
volumeSnapshotLocation:
  spec:
    #@schema/validation one_of=["aws", "azure", "vsphere"]
    provider: ""
```

That one new annotation — `@schema/validation` — will:
- validate the final data value against that rule (`provider:` set to one of the three values),
- when exporting schema, translate the rule to OpenAPI v3 / JSON Schema validation.
- automatically include documentation describing the rule.

While we plan on delivering a host of useful named rules, out of the box, there is a way to define custom validation rules, yourself.

For all the juicy details, check out the [Validations Proposal/Specification](https://github.com/vmware-tanzu/carvel/blob/004-schema-validation/proposals/ytt/004-schema-validation/README.md).

This kind of thing is very useful for situations where a mis-configured deployment could waste a lot of resources and be much more difficult to troubleshoot than getting an immediate error message that the configuration value was wrong.

### 🔬 It's an Experiment! 🧪

To make a preview possible, we're also introducing a feature for enabling "**experiments**" in v0.41.0.

An "experiment" is a feature that is still in development. By default, all experiments are off. 

When you switch on an experiment, it lights-up the named feature, allowing you to take it for a spin. Of course, like any early access software, using `ytt` with any experiments enabled means it's not suitable for production environments. All APIs introduced with the experiment are unstable and will change as we improve the UX and behavior of the feature.

So, `ytt` Validations is the first of these such experiments.

We're doing this so that you have a voice in making sure features like this meet _your_ needs.

### How do I get started?

`ytt` v0.41.0 will be released soon. When it does, grab yourself the latest.

Then, to enable Validations, and start including validation rules in a copy of _your_ schema:

```yaml
#@data/values-schema
---
dex:
  #@schema/validation ("non-empty value", lambda v: len(v) > 1)
  username: ""
  #@schema/validation ("non-empty value", lambda v: len(v) > 1), ("not 'default'", lambda v: v != "default")
  namespace: ""
  #@schema/validation ("one of: aws, azure, vsphere", lambda v: v in ["aws", "azure", "vsphere"])
  provider: ""
```

... and set the OS environment variable, `YTTEXPERIMENTS`...

```console
$ YTTEXPERIMENTS=validations yttt -f schema.yml -v dex.namespace=default
ytt: Error: One or more data values were invalid:
- "username" (schema.yml:5) requires "non-empty value" (by schema.yml:4)
- "namespace" ((data-value arg):1) requires "not 'default'" (by schema.yml:6)
- "provider" (schema.yml:9) requires "one of: aws, azure, vsphere" (by schema.yml:8)
```

You'll notice that with the validations experiment turned off, `ytt` doesn't recognize those annotations.

```console
$  yttt -f schema.yml -v dex.namespace=default --data-values-inspect
dex:
  username: ""
  namespace: default
  provider: ""
  ```

### What is implemented so far?

As of v0.41.0, we've implemented the core behavior of recognizing, parsing, and checking validations in schema.

In essence, we've introduced the `@schema/validation` annotation and wired it in to [the `ytt` pipeline](../ytt/docs/v0.40.0/how-it-works/) — specifically, at the end of the "Calculate Data Values" step.

We're including light documentation as we go, so check out `[link to @schema/validation in schema reference]` for the exact details of what's available.

### How can I give feedback?

We would love to tell you, thank you for asking!

Delightfully, any format that is most convenient for you, we're happy to hear your thoughts!

The likely easiest/best way is by popping by our channel on the Kubernetes Slack workspace: [#carvel](https://kubernetes.slack.com/archives/CH8KCCKA5). You can fork a thread, there; request a direct message conversation; or even a video call. If you don't yet have an account there, you can get an invite at http://slack.k8s.io/.

That said, if you prefer the long-form, feel free to [create a GitHub Issue in our repo](https://github.com/vmware-tanzu/carvel-ytt/issues/new?assignees=&labels=carvel+triage&template=other-issue.md&title=Feedback+for+ytt+Validations).


### Why are Validations Useful?

To date, ytt Library / Carvel Package authors have had to "roll their own" logic to check that customer's inputs are valid: that data values are present/non-empty and within acceptable values.

They have had to...

- learn Starlark, in some depth, just to get started
- write code to collect all violations (instead of failing on first violation)
- hand-manage ordering validation evaluation — leaves to root
- write custom code to handle common scenarios (empty values, enums, unions, conditional)
- hand-document validations by adding comments to their Data Values (Schema) describing those constraints.
- ...

The more time you spend doing this, the less time you spend making progress on your _actual_ goal.
