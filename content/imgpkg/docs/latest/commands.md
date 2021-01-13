---
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

### Copying via lock file

[BundleLock configuration](resources.md#bundlelock-configuration) can be used as input to the copy command via the `--lock` flag.

```bash-plain
$ imgpkg copy --lock bundle.lock.yml --to-repo registry.corp.com/user2/sample-bundle-name --lock-output /tmp/new-bundle.lock.yml
```

---
## Tag

`imgpkg tag` supports a `list` subcommand that allows users to list the image tags pushed to registries. The command features an `--image`/`-i` option that allows a user to specify an image name. 

An example of this is shown below:

```bash-plain
$ imgpkg tag list -i index.docker.io/k8slt/image
```

The output shows the names of all tags associated with the image, along with its digest.
