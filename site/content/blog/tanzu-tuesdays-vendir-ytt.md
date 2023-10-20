---
title: "Manage Kubernetes Configurations with vendir + ytt"
slug: tanzu-tuesdays-vendir-ytt
date: 2022-04-05
author: Leigh Capili
excerpt: "Finding your YAML happy place."
image: /img/ytt.svg
tags: ['ytt', 'vendir', 'introduction', 'data values', 'library', 'patching', 'helm', 'kustomize']
---

When you’re steeped in YAML, looking for a way to keep the maintenance of all this configuration manageable, 
selecting the right tool for your situation can get complicated, fast.

In the April 5th edition of “Tanzu Tuesdays” (hosted by Tiffany Jernigan), Leigh Capili
gives a compelling survey of some of the most popular tools used to manage Kubernetes YAML. This is no cursory skim, 
but an empathetic tour — taking the time at each stop and appreciate what each tool brings… and where it starts to strain.

The Carvel team is delighted to learn that for Leigh, when he picks up `ytt`, he thinks to himself: “This is my happy place.” 
Doubly so, because it’s not just a matter of opinion, but for well considered reasons.

The icing on the cake for Leigh is a lesser known member of the Carvel suite: `vendir`. 
This little gem proves to be a surprise delight: when you’re pulling Kubernetes manifests from upstream sources 
(in just about any protocol you’ll use), look no further than declaring that source and let `vendir sync` take care of the rest. 
Goodbye git submodules. Goodbye ad-hoc schemes for tracking source versions (i.e. `vendir` has a lock file that captures that information for you). 
Hello, simple declarative dependencies!

So, if you’re turning over your YAML management options, feeling the pains of your current choice, 
or looking for a better way to manage your upstream-managed Kubernetes config, we strongly encourage you to give yourself the gift of hanging out with Tiffany and Leigh.
 

Video Outline:
- [0:00](https://www.youtube.com/watch?v=0WT7O3kJwjw)- Introduction & miscellaneous
- [06:48](https://www.youtube.com/watch?v=0WT7O3kJwjw&t=408s) - What is happening with all this YAML config
- [11:01](https://www.youtube.com/watch?v=0WT7O3kJwjw&t=661s) - Taking a look at other tools in the ecosystem
- [28:52](https://www.youtube.com/watch?v=0WT7O3kJwjw&t=1732s) - Taking a look at `ytt` + `vendir`
- [1:19:07](https://www.youtube.com/watch?v=0WT7O3kJwjw&t=4747s) - Outro
<!-- https://gohugo.io/content-management/shortcodes/#youtube -->
{{< youtube id="0WT7O3kJwjw" title="Tanzu Tuesdays 92: Carvel: vendir + ytt with Leigh Capili" >}}

{{< blog_footer >}}