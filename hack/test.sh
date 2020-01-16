#!/bin/bash

set -e -x -u

bash -n ./pkg/website/templates/install.sh

export K14SIO_INSTALL_BIN_DIR=./tmp

PATH=./hack/fake-path-darwin/:$PATH ./pkg/website/templates/install.sh
PATH=./hack/fake-path-linux/:$PATH ./pkg/website/templates/install.sh

echo SUCCESS
