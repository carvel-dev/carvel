#!/bin/bash

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

install() {
	set -euo pipefail

	# Start Kubernetes on Katacoda
	launch.sh

	wget -O- https://carvel.dev/install.sh | bash

	git clone https://github.com/carvel-dev/kapp
	echo "Cloned github.com/carvel-dev/kapp for examples"
}

install
