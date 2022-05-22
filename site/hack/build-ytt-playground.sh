#!/bin/bash

set -e -x -u

cd carvel-ytt
#go mod init ytt-submodule-playground
#go fmt $(go list ./... | grep -v yaml.v2)
go mod vendor
go mod tidy
export GOOS=linux GOARCH=amd64
ls
cd cmd/ytt && go build -o ../../../netlify/functions/ytt && cd -
cd cmd/ytt-lambda-website && go build -o ../../../netlify/functions/main && cd -
cd ..
ls
chmod +x netlify/functions/ytt netlify/functions/main

