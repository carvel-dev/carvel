#!/bin/bash

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

install() {
	set -euo pipefail

	echo "Installing ytt..."
	wget -O- https://github.com/k14s/ytt/releases/download/v0.11.0/ytt-linux-amd64 > /tmp/ytt
	echo "08b25d21675fdc77d4281c9bb74b5b36710cc091f30552830604459512f5744c  /tmp/ytt" | shasum -c -
	mv /tmp/ytt /usr/local/bin/ytt
	chmod +x /usr/local/bin/ytt
	echo "Installed ytt"

	echo "Installing kbld..."
	wget -O- https://github.com/k14s/kbld/releases/download/v0.6.0/kbld-linux-amd64 > /tmp/kbld
	echo "605ae37ee1b2f38883b4e55614415d3798161e9eb766088a3504aa707d9cd4ff  /tmp/kbld" | shasum -c -
	mv /tmp/kbld /usr/local/bin/kbld
	chmod +x /usr/local/bin/kbld
	echo "Installed kbld"

	echo "Installing kapp..."
	wget -O- https://github.com/k14s/kapp/releases/download/v0.5.0/kapp-linux-amd64 > /tmp/kapp
	echo "2d0f057ab0518f5eaf981f4bae9a13085533475b5821f74b0b17b8aea12f6d04  /tmp/kapp" | shasum -c -
	mv /tmp/kapp /usr/local/bin/kapp
	chmod +x /usr/local/bin/kapp
	echo "Installed kapp"

	echo "Installing kwt..."
	wget -O- https://github.com/k14s/kwt/releases/download/v0.0.5/kwt-linux-amd64 > /tmp/kwt
	echo "706abe487e38c4f673180600d11098e408e6bc22fefb1cc512e3ac0f07a9072c  /tmp/kwt" | shasum -c -
	mv /tmp/kwt /usr/local/bin/kwt
	chmod +x /usr/local/bin/kwt
	echo "Installed kwt"
}

install
