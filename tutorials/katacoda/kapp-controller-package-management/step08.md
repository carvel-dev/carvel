## Creating a Package Repository

A [package repository bundle](https://carvel.dev/kapp-controller/docs/latest/packaging/#package-repository-bundle-format)
is a collection of packages (more specifically a collection of Package and PackageMetadata CRs).
Currently, our recommended way to make a package repository is via an [imgpkg bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle).

The [PackageRepository bundle format](https://carvel.dev/kapp-controller/docs/latest/packaging/#package-repository-bundle-format) describes purpose of each directory and general recommendations.

Lets start by creating the needed directories:

`mkdir -p my-pkg-repo/.imgpkg my-pkg-repo/packages/simple-app.corp.com`{{execute}}

we can copy our CR YAMLs from the previous step in to the proper packages
subdirectory:

```
cp 1.0.0.yml my-pkg-repo/packages/simple-app.corp.com
cp metadata.yml my-pkg-repo/packages/simple-app.corp.com
```{{execute}}

Next, let’s use kbld to record which package bundles are used:

`kbld -f my-pkg-repo/packages/ --imgpkg-lock-output my-pkg-repo/.imgpkg/images.yml`{{execute}}

With the bundle metadata files present, we can push our bundle to whatever OCI
registry we plan to distribute it from, which for this tutorial will just be our
same REPO_HOST.

`imgpkg push -b ${REPO_HOST}/packages/my-pkg-repo:1.0.0 -f my-pkg-repo`{{execute}}

The package repository is pushed!

You can verify by checking the Docker registry catalog:

`curl ${REPO_HOST}/v2/_catalog`{{execute}}

In the next steps we'll act as the package consumer, showing an example of adding and using a PackageRepository with kapp-controller.

