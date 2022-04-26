---
title: "kapp rebase rules"
slug: kapp-rebase-rules
date: 2022-04-26
author: Joe Kimmel
excerpt: "Use kapp rebase rules to preserve or change some fields when updating a resource"
image: /img/logo.svg
tags: ['kapp', 'rebase-rules', 'rebaserules']
---


### Who

This article could be helpful for anyone who runs `kapp deploy -a …`, but especially for people who wonder if kapp is capable of preserving some fields in a resource on the cluster during an update.

### Why

Here’s one example of a recent question in [#carvel](https://kubernetes.slack.com/archives/CH8KCCKA5), our community channel in the Kubernetes Slack:

    _Is there a way to use an annotation for kapp to somehow ignore immutable fields? [...] somehow get the immutable field current values and pull them into the patch we are applying with kapp?_

You might expect we would solve this like `kubectl apply` or git with a 3 way merge, but that approach can be inflexible or require manual steps for some kinds of conflicts.

With the rebase rule approach, kapp takes user provided config as the only source of truth, but also allows users to explicitly specify that certain fields are cluster controlled. This method guarantees that clusters don’t drift, which is better than what basic 3 way merge provides. (You can read more about the rationale behind rebase rules [here](https://carvel.dev/kapp/docs/v0.46.0/merge-method/).) 

### What

A Rebase rule is applied when all of the below are true:

* While updating a resource
* A rebase rule was passed into kapp for this update
* The resource being updated is matched by the “matchers” section of the rebase rule

Rebase rules come in two flavors: “copy/remove” and ytt.

The rebase rule is applied at a moment when kapp has an in-memory representation of both the resource that already exists and the resource as it would be changed by the current update.

The “copy/remove” flavor rebase rule allows you to set up logic such as “prefer to copy the existing values of this field if it already exists, but otherwise take the new ones that are generated as part of this update.” This style of rebase rule operates basically on a single field at a time, choosing to copy or remove it.

A ytt rebase rule goes even further, allowing you to run ytt templating steps across the whole resource and even apply any business logic that can be expressed in starlark. I think of ytt rebase rules in kapp as very similar to stored procedures in SQL databases: they live in a file that may or may not be versioned and deployed with the rest of your code and they can make arbitrary changes right in the middle of execution of a db query, or kapp deploy, respectively. So they’re a real power tool, with all the flexibility and dangers implied!

#### Examples

There are rebase-rules in `kapp deploy-config` that are applied by default every time you run `kapp deploy …` in order to make the experience sane and consistent with user expectations. For example, the first two rebase rules match all resources and act to preserve the existing metadata on the cluster and then to apply the user’s new metadata fields over that:

```
# Copy over all metadata (with resourceVersion, etc.)

- path: [metadata]

  type: copy

  sources: [existing]

  resourceMatchers:

  - allMatcher: {}

# Be specific about labels to be applied

- path: [metadata, labels]

  type: remove

  resourceMatchers:

  - allMatcher: {}

- path: [metadata, labels]

  type: copy

  sources: [new]

  resourceMatchers:

  - allMatcher: {}

```


### Where

“Where” is a funny question in the cloud, since the answer is always “someone else’s computer”, right? ;-)

Rebase rules aren’t persisted anywhere on the cluster, so they have to be supplied to kapp each time you want them to be applied.


### When

Copy/remove flavor rebase rules have been in kapp nearly since the dawn of time, but were substantially updated in kapp 0.6.0 and evolved to their fully modern form sometime around kapp 0.27.0.

Ytt rebase rules were introduced in kapp v0.38.0 (August 2021).


### How To Use

Here’s some links to rebase rules examples in our docs and tests

* copy/remove flavor
    * [Keep existing cluster values for a HPA deployment](https://carvel.dev/kapp/docs/v0.46.0/hpa-deployment-rebase/#docs)
    * [Use new values if provided, or fallback on existing cluster values for a PVC](https://carvel.dev/kapp/docs/latest/rebase-pvc/#docs) 
* ytt flavor
    * [Retain cluster added token secret in ServiceAccount’s secrets array](https://github.com/vmware-tanzu/carvel-kapp/blob/d3ee9a01b5f0d7d5632b6a157ea7d0338730d497/pkg/kapp/config/default.go#L123-L154)
    * [Add a kapp-noop annotation to force a resource with update conflicts not to reconcile ](https://github.com/vmware-tanzu/carvel-kapp/blob/724d714376c8835368915661b6a5ecda06bc7ed5/test/e2e/create_fallback_on_noop_test.go#L31-L47)
      (effectively:  “if there’s an update conflict, keep exactly what’s on the server”) 
      
## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30 am PT / 1:30 pm ET. Check out the [Community page](/community/) for full details on how to attend.
