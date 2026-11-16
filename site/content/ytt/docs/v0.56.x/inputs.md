---
aliases: [/ytt/docs/latest/inputs]
title: Inputs
---

ytt supports different input sources:

- Files & Directories
  - Those are provided via the `-f`/`--file` flag

  - ytt uses the file's name for its internal representation

    If you have a tree like
    ```terminal
    $ tree .
    .
    ├── dir1
    │   └── some.yaml
    └── dir2
        └── sub
            ├── another.yaml
            └── someother.yaml

    4 directories, 3 files
    ```
    and you call `ytt --file dir1/some.yaml --file dir2/ ...` then ytt loads
    - `dir1/some.yaml` as `some.yaml`
    - `dir2/sub/another.yaml` as `sub/another.yaml`
    - `dir2/sub/someother.yaml` as `sub/someother.yaml`

  - ytt uses a file's extension to determine its type, e.g. a extension like
    `yaml` flags that file as "yaml-template"; you can read more about that in
    [File Marks](file-marks/)

  - You can change a file's name, location, and also "type" by explicitly
    setting the file's name to be used by ytt, e.g. `ytt --file
    a/different/file.foo=dir1/some.yaml`, which would mean that ytt

    - loads that file as `a/different/file.foo`
    - would not consider it as "yaml-template"/"yaml-plain", but as "data", because of its extension

    Note: this only works for files, not for directories

  - Explicitly setting file's names can be especially useful when consuming
    files where you have no control over their name, like process substitutions:

    Running `ytt --file <(echo 'some: yaml')` (on Linux) would have the shell
    produce a file like `/dev/fd/63` and pass that on to ytt. This file, based
    on it's name "63", would not be considered yaml and thus interpreted as
    "data". To change that, you need to run `ytt --file subst.yaml=<(echo 'some:
    yaml')` to have ytt treat it as yaml.

  - ytt can also consume stdin by using `-`, like: `ytt --file -`

    Note: When using `-`, ytt automatically treats data on stdin as yaml, as it
    will use stdin as `stdin.yaml`, thus having an extension which flags it as
    "yaml-template". If you use some other means to consume stdin, e.g. `ytt
    --file /dev/stdin`, this does not happen and ytt treats stdin as a file
    `stdin` and thus as "data", because it has no extension marking it
    differently. You can still set a different file name explicitly, e.g. with
    `ytt --file my-stdin.yaml=/dev/stdin`.

  - ytt can also consume files via http/s, e.g. `ytt --file
    https://raw.githubusercontent.com/carvel-dev/ytt/develop/.golangci.yml`

  - ytt can also consume symlinks, however if a symlink's target is not a file
    you have already included into the set of files ytt should consider
    (`--file ...`), ytt will not allow that and print an error. You can
    explicitly allow additional symlink targets via the
    `--allow-symlink-destination ...` flag.

  - To debug / inspect which files ytt considers and how it handles those, the
    flags `--files-inspect` & `--debug` can be helpful


- Data Values & Data Values Schemas

  You can read about how to define data-values schemas and how to consume and
  set Data Values and Schemas here:

  - [Write Schema](how-to-write-schema/)
  - [Data Values Schema](lang-ref-ytt-schema/)
  - [Use Data Values](how-to-use-data-values/)
  - [Data Values](ytt-data-values/)

  Generally you can provide Data Values
  - as strings
    - on the command line via the flags `--data-value`/`-v`
    - from the environment via the flag `--data-values-env`
    - from files via the flag `--data-value-file`
  - as structured data / yaml
    - on the command line via the flag `--data-value-yaml`
    - from the environment via the flag `--data-values-env-yaml`
    - from files via the flag `--data-values-file`
