# Bundles

- Status: Being written | **Being implemented** | Included in release | Rejected

# Summary

Support creating, relocating, and pulling images.
# Concepts

## Bundle

A bundle abstracts away the difference between configuration and the images
referenced by it. This abstraction allows people to treat both their config
and the images it depends on as a single artifact, removing the overhead
associated with operations such as relocation.

Bundles are simply images stored in a registry. They include:

- bundle metadata (e.g. name, authors)
- bundle contents - a set of files (e.g. kubernetes manifests)
- list of image references that are considered to be part of a bundle (can be
  empty, but must be present)

Key constraint: bundle image must always retain its digest when copied around.

# Resources

## Bundle Directory

```yaml
my-app/
  .imgpkg/         <-- .imgpkg is what makes this a bundle and a max of 1 can be provided to imgpkg push
    bundle.yml   <-- describes bundle contents and misc info
    images.yml   <-- list of referenced images in this bundle
  contents/      <-- configuration files or directories referencing images in images.yml; but could be anything
```

## Bundle YAML

The Bundle YAML file is meant to contain metadata associated with the bundle. In
the future, the intention is to expand this file to contain a `paths` key which
will allow users to specify paths that are included in the bundle.

```yaml
apiVersion: imgpkg.k14s.io/v1alpha1
kind: Bundle
metadata:
  name: my-app
authors:
- name: blah
  email: blah@blah.com
websites:
- url: blah.com
```

## BundleLock

A BundleLock file serves as a deterministic reference to a bundle. It will
contain the original tag, as well as a url that references the bundle image by digest.

```yaml
apiVersion: imgpkg.k14s.io/v1alpha1
kind: BundleLock
spec:
  image:
    url: docker.io/my-app@sha256:<digest>
    tag: v1.0
```

## ImagesLock

An ImagesLock file acts as a way to reference multiple images deterministically.
When included in a bundle image, it will cause imgpkg to relocate all referenced
images along with the bundle image during a copy. Users are also able to
provide just an ImagesLock file when copying to support relocation of multiple
generic images. Initially, the ImagesLock file should only contain references to
generic images, but in the future we plan to allow it to reference bundles,
enabling users to recursively relocate bundles or relocate a list of bundles.

```yaml
apiVersion: imgpkg.k14s.io/v1alpha1
kind: ImagesLock
spec:
  images:
  - image: docker.io/my-app@sha256:<digest>
    annotations: # <--------- This field is to be populated by other tools
      <image metadata>
  - image: docker.io/another-app@sha256:<digest>
    annotations:
      <image metadata>
```

Note: imgpkg will require all images to be in digest reference form

---
# Initial Commands

## imgpkg push ( Create a bundle or config image)

This command will package a section of the local file system in to an OCI
image and push it to the specified image repository. The push command will be
able to push two types of images, a bundle and a generic image. The presence of
a `.imgpkg` directory as a direct child of one of the arguments to `-f` will
cause imgpkg to label the image's config, denoting it is a bundle. If the imgpkg
directory is in any other location, if there are multiple `.imgpkg` directories, or
if a `.imgpkg` exists when a `-i` flag was used, `imgpkg push` will error.

In the near future, we would like to allow users to push a bundle using the `-b`
flag, even if a `.imgpkg` directory does not exist, by automatically creating an
empty one.

Flags:
* `-f` - bundle directory to create bundle from # Can be used multiple times
* `-b, --bundle` - reference to push bundle to
* `--lock-output` - location to write a BundleLock file to

Examples:
- `imgpkg push -f ... -b docker.io/klt/foo:v123 # simple case; just pack up dir and push`
- `imgpkg push -f ... -b docker.io/klt/foo:v123 --lock-output bundle.lock.yml # with BundleLock output`
- `imgpkg push -f ... -b docker.io/klt/foo --lock-output bundle.lock.yml # tag gets auto-incremented?`

Notes:
* Adds Label to image config to denote it is a bundle
* Requires `.imgpkg` directory to push a bundle
* If present, requires `.imgpkg` to:
  * be a direct child of an argument to `-f`
  * be a singleton
  * contain an images.yml file

---
## imgpkg pull ( Download and unpack the contents of a bundle to your local filesystem )

Flags:
* `-o` - location to unpack the bundle directory
* `-b` - reference to the bundle to unpack
* `--lock` - BundleLock with a reference to a bundle to unpack (Error is ImagesLock?)
* `--image` - An image to unpack

