#!/usr/bin/env bash
set -o nounset
set -o pipefail

echo "=============== list modified files ==============="
git diff --name-only develop | head

echo "========== check paths of modified files =========="
git diff --name-only develop | head > filesChanged.txt

./validatedocs -diff filesChanged.txt -cfg site/config.yaml

echo "No frozen documentation changes"
exit 0
