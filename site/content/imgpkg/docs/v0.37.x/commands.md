---
aliases: [/imgpkg/docs/latest/commands]
title: Commands
---

## Push

### Overview

`push` command allows users to create a bundle in the registry from files and/or directories on their local file systems. For example,

```bash-plain
$ imgpkg push -b index.docker.io/k8slt/sample-bundle -f my-bundle/
```

will push a bundle contents containing in the `my-bundle/` directory to `index.docker.io/k8slt/sample-bundle`.

Use the `-b`/`--bundle` flag to specify the destination of the push. If the specified destination does not include a tag, the artifact will be pushed with the default tag `:latest`.

The `-f` flag can be used multiple times to add different files or directories to the bundle.

Use the flag `--preserve-permissions=true` to preserve the current permission of the files of the image or bundle being pushed. If this flag is not present `imgpkg` will remove the Group and All permissions before uploading the image, when pull is done `imgpkg` will try to copy the User permissions to Group and All, respecting umask

### Generating a BundleLock

`push` command can output a [`BundleLock` configuration](resources.md#bundlelock-configuration) for users that would like a deterministic reference to a pushed bundle. For example, running:

```bash-plain
$ impgpkg push -b index.docker.io/k8slt/sample-bundle:v0.1.0 -f my-bundle/ --lock-output
/tmp/bundle.lock.yml
```

will create `/tmp/bundle.lock.yml` with BundleLock configuration. If another bundle image in the repository is later given the same tag (`v0.1.0`), the BundleLock configuration will continue to provide immutable reference (via digest) to the original pushed bundle.

---
## Pull

### Overview

After pushing bundles to a registry, users can retrieve them with `imgpkg pull`. For example,

```bash-plain
$ imgpkg pull -b index.docker.io/k8slt/sample-bundle -o my-bundle/
```

will pull a bundle from `index.docker.io/k8slt/sample-bundle` and extract its contents into the `my-bundle/` directory, which gets created if it does not already exist.

When pulling a bundle, imgpkg ensures that the referenced images are updated to account for any relocations. It will search for each referenced image by digest in the same repository as the bundle. If all referenced digests are found, imgpkg will update image references in the bundle's [`.imgpkg/images.yml` file](resources.md#imgpkg-directory). If any of the digests are not found in the repository, imgpkg will not update any references.

### Pulling via lock file

[BundleLock configuration](resources.md#bundlelock-configuration) can be used as input to the pull command via the `--lock` flag.

```bash-plain
$ imgpkg pull --lock bundle.lock.yml -o my-bundle/
```

### Pulling nested bundles

If pulling a bundle that references another bundle (via it's ImagesLock file), in order to *also* pull down the contents of every nested bundle, use the `--recursive` flag.  

```bash-plain
$ imgpkg pull --recursive -b bundle-with-nested-bundles
```

Contents of *every* nested bundle are written to the 'parent' bundle's `.imgpkg/bundles` directory, namespaced by the bundle's sha256.

For e.g. pulling a bundle with a nested bundle having sha of `123` would result in:
```
parent-bundle-path/.imgpkg/bundles/sha256-123/<nested bundle 123 contents written here>
```

---
## Copy

### Overview

The `copy` command copies a bundle from a registry to another registry (as long as both registries are accessible from where the command is running):

```bash-plain
$ imgpkg copy -b index.docker.io/k8slt/sample-bundle --to-repo registry.corp.com/user2/sample-bundle-name
```

Alternatively `copy` can copy a bundle between registries which are not both accessible from a single location, by creating an intermediate tarball:

```bash-plain
$ imgpkg copy -b index.docker.io/k8slt/sample-bundle --to-tar=/Volumes/secure-thumb/bundle.tar
# ... take thumb driver to a different location ...
$ imgpkg copy --tar=/Volumes/secure-thumb/bundle.tar --to-repo registry.corp.com/user2/sample-bundle-name
```

In either case, the bundle image and all dependent images are copied to the destination location `registry.corp.com/user2/sample-bundle-name`.

**Note:** To generate tags that provide information on the origin of the images use the flag `--repo-based-tags`


### Resume copy of image or bundle to tar

If the copy to tar was interrupted by a network problem it can be resumed by providing the flag `--resume` to the `copy` command

```bash-plain
$ imgpkg copy -b index.docker.io/k8slt/sample-bundle --to-tar=/Volumes/secure-thumb/bundle.tar --resume
```

### Copying via lock file

[BundleLock configuration](resources.md#bundlelock-configuration) can be used as input to the copy command via the `--lock` flag.

```bash-plain
$ imgpkg copy --lock bundle.lock.yml --to-repo registry.corp.com/user2/sample-bundle-name --lock-output /tmp/new-bundle.lock.yml
```

### Non-Distributable or Foreign Layers

Some images contain layers which should not be uploaded when copying, such as a proprietary base image.
Instead, to comply with license requirements, it is expected to get them directly from the source registry.
These layers are interchangeably known as
[Non-Distributable](https://github.com/opencontainers/image-spec/blob/79b036d80240ae530a8de15e1d21c7ab9292c693/layer.md#non-distributable-layers)
(by the OCI) or
[Foreign](https://docs.docker.com/registry/spec/manifest-v2-2/) (by Docker) and denoted in the layer's MediaType.

By default, imgpkg will not relocate any layers marked as non-distributable.

This can cause issues when dealing with [air-gapped environments](air-gapped-workflow.md) as they may be unable to reach the external registries.
To allow this use case, imgpkg supports the `--include-non-distributable-layers` flag to copy all layers, even those marked as non-distributable.

Note that usage of this flag shall not preclude your obligation to comply with the terms of the image license(s).

### Image Signatures

`imgpkg` can copy Signature created by [cosign](https://github.com/sigstore/cosign). By
default `imgpkg` will not search for Signatures for Images. To enable the search and copy of the signatures the
flag `--cosign-signatures` needs to be provided to copy command

```bash-plain
$ imgpkg copy -b index.docker.io/k8slt/sample-bundle --to-repo some.repo.io/some-bundle --cosign-signatures
```

This feature will work while copying to a different repository as well as copying to a tarball.

---

## Tag

`imgpkg tag` supports a `list` subcommand that allows users to list the image tags pushed to registries. The command features an `--image`/`-i` option that allows a user to specify an image name. 

An example of this is shown below:

```bash-plain
$ imgpkg tag list -i index.docker.io/k8slt/image
```

The output shows the names of all non-imgpkg internal tags associated with the image.

Additionally, you can request to see the tag digests or all tags, to include the imgpkg internally generated tags, using the following flags.

```bash-plain
$ imgpkg tag list --digests -i index.docker.io/k8slt/image
$ imgpkg tag list --imgpkg-internal-tags -i index.docker.io/k8slt/image
```

---

## Describe

`imgpkg describe` Provides a summary of all the images that are part of the provided Bundle.

An example of this is shown below:

```bash-plain
$ imgpkg describe -b carvel.dev/app1-bundle
```

This command provides 2 different types of output, `yaml` and `text`, that can be selected via the flag `--output-type`.
By default `text` is selected.

The flag `--cosign-artifacts` provides the user the ability to select if they want or not `imgpkg` to check and display
any [cosign](https://github.com/sigstore/cosign) artifact that is part of the Bundle.