Examples:
- `imgpkg pull -o /tmp -b foo:v123`
- `imgpkg pull -o /tmp --lock bundle.lock.yml`
- `imgpkg pull -o /tmp -b foo:v123@digest`
- `imgpkg pull -o /tmp -b foo@digest`
- `imgpkg pull -o /tmp --image foov123`

Notes:
* Will rewrite bundle's images.lock.yml if images are in same repo as bundle
    * can be determined by a get to the repo with the digest

---
## imgpkg copy ( Copy bundles and images to various locations )

Copy is responsible for relocating artifacts. It is able to consume a variety of
inputs and copy all required images to either an image repository or a tar file
on the local filesystem. When relocating bundles, imgpkg will also relocate any
images references by the bundle's ImagesLock file.

Flags:
* `--bundle` - the bundle reference we are copying (happens thickly, i.e. bundle image + all referenced images)
* `--from-tar` - Tar file which contains assets to be copied to a registry
* `--lock` - either an ImageLock file or BundleLock file with asset references to copy to destination
* `--image` - image reference for copying generic images
* `--to-repo` - the location to upload assets
* `--to-tar` - location to write a tar file containing assets
* `--to-tag` - the tag to upload with (if not present either existing tag will be used or random will be generated)
* `--lock-output` - location to output updated lockfile. If BundleLock in, BundleLock out. If ImagesLock in, ImagesLock out.

Examples:
- `imgpkg copy --bundle docker.io/foo:v123 --to-repo gcr.io/foo # repo to repo thick copy without outputting an update lockfile`
- `imgpkg copy --bundle docker.io/foo:v123 --to-repo gcr.io/foo --lock-output bundle.lock.yml --to-tag v124 # repo to repo copy with updated lock output and tag override`
- `imgpkg copy --bundle docker.io/foo:v123 --to-tar foo.tar # write bundle contents (thickly) to a tar on the local file system`
- `imgpkg copy --from-tar foo.tar --to-repo gcr.io/foo # upload bundle assets from foo.tar to remote repo foo`
- `imgpkg copy --lock bundle.lock.yml      --to-repo gcr.io/foo --lock-output bundle.lock.yml # thickly copy the bundle referenced by bundle.lock.yml to the repo foo (tags will be preserved)`
- `imgpkg copy --image docker.io/foo:v123  --to-repo gcr.io/foo # relocate a generic image to the foo repo -- Do we want to preserve tags? It could result in collisions`

Notes:
* Source lock file may contain bundle or images lock contents

---
# Potential Extensions

## imgpkg list ( list bundles in a repo or registry )

---
## imgpkg init ( initialize a directory with the bundle format )

---
# Use Cases

See [workflow](workflow.md) for an example E2E workflow.

## Use Case: No relocate bundle consumption

Developer wants to provide a no-surprises install of a "K8s-native" app, leveraging a number of publicly available images.

"no-surprises" means:

* by simple inspection, user knows all images that will be used;
* user knows the exact version of each image (i.e. version tag and digest);

### Bundle creator:
1. Create a bundle directory
2. `imgpkg push -f <bundle-directory> -b docker.io/klt/some-bundle:1.0.0`

### Bundle consumer:
1. `imgpkg pull -b docker.io/klt/some-bundle:1.0.0`
2. `ytt -f contents/ | kbld -f ./.imgpkg/images.yml | kapp deploy -a some-bundle -f-`

**Notes:**
* Producer could distribute a BundleLock file to give consumers a stronger
  guarantee the tag is the correct bundle

---
## Use Case: Thickly Relocated Bundles

### Bundle creator:
Same as above

### Bundle consumer:
1. `imgpkg copy --bundle docker.io/klt/some-bundle:1.0.0 --to-repo internal.reg/some-bundle` (or using --bundle + --to-tar and --tar + --to-repo for air-gapped environments, but outcome is the same)
2. `imgpkg pull -b internal.reg/some-bundle:1.0.0`
3. `ytt -f contents | kbld -f ./.imgpkg/images.yml | kapp deploy -a some-bundle -f-`

---
## Use Case: Generic Relocation

### A Single Image
1. `imgpkg copy --image gcr.io/my-image --to-repo docker.io/klt --lock-output image.lock.yml`

or

### Multiple Images
1. `imgpkg copy --lock images.lock.yml --to-repo docker.io/klt --lock-output relocated-images.lock.yml`
