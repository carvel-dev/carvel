#!/bin/bash

set -e -x -u

bash -n ./pkg/website/templates/install.sh

echo SUCCESS
