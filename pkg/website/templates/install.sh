#!/bin/bash

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

install() {
	set -euo pipefail

	echo "Installing ytt..."
	wget -O- https://github.com/k14s/ytt/releases/download/v0.7.0/ytt-linux-amd64 > /tmp/ytt
	echo "30764e32dab4cdaca432446afc75b07b13e6cdc2b5a6bd474a5b82bef13da60f  /tmp/ytt" | shasum -c -
	mv /tmp/ytt /usr/local/bin/ytt
	chmod +x /usr/local/bin/ytt
	echo "Installed ytt"

	echo "Installing kbld..."
	wget -O- https://github.com/k14s/kbld/releases/download/v0.2.0/kbld-linux-amd64 > /tmp/kbld
	echo "5996b9f4605b5e2cbb017a485d144d011a8657da0f22bf53a3d55392c85ece3e  /tmp/kbld" | shasum -c -
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
