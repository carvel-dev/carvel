---
title: "Carvel In August"
slug: carvel-in-august-2022
date: 2022-09-12
author: Aaron Hurley and Carvel Engineers
excerpt: "Reviewing the highlights of what the team has worked on last month."
image: /img/logo.svg
tags: ['kapp', 'impgkg', 'kapp-controller', 'ytt', 'vendir']
---
# Carvel in August

August was an action-packed month in the land of Carvel. Keep reading to learn more about what's going on in the project!

### In the News

Let's get started by reviewing some fresh Carvel-related content:

* [TAP And Helm – A Story Of YTT Magic](https://vrabbi.cloud/post/tap-and-helm-a-story-of-ytt-magic/) - How `ytt` solved a tricky challenge.
* [Continuous Thing-Doer](https://petewall.net/continuous-thing-doer/) - Keeping Concourse updated with Carvel
* [Local development workflow with Tilt and Carvel](https://carvel.dev/blog/tilt-carvel-local-workflow/) - How to integrate Tilt with carvel
* [Stop forking Kubernetes helm charts and do this instead!](https://www.youtube.com/watch?v=a-bEEKt7eHA) - A conversation with Robusta.dev introducing ytt
* [Introducing `kctrl` package authoring commands](https://carvel.dev/blog/kctrl-pkg-authoring-cmds/) - Simplifying package authoring. Checkout [the demo from our community](https://www.youtube.com/watch?v=UUBKK5KtquU).
* [Between Chair and Keyboard with Soumik Majumder](https://www.youtube.com/watch?v=tM79Z08WDkM) - A conversation with one of Carvel's enthusiastic maintainers, Soumik.
* We had a couple of great community meetings in August. Watch the [ytt schema validations demo](https://www.youtube.com/watch?v=GBMSru3WBJg) to learn more about the exciting new features that will be arriving soon. See the full community meeting recordings from [August 10th](https://www.youtube.com/watch?v=mxlKpvkJDUk) and [August 24th](https://www.youtube.com/watch?v=6OjRzGskT60).
* Mark your calendars for GitOpsCon North America! Learn about [experimenting with CUE and Carvel to enable GitOps for your applications](https://gitopsconna22.sched.com/event/1AR9Z)

### kapp

kapp had two releases in August:

* [v0.52.0](https://github.com/vmware-tanzu/carvel-kapp/releases/tag/v0.52.0)
    * Added `--default-label-scoping-rules` flag to enable or disable the default label scoping rules added during deploy
    * Bump k8s.io/client-go from v0.22.10 to v0.24.3
    * Bug fix: `--app-metadata-file-output` writes to disk even when deploy fails
* [v0.51.0](https://github.com/vmware-tanzu/carvel-kapp/releases/tag/v0.51.0)
    * Added `--app-metadata-file-output` flag which can be used to save recorded app metadata to a file.
    * Bump modern-go/reflect2 to v1.0.2 to fix incompatibility with Go v1.18
        * This problem became apparent with some random failures while trying to connect to GKE clusters.
        * Example error fixed `unexpected fault address 0xb01dfacedebac1e fatal error: fault`

### kapp-controller

* [v0.40.0](https://github.com/vmware-tanzu/carvel-kapp-controller/releases/tag/v0.40.0)
    * kctrl
        * Introducing the package authoring commands
        * dev deploy
    * Packages can constrain Kubernetes and kapp-controller versions
    * Package authors can now specify that their package can be installed on a certain versions of both kapp-controller and kubernetes.
    * Surface namespace and GK resources in AppCR status
    * Upgrade GoLang from 1.18 to 1.19
    * Bumped dependencies
* [v0.39.0](https://github.com/vmware-tanzu/carvel-kapp-controller/releases/tag/v0.39.0)
    * Add arm64 builds
    * Add downward api
    * Rename KC owned apps from x-ctrl to x.app or x.pkgr
    * use cache mount in Dockerfile
    * various bug fixes
    * kctrl
        * Add tailing behaviour to package repo and add a package repo kick command
        * Disallow use of shared namespaces for package installs
        * Enhance tty experience


### imgpkg

* [v0.31.0](https://github.com/vmware-tanzu/carvel-imgpkg/releases/tag/v0.31.0)
    * Resume the download of an image/bundle to tar
    * By providing the flag `--resume` to the `copy` command, imgpkg is now able to only download the missing blobs that cannot find in the file on disk. The flag doesn't error out if the tar file does not exist
    * Check if an image or bundle is cacheable or not. Note: This feature is only available on the new API call. Let us know if you see any benefit in implementing option 1 from that story.
    * API Improvements:
        * When calling the function to push images to the registry, via API, the user can provide a progress bar logger. This will allow for the progress to be displayed in the console.
        * Create API for Pull
        * Extracted the Pull logic to the new package that will contain imgpkg's public API, check [the package](https://github.com/vmware-tanzu/carvel-imgpkg/tree/develop/pkg/imgpkg/v1). With this change, the Pull command can be changed to provide machine-readable output.

### ytt

August was spent collecting and acting upon feedback for schema validations. These features are planned to GA in mid-September. For a preview, see the below links.

* [Blog: Preview of ytt Validations](https://carvel.dev/blog/ytt-validations-preview/) on how to get setup with this feature.
* see all available rules in the [docs](https://carvel.dev/ytt/docs/v0.42.0/lang-ref-ytt-schema/#schemavalidation).

### vendir

* [v0.30.0](https://github.com/vmware-tanzu/carvel-vendir/releases/tag/v0.30.0)
    * semver `HighestConstrainedVersion` takes additional constraints

## Farewell til Next Month!

Wishing you smooth deployments and painless upgrades!

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
