---

title: Sync command
---

## Overview

`vendir sync` command looks for [`vendir.yml`](vendir-spec.md) file in current directory for its configuration. `vendir.yml` specifies source of files for each managed directory.

```
# Run to sync directory contents as specified by vendir.yml
$ vendir sync
```

See [`vendir.yml` spec](vendir-spec.md) for its schema.

## Sync with local changes override

As of v0.7.0 you can use `--directory` flag to override contents of particular directories by pointing them to local directories. When this flag is specified other directories will not be synced (hence lock config is not going to be updated).

```
$ vendir sync --directory vendor/local-dir=local-dir-dev
```

## Sync with locks

`vendir sync` writes [`vendir.lock.yml`](vendir-lock-spec.md) (next to `vendir.yml`) that contains resolved references:

- for `git`, resolved SHAs are recorded
- for `hg`, resolved SHAs are recorded
- for `http`, nothing is recorded
- for `image`, resolved URL as a digest reference
- for `githubRelease`, permanent links are recorded
- for `helmChart`, resolved version
- for `directory`, nothing is recorded
- for `manual`, nothing is recorded

To use these resolved references on top of `vendir.yml`, use `vendir sync -l`.

## Syncing from different directory

As of v0.22.0, you can use `--chdir` flag with `vendir sync` command to change current working directory of vendir before any syncing occurs. All other paths provided to `vendir sync` should be relative to the changed directory.
