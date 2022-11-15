---
title: "Getting Started With ytt, Part 2"
slug: getting-started-with-ytt-part-2
date: 2022-11-13
author: Varsha Munishwar
excerpt: "Ever needed to make the same edits in multiple places in your kubernetes manifests? That can be error-prone. Learn how ytt can help you avoid misconfigurations." 
image: /img/ytt.svg
tags: ['ytt', 'ytt getting started', 'tutorials']
---

#### Welcome to the "Getting started with ytt" tutorial series!

In the Part 2, we will cover the following:
- Summary of [Part 1](getting-started-with-ytt-part-1/).
- Dive into a slightly more involved scenario to solve a common problem in Kubernetes.
- Learn why some set of labels are required to be in sync.
- Introduce a ytt feature to avoid misconfigurations due to manual edits.

#### Getting started with ytt - Part 2
{{< youtube id="brOoKhVxedE" title="Getting started tutorial - Part 2" >}}


**Note:**
- The **key moments/timestamps** are available if you watch on youtube. Please click on "**more**" and "**view all**".
- Here is the sample [deployment configuration](https://carvel.dev/ytt/#gist:https://gist.github.com/vmunishwar/db610648e999bebeb8743eb6eddd2d40) that is used in this tutorial to deploy the application on kubernetes cluster.
- Visit the documentation for more information on [functions in ytt](https://carvel.dev/ytt/docs/v0.43.0/how-to-modularize/#functions).
- In this tutorial, we are deploying the application on kubernetes using [Carvel's](https://carvel.dev/) deployment tool called kapp. If you are interested to know more here is the [link]( https://carvel.dev/kapp/). 


Happy Templating :)


## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:
* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
