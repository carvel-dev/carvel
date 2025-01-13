---

title: Install
---

## Via script (macOS or Linux)

(Note that `install.sh` script installs other Carvel tools as well.)

Install binaries into specific directory:

```bash
$ mkdir local-bin/
$ curl -L https://carvel.dev/install.sh | K14SIO_INSTALL_BIN_DIR=local-bin bash

$ export PATH=$PWD/local-bin/:$PATH
$ ytt version
```

Or system wide:

```bash
$ wget -O- https://carvel.dev/install.sh > install.sh

# Inspect install.sh before running...
$ sudo bash install.sh
$ ytt version
```

## Via Homebrew (macOS or Linux)

Based on [github.com/carvel-dev/homebrew](https://github.com/carvel-dev/homebrew).

```bash
$ brew tap carvel-dev/carvel
$ brew install ytt
$ ytt version
```

## Specific version from a GitHub release

To download, click on one of the assets in a [chosen GitHub release](https://github.com/carvel-dev/ytt/releases), for example for 'ytt-darwin-amd64'.

```bash
# **Compare binary checksum** against what's specified in the release notes
# (if checksums do not match, binary was not successfully downloaded)
$ shasum -a 256 ~/Downloads/ytt-darwin-amd64
08b25d21675fdc77d4281c9bb74b5b36710cc091f30552830604459512f5744c   /Users/pivotal/Downloads/ytt-darwin-amd64

# Move binary next to your other executables
$ mv ~/Downloads/ytt-darwin-amd64 /usr/local/bin/ytt

# Make binary executable
$ chmod +x /usr/local/bin/ytt

# Check its version
$ ytt version
```
## Shell Completion 

The `ytt completion` command generates an autocompletion script for the specified shell.

See `ytt completion --help` for information and instructions.

For detailed instructions on enabling shell completion, specify the type of shell in the help command. For example:
`ytt completion zsh --help`.
