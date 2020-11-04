#!/bin/bash

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

install() {
  set -euo pipefail

  dst_dir="${K14SIO_INSTALL_BIN_DIR:-/usr/local/bin}"

  if [ -x "$(command -v wget)" ]; then
    dl_bin="wget -nv -O-"
  else
    dl_bin="curl -s -L"
  fi

  shasum -v 1>/dev/null 2>&1 || (echo "Missing shasum binary" && exit 1)

  ytt_version=v0.30.0
  kbld_version=v0.27.0
  kapp_version=v0.34.0
  kwt_version=v0.0.6
  imgpkg_version=v0.2.0
  vendir_version=v0.12.0

  if [[ x`uname` == xDarwin ]]; then
    binary_type=darwin-amd64
    ytt_checksum=a1a56c3292e355b9891b2c4ce7525d78f0e1ffd8630b856d300e9a7f383e707c
    kbld_checksum=17e1336b714f9b6e9a99f86c6a8952be56b018d7aacab712f70e59430edfbdab
    kapp_checksum=61795970d69c530c134711e35fca35ef143176c9a32bf8dce9ef39b1bd0d3b75
    kwt_checksum=555d50d5bed601c2e91f7444b3f44fdc424d721d7da72955725a97f3860e2517
    imgpkg_checksum=e37f55e1dbd3ace7daf6ab8356c11f8104af1601f92ba96eebc57aa74c18cfa4
    vendir_checksum=418dbd15eaded3c5c324ef8f13a98d2d023c10447e7465a739af5b9746afe5c4
  else
    binary_type=linux-amd64
    ytt_checksum=456e58c70aef5cd4946d29ed106c2b2acbb4d0d5e99129e526ecb4a859a36145
    kbld_checksum=9c2c38ce2f884523a6888c3ba5c28bb9a7ab5d3f9879ab8492db1372e206e83b
    kapp_checksum=e170193c40ff5dff9f9274c25048de1f50e23c69e8406df274fbb416d5862d7f
    kwt_checksum=92a1f18be6a8dca15b7537f4cc666713b556630c20c9246b335931a9379196a0
    imgpkg_checksum=57a73c4721c39f815408f486c1acfb720af82450996e2bfdf4c2c280d8a28dcc
    vendir_checksum=3310669b39cd2095f9ff373fef479ed90c2eb75e3987f8e14e3779c59fa051c4
  fi

  echo "Installing ${binary_type} binaries..."

  echo "Installing ytt..."
  $dl_bin https://github.com/k14s/ytt/releases/download/${ytt_version}/ytt-${binary_type} > /tmp/ytt
  echo "${ytt_checksum}  /tmp/ytt" | shasum -c -
  mv /tmp/ytt ${dst_dir}/ytt
  chmod +x ${dst_dir}/ytt
  echo "Installed ${dst_dir}/ytt"

  echo "Installing kbld..."
  $dl_bin https://github.com/k14s/kbld/releases/download/${kbld_version}/kbld-${binary_type} > /tmp/kbld
  echo "${kbld_checksum}  /tmp/kbld" | shasum -c -
  mv /tmp/kbld ${dst_dir}/kbld
  chmod +x ${dst_dir}/kbld
  echo "Installed ${dst_dir}/kbld"

  echo "Installing kapp..."
  $dl_bin https://github.com/k14s/kapp/releases/download/${kapp_version}/kapp-${binary_type} > /tmp/kapp
  echo "${kapp_checksum}  /tmp/kapp" | shasum -c -
  mv /tmp/kapp ${dst_dir}/kapp
  chmod +x ${dst_dir}/kapp
  echo "Installed ${dst_dir}/kapp"

  echo "Installing kwt..."
  $dl_bin https://github.com/k14s/kwt/releases/download/${kwt_version}/kwt-${binary_type} > /tmp/kwt
  echo "${kwt_checksum}  /tmp/kwt" | shasum -c -
  mv /tmp/kwt ${dst_dir}/kwt
  chmod +x ${dst_dir}/kwt
  echo "Installed ${dst_dir}/kwt"

  echo "Installing imgpkg..."
  $dl_bin https://github.com/k14s/imgpkg/releases/download/${imgpkg_version}/imgpkg-${binary_type} > /tmp/imgpkg
  echo "${imgpkg_checksum}  /tmp/imgpkg" | shasum -c -
  mv /tmp/imgpkg ${dst_dir}/imgpkg
  chmod +x ${dst_dir}/imgpkg
  echo "Installed ${dst_dir}/imgpkg"

  echo "Installing vendir..."
  $dl_bin https://github.com/k14s/vendir/releases/download/${vendir_version}/vendir-${binary_type} > /tmp/vendir
  echo "${vendir_checksum}  /tmp/vendir" | shasum -c -
  mv /tmp/vendir ${dst_dir}/vendir
  chmod +x ${dst_dir}/vendir
  echo "Installed ${dst_dir}/vendir"
}

install
