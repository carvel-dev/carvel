#!/bin/bash

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

install() {
	set -euo pipefail

	dst_dir="${K14SIO_INSTALL_BIN_DIR:-/usr/local/bin}"

	echo "Installing ytt..."
	wget -O- https://github.com/k14s/ytt/releases/download/v0.20.0/ytt-linux-amd64 > /tmp/ytt
	echo "a5759302fe28157cda0c9015d41d1b6901f0f03ae184f168dd40521012426219  /tmp/ytt" | shasum -c -
	mv /tmp/ytt ${dst_dir}/ytt
	chmod +x ${dst_dir}/ytt
	echo "Installed ${dst_dir}/ytt"

	echo "Installing kbld..."
	wget -O- https://github.com/k14s/kbld/releases/download/v0.11.0/kbld-linux-amd64 > /tmp/kbld
	echo "1029110ffa0263fb75a9deb25642f577bb9d5ee25b1a5b10db55310e05388569  /tmp/kbld" | shasum -c -
	mv /tmp/kbld ${dst_dir}/kbld
	chmod +x ${dst_dir}/kbld
	echo "Installed ${dst_dir}/kbld"

	echo "Installing kapp..."
	wget -O- https://github.com/k14s/kapp/releases/download/v0.12.0/kapp-linux-amd64 > /tmp/kapp
	echo "75eb211d596ffe01852f04c8c0bb3a2792e53a737e036fe0409132e0e2917076  /tmp/kapp" | shasum -c -
	mv /tmp/kapp ${dst_dir}/kapp
	chmod +x ${dst_dir}/kapp
	echo "Installed ${dst_dir}/kapp"

	echo "Installing kwt..."
	wget -O- https://github.com/k14s/kwt/releases/download/v0.0.5/kwt-linux-amd64 > /tmp/kwt
	echo "706abe487e38c4f673180600d11098e408e6bc22fefb1cc512e3ac0f07a9072c  /tmp/kwt" | shasum -c -
	mv /tmp/kwt ${dst_dir}/kwt
	chmod +x ${dst_dir}/kwt
	echo "Installed ${dst_dir}/kwt"
}

install
