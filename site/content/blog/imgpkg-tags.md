---
title: "imgpkg image collocation and tagging"
slug: imgpkg-image-collocation-and-tagging
date: 2022-03-24
author: Joao Pereira
excerpt: "Understand imgpkg bundles and tags associated with them"
image: /img/logo.svg
tags: ['tag', 'tags', 'imgpkg', 'bundle', 'image collocation']
---

# imgpkg image collocation and tagging

Some people have been asking questions like

- "Why are all bundle images copied to the same repository?"
- "Why do I have so many tags in my repositories?"

We will try to give an overview of how `imgpkg` works and try to answer these questions at the same time.

## Common terms

But before we can do this, lets try to establish some common terms

- OCI: Open Container Initiative, [the official website](https://opencontainers.org/)
- Image: content stored within OCI registry
- Bundle: OCI Image that contains configuration and OCI images
- OCI Terminology
  ![OCI Terminology](/images/blog/OCITerminology.png)

## Creating a Bundle and pushing it to the registry

A bundle is just a regular OCI image that can contain anything inside it, but in order for `imgpkg` to consider it a
bundle, some requirements need to be followed:

- The OCI image must have only 1 layer
- The OCI image must contain the file `.imgpkg/images.yml` with the content that is compatible with
  the [ImagesLock structure](/imgpkg/docs/latest/resources/#imageslock-configuration)
- The OCI image can contain the file `.imgpkg/bundle.yml` with the content that is compatible with
  the [Bundle configuration](/imgpkg/docs/latest/resources/#bundle-configuration)
- The OCI image can contain other arbitrary files

Now that we know what defines a bundle what does it mean to "push a bundle to a registry"?

In broad strokes it just means to create an OCI image from your filesystem in a particular repository in your registry.

Let us see `imgpkg` in action:

```bash
$ imgpkg push -b localhost:5000/cool-new-bundle:my-tag -f examples/basic-step-2
dir: .
dir: .imgpkg
file: .imgpkg/bundle.yml
file: .imgpkg/images.yml
file: config.yml
Pushed 'localhost:5000/cool-new-bundle@sha256:5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511'
Succeeded
```

**Note:** we are using the examples provided in
the [`imgpkg` Github repository](https://github.com/carvel-dev/imgpkg)

In this output you can see that `imgpkg` lists all the files that will be pushed to the registry as well has the fully
qualified image reference for the OCI image created.

One thing that you might notice is that despite the fact that this bundle points to another OCI
image, [check the ImagesLock file](https://github.com/carvel-dev/imgpkg/blob/develop/examples/basic-step-2/.imgpkg/images.yml)
, nothing happens to it.

But why? As we previously stated, pushing a bundle to a registry only creates the OCI image that defines the bundle.

## Copying a bundle to a different registry

Having a bundle in a particular registry might not be good enough, and we might need to promote our software to
a different registry, or even copy this bundle to a public registry so that other people can use the software being
developed.

One of the most awesome features of the `imgpkg` bundles is that despite the fact that bundles are just OCI images that
contain some metadata they also can aggregate other OCI images. Let us look at the prior bundle, when we check the
ImagesLock file we can see that it contains a reference to a different OCI
image `index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0`

```bash
$ cat examples/basic-step-2/.imgpkg/images.yml
apiVersion: imgpkg.carvel.dev/v1alpha1
kind: ImagesLock
images:
- image: index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
  annotations:
    kbld.carvel.dev/id: docker.io/dkalinin/k8s-simple-app
```

So whenever we are copying a bundle, `imgpkg` does the leg work and copies all the images or bundles that are referenced
by the bundle being copied. This way with a single command you can copy all the OCI images associated with the bundle to
the destination. Let us see `imgpkg` in action

```bash
$ imgpkg copy -b localhost:5000/cool-new-bundle:my-tag --to-repo my-company.repo.io:5000/destination-repo
copy | exporting 2 images...
copy | will export index.docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
copy | will export localhost:5000/cool-new-bundle@sha256:5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511
copy | exported 2 images
copy | importing 2 images...

 
copy | done uploading images

Succeeded
```

From the output we can see that 2 OCI images were copied, the bundle image and the image that is in the ImagesLock.

When we copied we only provided one destination Repository and `imgpkg` will copy all the OCI images into that
repository. This was a design decision that was made due to the following constraints:

- Multiple images that have the same Image Name but are not the same. Assuming we have 2 bundles one that contains the
  image `my.registry.io/controller@sha256:aaaa` and another that contains the image `other.registry.io/controller@sha256:bbbb`, when we copy both images to the registry third.registry.io they would be copied to
  `third.registry.io/controller@sha256:aaaa` and `third.registry.io/controller@sha256:bbbb` respectively. This can confuse
  because even though now they share the same repository they are completely different Images from 2 completely
  different Source Codes. This might cause problems for registry Administrators when they try to understand what each
  Repository contains.
- Finding if an image is already present in the destination repository is complicated.
- Registries like gcr.io support paths in their repositories while `hub.docker.io` does not. Copying an OCI image from
  `gcr.io/my/specific/path/controller@sha256:aaaa` to `index.docker.io` is a challenge because we would lose information
  about the original OCI image that can be significant.
- Copying OCI images to different repositories can require different user or authentication. When copying an OCI image
  to a particular Repository the user needs to have credentials to do so, in a scenario where the repository
  `my.registry.io/controller` was previously created by a different user, the current user might not have permission to
  copy the new OCI image to that particular repository.
- ECR requires users to create a repository before pushing OCI
  images. [reference](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)

The design decision tries to address the above constraints but causes some other problems:

- Trackable OCI image, hard to understand what each OCI image is for, and what bundle is it part of

  There are 2 initiatives that are trying to address this problem.
    - A new feature is being developed to allow the users to tell `imgpkg` to generate tags that are more human
      friendly, [Github Issue](https://github.com/carvel-dev/imgpkg/issues/331)
    - A proposal was started to allow the users to tell `imgpkg` where to copy the OCI images to. This proposal is still
      being written, and we would love to have the community to read it and give their opinion about it. The initial
      draft can be found [here](https://github.com/carvel-dev/community/pull/22).
- Some registries restrict the number of OCI images that can be present in each
  repository, [reference 1](https://docs.aws.amazon.com/AmazonECR/latest/userguide/service-quotas.html)
  , [reference 2](https://www.jfrog.com/confluence/display/JFROG/Docker+Registry#DockerRegistry-LocalDockerRepositories)

  For this particular problem there is not much that `imgpkg` can do at this point in time.

## What about tags?

Let us look at the Tags present in the Repository we pushed our bundle to

```bash
$ imgpkg tag list -i localhost:5000/cool-new-bundle
Tags

Name
my-tag
sha256-5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511.imgpkg

2 tags

Succeeded

$ crane digest localhost:5000/cool-new-bundle:my-tag
sha256:5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511

$ crane digest localhost:5000/cool-new-bundle:sha256-5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511.imgpkg
sha256:5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511
```

There are 2 tags and both point the same Digest. If we look at the command we used to push the
bundle `imgpkg push -b localhost:5000/cool-new-bundle:my-tag -f examples/basic-step-2` we defined a tag to be used.
Also `imgpkg` automatically creates a tag that contains the digest and the `.imgpkg` suffix. The main reason for this
Tag is to ensure that if in the future we want to move the tag `my-tag` to a different bundle, it can be done and the
garbage collector of the registry would not remove this OCI image because of the lack of Tag point to it.

Let us look at the tags present in the repository we copied the bundle into

```bash
$ imgpkg tag list -i my-company.repo.io:5000/destination-repo --registry-insecure
Tags

Name
my-tag
sha256-4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0.imgpkg
sha256-510482df49db421542ae10142e8ce99572b23ef72675c37e92e4a12b541a3f6a.imgpkg
sha256-5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511.image-locations.imgpkg
sha256-5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511.imgpkg

5 tags

Succeeded
```

These are a lot of tags, lets drill down each one to understand what they are:

- `my-tag` original tag we copied from
- `sha256-5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511.imgpkg` This tag points to the bundle
- `sha256-4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0.imgpkg` Based on the digest this will point
  to the OCI image that is part of the bundle
- `sha256-510482df49db421542ae10142e8ce99572b23ef72675c37e92e4a12b541a3f6a.imgpkg` Tag points to the Locations OCI
  image
- `sha256-5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511.image-locations.imgpkg` This is a new OCI
  image that is created by `imgpkg` to store the location of the OCI images that are part of the bundle. The main reason
  to create this tag is to allow `imgpkg` to later reference and use this OCI image when copying the bundles between registries.

## The end

As a summary of what we talked about in this blog post

bundles are OCI images that hold arbitrary files and references to other dependent OCI images. This feature makes it easy
to package and distribute your software.

`imgpkg` enables the users with a single command to move all the OCI images associated with a bundle to the destination

`imgpkg` creates tags for different purposes on the destination repository

## Join the Carvel Community

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/carvel-dev/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.
