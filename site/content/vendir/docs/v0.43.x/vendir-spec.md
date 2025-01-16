---
aliases: [/vendir/docs/latest/vendir-spec]
title: vendir.yml spec
---

```yaml
apiVersion: vendir.k14s.io/v1alpha1
kind: Config

# declaration of minimum required vendir binary version (optional)
minimumRequiredVersion: 0.8.0

# one or more directories to manage with vendir
directories:
- # path is relative to `vendir` CLI working directory
  path: config/_ytt_lib

  # set the permissions for this directory (optional; v0.33.0+)
  # by default directories will be created with 0700
  # can be provided as octal, in which case it needs to be prefixed with a `0`
  permissions: 0700

  contents:
  - # path lives relative to directory path # (required)
    path: github.com/cloudfoundry/cf-k8s-networking

    # skip fetching if the config for this path has not changed since the last sync
    # optional, `false` by default, available since v0.36.0
    # use `vendir sync --lazy=false` to forcefully sync when needed
    lazy: true

    # uses git to clone Git repository (optional)
    git:
      # http or ssh urls are supported (required)
      url: https://github.com/cloudfoundry/cf-k8s-networking
      # branch, tag, commit; origin is the name of the remote (required)
      # optional if refSelection is specified (available in v0.11.0+)
      ref: origin/master
      # depth of commits to fetch; 0 (default) means everything (optional; v0.29.0+)
      depth: 1
      # specifies a strategy to resolve to an explicit ref (optional; v0.11.0+)
      refSelection:
        semver:
          # list of semver constraints (see versions.md for details) (required)
          constraints: ">0.4.0"
          # by default prerelease versions are not included (optional; v0.12.0+)
          prereleases:
            # select prerelease versions that include given identifiers (optional; v0.12.0+)
            identifiers: [beta, rc]
      # skip downloading lfs files (optional)
      lfsSkipSmudge: false
      # skip SSL/TLS verification (optional)
      dangerousSkipTLSVerify: false
      # skip initializing any git submodules (optional; v0.28.0+)
      skipInitSubmodules: false
      # verify gpg signatures on commits or tags (optional; v0.12.0+)
      verification:
        publicKeysSecretRef:
          name: my-git-gpg-auth
      # specifies name of a secret with auth details;
      # secret may include 'ssh-privatekey', 'ssh-knownhosts',
      # 'username', 'password' keys (optional)
      secretRef:
        # (required)
        name: my-git-auth
      # when this flag set to true it will set the Basic Auth header directly
      # in git configuration to ensure that it does not try to use NTLM
      forceHTTPBasicAuth: false

    # uses hg to clone Mercurial repository (optional; v0.22.0+)
    hg:
      # http or ssh urls are supported (required)
      url: https://hg.sr.ht/~sircmpwn/hg.sr.ht
      # branch, tag, commit (required)
      ref: 180c776fe29448afa8c756ab572bab7a1cf17a06
      # specifies name of a secret with auth details;
      # secret may include 'ssh-privatekey', 'ssh-knownhosts',
      # 'username', 'password' keys (optional)
      secretRef:
        # (required)
        name: my-hg-auth

    # fetches asset over HTTP (optional)
    http:
      # asset URL (required)
      url: 
      # verification checksum (optional)
      sha256: ""
      # specifies name of a secret with basic auth details;
      # secret may include 'username', 'password' keys (optional)
      secretRef:
        # (required)
        name: my-http-auth
      # skip unpacking tar, tgz, and zip files; by default files are unpacked (optional)
      disableUnpack: false

    # fetches asset from an image registry (optional; v0.11.0+)
    image:
      # image URL; could be plain, tagged or digest reference (required)
      url: gcr.io/repo/image:v1.0.0
      # specifies a strategy to choose a tag (optional; v0.22.0+)
      # if specified, do not include a tag in url key
      tagSelection:
        semver:
          # list of semver constraints (see versions.md for details) (required)
          constraints: ">0.4.0"
          # by default prerelease versions are not included (optional; v0.12.0+)
          prereleases:
            # select prerelease versions that include given identifiers (optional; v0.12.0+)
            identifiers: [beta, rc]
      # specifies name of a secret with registry auth details;
      # secret may include 'username', 'password' and/or 'token' keys;
      # as of v0.19.0+, dockerconfigjson secrets are also supported (optional)
      # of of v0.22.0+, multiple registry credentials are supported and
      #   are passed to imgpkg via env. registry hostname must match url
      #   for auth information to be chosen by imgpkg.
      #   (https://carvel.dev/imgpkg/docs/latest/auth/#via-environment-variables)
      secretRef:
        # (required)
        name: my-image-auth
      # specify wether to skip TLS verification; defaults to false (optional;v0.18.0+)
      dangerousSkipTLSVerify: false
      # specify the response timeout in seconds for imgpkg when querying the registry; defaults to 30 (optional; v0.40.0+)
      responseHeaderTimeout: 30

    # fetches imgpkg bundle from an image registry (optional; v0.16.0+)
    imgpkgBundle:
      # could be plain, tagged or digest reference (required)
      image: gcr.io/repo/bundle:v1.0.0
      # specifies a strategy to choose a tag (optional; v0.22.0+)
      # if specified, do not include a tag in image key
      tagSelection:
        semver:
          # list of semver constraints (see versions.md for details) (required)
          constraints: ">0.4.0"
          # by default prerelease versions are not included (optional; v0.12.0+)
          prereleases:
            # select prerelease versions that include given identifiers (optional; v0.12.0+)
            identifiers: [beta, rc]
      # specifies name of a secret with registry auth details;
      # secret may include 'username', 'password' and/or 'token' keys;
      # as of v0.19.0+, dockerconfigjson secrets are also supported (optional)
      # of of v0.22.0+, multiple registry credentials are supported and
      #   are passed to imgpkg via env. registry hostname must match image
      #   for auth information to be chosen by imgpkg.
      #   (https://carvel.dev/imgpkg/docs/latest/auth/#via-environment-variables)
      secretRef:
        # (required)
        name: my-image-auth
      # specify wether to skip TLS verification; defaults to false (optional;v0.18.0+)
      dangerousSkipTLSVerify: false
      # specify the response timeout in seconds for imgpkg when querying the registry; defaults to 30 (optional; v0.40.0+)
      responseHeaderTimeout: 30
      # paths to PEM files containing additional CA certificates required to securely connect to registries
      additionalCACertificates: []

    # fetches assets from a github release (optional)
    githubRelease:
      # slug for repository (org/repo) (required)
      slug: k14s/kapp-controller
      # use release tag (optional)
      # optional if tagSelection is specified (available in v0.22.0+)
      tag: v0.1.0
      # specifies a strategy to choose a tag (optional; v0.22.0+)
      tagSelection:
        semver:
          # list of semver constraints (see versions.md for details) (required)
          constraints: ">0.4.0"
          # by default prerelease versions are not included (optional; v0.12.0+)
          prereleases:
            # select prerelease versions that include given identifiers (optional; v0.12.0+)
            identifiers: [beta, rc]
      # use latest published version (optional)
      latest: true
      # use exact release URL (optional)
      url: https://api.github.com/repos/k14s/kapp-controller/releases/21912613
      # only download specific assets (optional; v0.12.0+)
      assetNames: ["release*.yml"]
      # checksums for downloaded files (optional)
      # (if release text body contains checksums, it's not necessary
      # to manually specify them here)
      checksums:
        release.yml: 26bf09c42d72ae448af3d1ee9f6a933c87c4ec81d04d37b30e1b6a339f5983a7
      # disables checking auto-found checksums for downloaded files (optional)
      # (checksums are extracted from release's text body
      # based on following format `<sha256>  <filename>`)
      disableAutoChecksumValidation: true
      # specifies which archive to unpack for contents (optional)
      unpackArchive:
        # (required)
        path: release.tgz
      # specifies name of a secret with github auth details;
      # secret may include 'token' key (optional)
      secretRef:
        # (required)
        name: my-gh-auth
      # Used to create the URL of the asset to download the metadata
      # from the Github Release. (optional)
      http:
        # The url parameter of http can interpolate the tag of the GitHub release using the {tag} token.
        url: https://dl.k8s.io/release/{tag}/bin/linux/amd64/kubectl

    # fetch Helm chart contents (optional; v0.11.0+)
    helmChart:
      # chart name (required)
      name: stable/redis
      # use specific chart version (string; optional)
      version: "1.2.1"
      # specifies Helm repository to fetch from (optional)
      repository:
        # repository url; supports exprimental oci helm fetch via
        # oci:// scheme (required)
        url: https://...
        # specifies name of a secret with helm repo auth details;
        # secret may include 'username', 'password';
        # as of v0.19.0+, dockerconfigjson secrets are also supported (optional)
        # as of v0.22.0+, 0 or 1 auth credential is expected within dockerconfigjson secret
        #   if >1 auth creds found, error will be returned. (currently registry hostname
        #   is not used when found in provide auth credential.)
        secretRef:
          # (required)
          name: my-helm-auth
      # specify helm binary version to use;
      # '3' means binary 'helm3' needs to be on the path (optional)
      helmVersion: "3"

    # copy contents from local directory (optional)
    directory:
      # local file system path relative to vendir.yml
      path: some-path

    # states that directory specified by above path
    # is managed by hand; nothing to do for vendir (optional)
    manual: {}

    # specify contents inline within this file (optional; v0.11.0+)
    inline:
      # specifies mapping of paths to their content (optional)
      paths:
        dir/file.ext: file-content
      # specifies content via secrets and config maps (optional)
      pathsFrom:
      - secretRef:
          # (required)
          name: secret-name
          # specifies where to place files found in secret (optional)
          directoryPath: dir
      - configMapRef:
          # (required)
          name: cfgmap-name
          # specifies where to place files found in config map (optional)
          directoryPath: dir

    # includes paths specify what should be included. by default
    # all paths are included (optional)
    includePaths:
    - cfroutesync/crds/**/*
    - install/ytt/networking/**/*

    # exclude paths are "placed" on top of include paths (optional)
    excludePaths: []

    # specifies paths to files that need to be includes for
    # legal reasons such as LICENSE file. Defaults to few 
    # LICENSE, NOTICE and COPYRIGHT variations (optional)
    legalPaths: []

    # make subdirectory to be new root path within this asset (optional; v0.11.0+)
    newRootPath: cfroutesync

    # set the permissions for this content directory (optional; v0.33.0+)
    # by default content directories will be created with 0700
    # can be provided as octal, in which case it needs to be prefixed with a `0`
    permissions: 0700
```
