---
title: "Carvel In July"
slug: carvel-in-july-2022
date: 2022-08-04
author: Joe Kimmel, Praveen Rewar, and Carvel Engineers
excerpt: "Like Christmas in July but with Carvel. Let's walk-through the highlights of what the team has worked on last month."
image: /img/logo.svg
tags: ['kapp', 'impgkg', 'secretgen-controller']
---
# ~~Christmas~~ Carvel in July

Ah, July in America[^1]! Long days, warm nights, fireworks, barbecues, vacations, and many iconic releases from our Carvel summer collection. Let us peruse the highlights, as we make s’mores in our bonfires.


### Kapp

Kapp celebrated its 50th release with luminous features such as:


* default change groups and change rules for kapp-controller resources
* Output is now available in delicious yaml, just like mom used to make!
    * Use --diff-changes-yaml while deploying an app to see the complete yaml after rebase rules etc,. are applied.
* unblockChanges can be used with conditions in waitRules to unblock any waiting changes
    * These conditions are treated as non success/failure conditions. Helpful when you want to unblock waiting changes but would still want kapp to wait for the resource to reconcile based on other success/failure conditions. 


### Imgpkg

* Improved support for cross-platform transfers of bundles


### Ytt

Have you ever seen an innocently wrong piece of configuration blow up a deployment? Wish that simple mistake could have been caught sooner — before a bunch of resources were snarled!?? No longer must you cower in fear that your data might be invalid!
Go forth boldly, young padawan, ensuring that your data is valid with our new feature[^2], available starting in ytt 0.42.0.

    * [Blog: Preview of ytt Validations](https://carvel.dev/blog/ytt-validations-preview/) on how to get setup with this feature.
    * see all available rules in the [docs](https://carvel.dev/ytt/docs/v0.42.0/lang-ref-ytt-schema/#schemavalidation).


### Secretgen-controller

The previously introduced “Secret Templates” are no longer secret now that they’re fully [documented](https://github.com/vmware-tanzu/carvel-secretgen-controller/blob/develop/docs/secret-template.md).


### Farewell til Next Month!

Wishing you smooth deployments and may the pods smile upon you!

[^1]: Half the Carvel team is actually in India, but we’ll let them tell us about August or September in India in the coming months.
[^2]: experimental feature

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
