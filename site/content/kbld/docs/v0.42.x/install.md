---
aliases: [/kbld/docs/latest/install]
title: Install
---

## Via script (macOS or Linux)

(Note that `install.sh` script installs other Carvel tools as well.)

Install binaries into specific directory:

```bash
$ mkdir local-bin/
$ curl -L https://carvel.dev/install.sh | K14SIO_INSTALL_BIN_DIR=local-bin bash

$ export PATH=$PWD/local-bin/:$PATH
$ kbld version
```

Or system wide:

```bash
$ wget -O- https://carvel.dev/install.sh > install.sh

# Inspect install.sh before running...
$ sudo bash install.sh
$ kbld version
```

## Via Homebrew (macOS or Linux)

Based on [github.com/carvel-dev/homebrew](https://github.com/carvel-dev/homebrew).

```bash
$ brew tap carvel-dev/carvel
$ brew install kbld
$ kbld version
```

## Specific version from a GitHub release

To download, click on one of the assets in a [chosen GitHub release](https://github.com/carvel-dev/kbld/releases), for example for 'kbld-darwin-amd64'.

```bash
# **Compare binary checksum** against what's specified in the release notes
# (if checksums do not match, binary was not successfully downloaded)
$ shasum -a 256 ~/Downloads/kbld-darwin-amd64
08b25d21675fdc77d4281c9bb74b5b36710cc091f30552830604459512f5744c  /Users/pivotal/Downloads/kbld-darwin-amd64

# Move binary next to your other executables
$ mv ~/Downloads/kbld-darwin-amd64 /usr/local/bin/kbld

# Make binary executable
$ chmod +x /usr/local/bin/kbld

# Check its version
$ kbld version
```
