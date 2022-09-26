---
title: "The Hidden Costs of Misconfiguration"
slug: ytt-validations-released
date: 2022-09-26
author: John Ryan, Varsha Munishwar
excerpt: "When your end-users give the wrong input, the best thing you can do is give them immediate, concise, and actionable feedback. Now, you can do that with ytt Data Values Validations!"
image: /img/ytt.svg
tags: ['ytt', 'data values', 'validation']
---

## The Hidden Costs of Misconfiguration

Take a look at this error message:

```
...
Updating resource service/petc (serving.knative.dev/v1)
  API server says: 
     admission webhook "validation.webhook.serving.knative.dev" denied the request:
        validation failed: 
           "PORT" is a reserved environment variable: spec.template.spec.containers[0].env[0].name
...
```

What you're looking at is the tail end of a **30-minute circuitous journey locating and collecting logs** after a 
particular service apparently failed to deploy. 🥵

The person trying to decipher this cryptic-to-them error message wasn't versed in the intricacies of
Knative services. What they _did_ know was that there's a configuration option in the package they are using
to inject environment variables.

Here's the simplified schema:

```yaml
#! schema.yaml
#@data/values-schema
---
service_name: ""
additional_env_values:
  - name: ""
    value: ""
```

and they had supplied these data values:

```yaml
# values.yaml
---
service_name: hello
additional_env_values:
  - name: PORT
    value: "5432"
```

When they deployed their application, all seemed to be in order... until it wasn't.

Now, in this reduced example, the source of the error is probably obvious to the reader. But consider when
there are dozens (if not more) Data Values involved... or if there weren't so obvious matchable strings in
the error message and inputs.

And at least in _this_ case, there's an admission webhook involved. Imagine if the workload simply quietly failed
to run? Or ignored the invalid configuration altogether??!?

It's a recipe for pain. 😖

## Shift-Left Configuration Errors

The key to avoiding this kind of suffering is to "shift left" the validating input values.

By "[shift left](https://devopedia.org/shift-left)", we mean moving a test or check to an earlier step in the process.
This has two key effects:
1. the end-user gets immediate feedback, saving them (potentially hours) of troubleshooting.
2. the message they get is in terms of the inputs they provided, not in places where that input was used.

We've actually grown to expect this kind of thing from web applications we use every day. Signing up for
a service, we're often asked for our email address. Usually, we get _immediate_ feedback when we put in a value that
is not a well-formed email address.


## Introducing `ytt` Data Values Validations

As of `ytt` v0.43.0, you now have the ability to give your user that more useful/pleasant experience of reporting an
erroneous input right away.

Using our example above, the author could simply include a validation annotation:

```yaml
#@data/values-schema
---
service_name: ""
additional_env_values:
  - 
    #@schema/validation ("environment variable name, expect PORT (which is reserved)", lambda v: v != "PORT")
    name: ""
    value: ""
```
Here:
- each value given for `additional_env_values` will be validated.
- `name:` has a validation rule defined:
  - the first parameter is a user-friendly message, describing what a valid value is.
  - the second parameter is an expression that _implements_ that rule (here, the value of `name:`, passed to `v` can't equal `"PORT"`)

Instead of having to make heads-or-tails of the error message at the top of this article, they see this:

```console
$ ytt -f schema.yaml --data-values-file values.yaml
ytt: Error: Validating final data values:
  additional_env_values[0].name
    from: values.yaml:4
    - must be: environment variable name, expect PORT (which is reserved) (by: schema.yaml:6)
```

Here:
- the data value they supplied `additional_env_values[0].name` is directly referenced (including filename and line number)
- the definition of a valid value is given.

It's seconds, not minutes (or hours) to learn what when wrong, how, and what they can do to fix it. 

Now _that's_ a delightful experience. 🥳

## How do I get started?

1. upgrade to ytt v0.43.0
2. TODO: pointer into the Guide, Cheat Sheet, and reference.


