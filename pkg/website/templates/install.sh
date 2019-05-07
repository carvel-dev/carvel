#!/bin/bash

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

install() {
	set -euo pipefail

	echo "Installing ytt..."
	wget -O- https://github.com/k14s/ytt/releases/download/v0.8.0/ytt-linux-amd64 > /tmp/ytt
	echo "41de73008f81e2b072718557689f109087fc64911281fa2b569a4fc6d3d88cf4  /tmp/ytt" | shasum -c -
	mv /tmp/ytt /usr/local/bin/ytt
	chmod +x /usr/local/bin/ytt
	echo "Installed ytt"

	echo "Installing kbld..."
	wget -O- https://github.com/k14s/kbld/releases/download/v0.5.0/kbld-linux-amd64 > /tmp/kbld
	echo "e82867e73444ed83627de198124cff29ce46a3b3d304fa54b005596ae605f2b5  /tmp/kbld" | shasum -c -
	mv /tmp/kbld /usr/local/bin/kbld
	chmod +x /usr/local/bin/kbld
	echo "Installed kbld"

	echo "Installing kapp..."
	wget -O- https://github.com/k14s/kapp/releases/download/v0.4.0/kapp-linux-amd64 > /tmp/kapp
	echo "c6b603ac7dce5ba7f0679df7b69f39a35c8278f479534c2ea5cda8a83acfc0a1  /tmp/kapp" | shasum -c -
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
