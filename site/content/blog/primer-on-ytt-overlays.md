---
title: "Primer on ytt Overlays"
slug: primer-on-ytt-overlays
date: 2022-03-31
author: John Ryan
excerpt: "Ever been frustrated writing an ytt Overlay? Here's that primer you wish you had."
image: /img/ytt.svg
tags: ['tag', 'tags', '', 'bundle', 'image collocation']
tags: ['ytt', 'overlay', 'overlays', 'introduction', 'primer', 'patching']
---

ytt Overlays can be a little ... unintuitive. 😬 If you've taken Overlays out for a spin and been kinda frustrated, you're not alone. There's _a lot_ going on even in the simplest case. This makes for a steep learning curve.

I'm here to flatten that learning curve. 👍

Let's walk in the shoes of someone who has a host of needs for overlays: each getting a little more sophisticated than the last. By the time we're done, we'll have seen all the core aspects of this powerful feature ... and better yet, we'll have learned how to:
- quickly read overlay-related error messages, 
- make the most of the built-in matchers and know how to write your own,
- understand how ytt annotations attach to YAML,

... and much more.

This is a vlog because it is so much more instructive to see this kind of feature working in realtime than to read about it. While each part builds on the last, you can also jump around if you'd like; don't miss the index in the video description.

Feel free to just sit back and take it all in. Some learn better by doing; here's [the starting point of the primer](https://carvel.dev/ytt/#gist:https://gist.github.com/pivotaljohn/28869c2a1261e7e922412feee25adb8d) and you can follow along. It can also be helpful to have [a complete working example](https://carvel.dev/ytt/#gist:https://gist.github.com/pivotaljohn/fd11e2b4ee7256ec574dda77856ef956) just in case it all goes off the rails.

If you have any further questions, we're a mere Slack message away: [Kubernetes#carvel](https://kubernetes.slack.com/archives/CH8KCCKA5) (if you need one, grab an invite here: http://slack.k8s.io).

Without further ado, let's get overlayin'!

<!-- https://gohugo.io/content-management/shortcodes/#youtube -->
{{< youtube id="15YGMYZ7Vv0" title="Primer on ytt Overlays" >}}
