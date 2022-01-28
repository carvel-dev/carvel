#!/usr/bin/env bash
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd "${SCRIPT_DIR}"/../../tools
export CGO_ENABLED=0
go build -o "../validatedocs" -trimpath ./cmd/validate-docs/...
popd
