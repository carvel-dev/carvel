---
aliases: [/ytt/docs/latest/file-marks]
title: File Marks
---

## Overview

ytt allows to control certain metadata about files via `--file-mark` flag.

```bash
$ ytt ... --file-mark <path>:<mark>=<value>
```

where:
- `path` — location to the file(s) being marked
    - exact path (use `--files-inspect` to see paths as seen by ytt)
    - path with `*` to match files in a directory
    - path with `**/*` to match files and directories recursively
- `mark` — metadata to modify on the file(s) selected by `path`
- `value` — the value for the mark

Note that this flag can be specified multiple times. 

Example: 

```bash
ytt -f . \
  --file-mark 'alt-example**/*:type=data' \
  --file-mark 'example**/*:type=data' \
  --file-mark 'generated.go.txt:exclusive-for-output=true' \
  --output-files ../../tmp/
```

---
## Available Marks

### path

Changes the relative path.

```
--file-mark '<path>:path=<new-path>'
```

Example: 

```
--file-mark 'generated.go.txt:path=gen.go.txt'
```

renames `generated.go.txt` to `gen.go.txt`

### exclude

Exclude file from any kind of processing. 

```
--file-mark '<path>:exclude=true'
```

### type

Change type of file, affecting how `ytt` processes it. 

```
--file-mark '<path>:type=<file-type>'
```

By default `file-type` is determined based on file extension and — as of v0.32.0 — content.

`file-type` can be: 
- `yaml-template` (default for: `.yml` or `.yaml`) — parsed as a YAML document and evaluated for templating.
- `yaml-plain` — parsed as a simple YAML document (_not_ evaluated for templating).
- `text-template` (default for: `.txt`) — parsed as a text document containing text templating.
- `text-plain` — included in output, as is.
- `starlark` (default for: `.star`) — a Starlark source file (executed)
- `data` (default for all other files) — a text file that can be loaded by [`data.read()`](lang-ref-ytt.md#data)

Example:

```
--file-mark 'config.yml:type=data'
```

indicates that `config.yml` is _not_ a `yaml-template`, but is `data`. This file will _not_ be parsed, evaluated, or included in the output, but _can_ be loaded using [`data.read()`](lang-ref-ytt.md#data).

#### type detection for YAML files
_(as of v0.32.0)_

First, `ytt` determines the type of each YAML file:
1. if it has a `.yml` or `.yaml` extension, it's assumed to be a `yaml-template`
2. if it is `yaml-template` but does not contain any ytt templating, it is treated as if it were `yaml-plain`
3. if it is marked with `type=yaml-plain`, it is treated as `yaml-plain`

and then processes each:
- `yaml-template` files are:
    1. parsed as YAML,
    2. evaluated (i.e. executes `ytt` the template), and
    3. linted (i.e. detects when non-ytt comments are included)
        - this catches errors where the `@` is accidentally omitted,
        - if the `--ignore-unknown-comments` flag is included, this "linting" is disabled.
- `yaml-plain` files are simply parsed as YAML (with no evaluation or linting).


### for-output

Marks a file to be included in the output.

Files of [type](#type) `yaml-template`, `yaml-plain`, `text-template`, and `text-plain` are part of the output by default.

```
--file-mark '<path>:for-output=true'
```

Example
```
--file-mark 'config.lib.yml:for-output=true'
```

By default, `.lib.yml` files are not included in the rendered output (they are loaded
by other templates).  With this file mark, `config.lib.yml` _is_ included in the output.

### exclusive-for-output

Limits output to only marked files.

If there is at least one file marked this way, only these files will be used in output. 

```
--file-mark '<path>:exclusive-for-output=true'
```

Example:
```
--file-mark 'config.lib.yml:exclusive-for-output=true'
```

Causes output to only include `config.lib.yml`.
