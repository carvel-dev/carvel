---
title: "The Hidden Costs of Misconfiguration"
slug: ytt-validations-released
date: 2022-09-27
author: John Ryan, Varsha Munishwar
excerpt: "When your end-users give the wrong input, the best thing you can do is give them immediate, concise, and actionable feedback. Now you can, with ytt Validations!"
image: /img/ytt.svg
tags: ['ytt', 'data values', 'validation']
---

## A Cryptic Error

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

## Shift Left Configuration Errors

The key to avoiding this kind of suffering is to "shift left" the validating input values.

By "[shift left](https://devopedia.org/shift-left)", we mean moving a test or check to an earlier step in the process.
This has two key effects:
1. the end-user gets immediate feedback, saving them (potentially hours) of troubleshooting;
2. the message they get is in terms of the inputs they provided, not in places where that input was used.

We've actually grown to expect this kind of thing from web applications we use every day. Signing up for
a service, we're often asked for our email address. Usually, we get _immediate_ feedback when we put in a value that
is not a well-formed email address.


## Introducing `ytt` Validations

As of `ytt` v0.43.0, you now have the ability to give your user that more useful/pleasant experience of reporting an
erroneous input right away.

Using our example above, the author could simply include a validation annotation:

```diff
  #! schema.yaml
  #@data/values-schema
  ---
  service_name: ""
  additional_env_values:
    - 
+     #@schema/validation ("environment variable name, expect PORT (which is reserved)", lambda v: v != "PORT")
      name: ""
      value: ""
```
Here:
- each value given for `additional_env_values` will be validated;
- `name:` has a validation rule defined:
  - the first parameter is a user-friendly message, describing what a valid value is;
  - the second parameter is an expression that _implements_ that rule (here, the value of `name:`, passed to `v` can't equal `"PORT"`).

Instead of having to find and make heads-or-tails of [the error message at the top of this article](#a-cryptic-error)...\
... as soon as `ytt` is invoked, they see this:

```console
$ ytt -f schema.yaml --data-values-file values.yaml
ytt: Error: Validating final data values:
  additional_env_values[0].name
    from: values.yaml:4
    - must be: environment variable name, expect PORT (which is reserved) (by: schema.yaml:6)
```

Here:
- the data value they supplied `additional_env_values[0].name` is directly referenced (including filename and line number);
- the definition of a valid value is given.

It's seconds, not minutes (or hours) to learn what when wrong, how, and what they can do to fix it. 

Now _that's_ a delightful experience. 🥳

## Where to, from here?

Learn more about `ytt` Validations:
- See [a demo of validations in action](https://www.youtube.com/watch?v=GBMSru3WBJg) (click "show more" for a table of contents of the video).
- [Upgrade to ytt v0.43.0](/ytt/docs/v0.43.0/install/) or later.
- Get a gentle introduction through our How To [Write Validations](/ytt/docs/v0.43.0/how-to-write-validations).
- Get started quick with our [Validations Cheat Sheet](/ytt/docs/v0.43.0/schema-validations-cheat-sheet).
- Dive into the syntax and inventory of out-of-the-box rules in the [@schema/validation reference](/ytt/docs/v0.43.0/lang-ref-ytt-schema/#schemavalidation).

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:
* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
