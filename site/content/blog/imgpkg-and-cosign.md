---
title: "Signing imgpkg Bundles with cosign"
slug: signing-imgpkg-bundles-with-cosign
date: 2021-10-07
author: Dennis Leon
excerpt: "Interested in learning about how imgpkg integrates with cosign? Take a walkthrough on how imgpkg can promote a bundle into prod, signing and verifying using cosign"
image: /img/imgpkg.svg
tags: ['image signing', 'cosign', 'imgpkg']
---

# imgpkg and cosign

![You wouldn’t steal a car
](/images/blog/imgpkg_and_cosign_blog_intro.png)

Some of y'all might remember the beginning of every DVD movie showing this warning (read: scare tactic) to try and combat piracy.

These days, however, based on the amount of security breaches, dev tools could use a similar warning, i.e. using an image that hasn't had its signature verified.

**“You wouldn’t insert a USB found on the sidewalk”**

[Imgpkg](https://carvel.dev/imgpkg/) is a way to package and distribute multiple images via a single OCI artifact known as a [Bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle). [Cosign](https://github.com/sigstore/cosign) is a way to sign container images.

We at [Carvel](https://https://carvel.dev/) are always looking for opportunities to integrate with existing OSS solutions. Cosign is one such tool we have integrated with (since [imgpkg 0.9.0+](https://github.com/carvel-dev/imgpkg/releases/tag/v0.9.0)).

This integration aims to solve the problem of having various images representing a deployment, and propagating it from dev to production while maintaining integrity and provenance.

It can be summed up in 3 steps:

1. Sign the container image after building
1. Copy the bundle (of images)
1. Verify the image signatures before deployment


Alright let me try to explain in a little more detail.

## Bootstrapping

```bash
$ imgpkg version
imgpkg version 0.19.0

$ cosign version
GitVersion:    v1.2.1
```

We are going to work with two projects:
- useful-server-image: represents an image we want to use in our deployment
- useful-bundle: contains deployment configuration, references the useful-server-image and is what allows copying a single entity representing a deployment across environments. [Read more about what an imgpkg Bundle is](https://carvel.dev/imgpkg/docs/latest/resources/#bundle)

Each project will also have its own private/public key used to sign and verify said image.

```bash
$ mkdir -p useful-server-image-repo/{key,src}
$ cd useful-server-image-repo/key
$ cosign generate-key-pair

$ mkdir -p useful-bundle-repo/{key,.imgpkg}
$ cd useful-bundle-repo/key
$ cosign generate-key-pair
```

Private keys are stored as encrypted PEM files. They should be safe to put along side your source code. This allows you to decrypt and then sign (requiring a password stored in a secure manner) as part of your CI/CD system.

## Signing images

Now let's build some images *and* sign them!

Creating a simple single-layer image can be achieved using the imgpkg `push` command (with the `--image` flag). There are plenty of other ways to build images too! (using [kbld](https://github.com/carvel-dev/kbld), [docker](https://www.docker.com/) etc). This workflow works with all of them.


```bash
$ pwd
/useful-server-image-repo
$ imgpkg push --image useful-server-image:0.1.0 --file ./src
Pushed 'useful-server-image@sha256:f13a810a247008e5afb49af331e0849182dea927390f3fde82443d600d57f1f5'
Succeeded

$ cosign sign -key ./key/cosign.key useful-server-image:0.1.0
Pushing signature to: useful-server-image:sha256-f13a810a247008e5afb49af331e0849182dea927390f3fde82443d600d57f1f5.sig
```

Let's also create the bundle image and reference the useful-server-image we pushed just a second ago. One difference being we provide the `push` command with the `--bundle` flag instead of the `--image` flag.

*For this example, I'm keeping it simple and only using one image (useful-server-image). However, imgpkg has been optimized and used in the wild to reference many hundreds of images. Let's create an [imgpkg Bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle) and reference every image we plan on using in our deployment.*

```bash
$ pwd
/useful-bundle-repo
$ cat <<EOF > .imgpkg/images.yml
---
apiVersion: imgpkg.carvel.dev/v1alpha1
images:
- image: useful-server-image@sha256:f13a810a247008e5afb49af331e0849182dea927390f3fde82443d600d57f1f5
kind: ImagesLock
EOF

$ imgpkg push --bundle useful-bundle:1.0.0 --file .
dir: .
dir: .imgpkg
file: .imgpkg/images.yml
Pushed 'useful-bundle@sha256:af5b5e594aab43e2a339017e0e54541afed1c972ae897f86a7112545109c817e'

$ cosign sign -key ./key/cosign.key useful-bundle:1.0.0
Pushing signature to: useful-bundle:sha256-af5b5e594aab43e2a339017e0e54541afed1c972ae897f86a7112545109c817e.sig
```

We now have our two images pushed and signed! Digging a bit deeper however, `useful-bundle` and `useful-server-image` *actually* now have *two* images each. One being the image pushed using `imgpkg` and the other containing the signature of said image.

**Note:** Cosign uses a fixed naming convention to decide the name for the signature image. This naming convention will allow imgpkg to 'discover' the signature images belonging to `useful-bundle` and `useful-server-image` during the upcoming copy step.

For those of you curious to find the location of the signature image you can use the `triangulate` subcommand:
```bash
$ cosign triangulate useful-server-image:0.1.0
useful-server-image:sha256-f191fa2c7403b225017a1e0ea1db3ee693251de450615789e17981c4e5ed17d1.sig
```

Our bundle of images are now ready to be promoted to the test environment.

## Promoting a bundle

Now let's leverage the imgpkg `copy` command to replicate `useful-bundle`, and its referenced image `useful-server-image`. Notice that signature verification continues to work in the new target repository.

```bash
$ imgpkg copy --bundle useful-bundle:1.0.0 --to-repo useful-bundle-test-repo --cosign-signatures
copy | exporting 4 images...
copy | will export useful-bundle@sha256:af5b5e594aab43e2a339017e0e54541afed1c972ae897f86a7112545109c817e
copy | will export useful-bundle@sha256:fa4ef95afe31c1664db2c5a8afea2071643dd05f466465abeede742acaea0fec
copy | will export useful-server-image@sha256:f13a810a247008e5afb49af331e0849182dea927390f3fde82443d600d57f1f5
copy | will export useful-server-image@sha256:f191fa2c7403b225017a1e0ea1db3ee693251de450615789e17981c4e5ed17d1
copy | exported 4 images
copy | importing 4 images...

$ cosign verify -key useful-bundle-repo/key/cosign.pub useful-bundle-test-repo:1.0.0
Verification for useful-bundle-test-repo:latest --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
  - Any certificates were verified against the Fulcio roots.

[{"critical":{"identity":{"docker-reference":"useful-bundle"},"image":{"docker-manifest-digest":"sha256:af5b5e594aab43e2a339017e0e54541afed1c972ae897f86a7112545109c817e"},"type":"cosign container image signature"},"optional":null}]
```

imgpkg `copy` (with the `--cosign-signatures` flag) ensures the bundle image, images referenced *within* the bundle and the signature images are identical between the source and target repository.

It might be useful to note that an 'image' is an abstract concept, similar to a network connection really being a series of packets stitched together. An image is a bunch of json and tar files stitched together. This json known as the [OCI’s Image Manifest](https://github.com/opencontainers/image-spec/blob/main/manifest.md) is encoded and hashed, resulting in a digest that can be signed over using cosign. And as previously stated, because imgpkg guarantees the contents of the OCI's Image Manifest is identical, cosign signature verification continues to work!


Once the necessary testing has been performed on our useful-bundle, we can annotate (using cosign's `-a` flag) the signature image signalling that the e2e tests has succeeded. We then promote the bundle from test to production.

```bash
$ pwd
/useful-bundle-repo
$ cosign -key ./key/cosign.key -a e2e-tests-passed=True useful-bundle-test-repo:1.0.0
$ imgpkg copy --bundle useful-bundle-test-repo:1.0.0 --to-repo useful-bundle-prod-repo --cosign-signatures
```

## Production
The bundle that now resides in the production repository can be verified (yet again) with additional checks to ensure that e2e tests have also run.

```bash
$ pwd
/useful-bundle-repo
$ cosign verify -key key/cosign.pub -a e2e-tests-passed=True useful-bundle-prod-repo:1.0.0
Verification for useful-bundle-test-repo:latest --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
  - Any certificates were verified against the Fulcio roots.

[{"critical":{"identity":{"docker-reference":"useful-bundle"},"image":{"docker-manifest-digest":"sha256:af5b5e594aab43e2a339017e0e54541afed1c972ae897f86a7112545109c817e"},"type":"cosign container image signature"},"optional":null}]
```

Running that same verification using the original (dev) useful-bundle does *not* succeed. This is because that image was not annotated with `e2e-tests-passed`.

```bash
$ pwd
/useful-bundle-repo
$ cosign verify -key key/cosign.pub -a e2e-tests-passed=True useful-bundle:1.0.0
error: no matching signatures:
missing or incorrect annotation
```


To learn more about how to deploy this bundle on kubernetes, check out our docs around [pulling a bundle](https://carvel.dev/imgpkg/docs/latest/commands/#pull) onto disk and using carvel to [deploy config to kuberenetes](https://carvel.dev/blog/deploying-apps-with-ytt-kbld-kapp/).

Lastly, If you are using kubernetes there is a [good article](https://medium.com/sse-blog/verify-container-image-signatures-in-kubernetes-using-notary-or-cosign-or-both-c25d9e79ec45) describing how to verify images used in resources (like pods) using Connaisseur.

## Whats next

I'm personally excited about the upcoming features imgpkg has lined up. View our [roadmap for the latest info](https://github.com/carvel-dev/carvel/blob/develop/ROADMAP.md).

Also, imgpkg is only a single building block. [Carvel](carvel.dev) (inspired by the [unix philosophy](https://en.wikipedia.org/wiki/Unix_philosophy)) also offers other composable, modular building blocks giving users full flexibility in how they wish to work, while still preserving extensibility in their workflow.

## Join us on Slack and GitHub

We are excited about this new adventure and we want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel’s slack channel, [#carvel in Kubernetes](https://kubernetes.slack.com/archives/CH8KCCKA5) workspace and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/carvel-dev/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](https://carvel.dev/community/) for full details on how to attend.
