---
title: File Marks
---

## Overview

ytt allows to control certain metadata about files via `--file-mark` flag.

```
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
  --output-directory ../../tmp/
```

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

__

### exclude

Exclude file from any kind of processing. 

```
--file-mark '<path>:exclude=true'
```

__

### type

Change type of file, affecting how `ytt` processes it. 

```
--file-mark '<path>:type=<file-type>'
```

By default `file-type` is determined based on file extension. 

`file-type` can be: 
- `yaml-template` (ext: `.yml`) — parsed as a YAML document containing `ytt` templating.
- `yaml-plain` — parsed as a simple YAML document (not processed for templating).
- `text-template` (ext: `.txt`) — parsed as a text document containing text templating.
- `text-plain` — plain text (included in output, as is)
- `starlark` (ext: `.star`) — a Starlark source file (executed)
- `data` — a text file that can be loaded by [`data.read()`](lang-ref-ytt.md#data)
 
Example:

```
--file-mark 'config.yml:type=data'
```

indicates that `config.yml` is _not_ a `yaml-template`, but is `data`. This file will _not_
be included in the output, but can be loaded using [`data.read()`](lang-ref-ytt.md#data).

__

### for-output

Marks a file that is not part of output by default, to be included.

```
--file-mark '<path>:for-output=true'
```

Example
```
--file-mark 'config.lib.yml:for-output=true'
```

By default, `.lib.yml` files are not included in the rendered output (they are loaded
by other templates).  With this file mark, `config.lib.yml` _is_ included in the output.

__

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


