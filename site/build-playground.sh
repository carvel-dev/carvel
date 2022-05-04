#!/bin/bash

set -e -x -u

mkdir -p local-bin/
curl -L https://carvel.dev/install.sh | K14SIO_INSTALL_BIN_DIR=local-bin bash
export PATH=$PWD/local-bin/:$PATH
local-bin/vendir version
local-bin/vendir sync

mkdir -p netlify/functions
GOOS=linux
GOARCH=amd64
(cd playground-src/github.com/wmware-tanzu/carvel-ytt && ./hack/build.sh)
cp playground-src/github.com/wmware-tanzu/carvel-ytt/tmp/ytt-lambda-website.zip netlify/functions
