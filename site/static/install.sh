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

  ytt_version=v0.38.0
  kbld_version=v0.31.0
  kapp_version=v0.43.0
  kwt_version=v0.0.6
  imgpkg_version=v0.24.0
  vendir_version=v0.23.0

  if [[ `uname` == Darwin ]]; then
    binary_type=darwin-amd64
    ytt_checksum=1f84e26457a5efd2470df408072bf2f182c939414e4958f82e19e122d2ee120c
    kbld_checksum=d3b0a30bf3a79bedeb25d8548a91254954b99cd4a0c03f3a810b331fc4d1f071
    kapp_checksum=c5c7f34399293ccda62dc7b809535a8e2f2afb9901147429281c0f4884b13483
    kwt_checksum=555d50d5bed601c2e91f7444b3f44fdc424d721d7da72955725a97f3860e2517
    imgpkg_checksum=f0c87c8caefb3d2a82e648779b36783403fe5c93930df2d5cbf4968713933392
    vendir_checksum=aef3233128727c01ffac6561533c9f60a49307f41decc1baa18688a4a250b15f
  else
    binary_type=linux-amd64
    ytt_checksum=2ca800c561464e0b252e5ee5cacff6aa53831e65e2fb9a09cf388d764013c40d
    kbld_checksum=ba0be56d9e74b067f3e659de0b79100b0b9df86a2e3e0e6ff533b1e019c22c23
    kapp_checksum=f8669039dfba001081c94576c898d10aba28ecceffcd98708e8f2c87c13109e4
    kwt_checksum=92a1f18be6a8dca15b7537f4cc666713b556630c20c9246b335931a9379196a0
    imgpkg_checksum=cfcfcb5afc5e3d28ce1f2f67971a4dcd18f514dadf8a63d70c864e49c9ddca7e
    vendir_checksum=c6a65e7e8e589e25bf5554e9575ab247e55ae71920d3d366ffd84b1571fe34ac
  fi

  echo "Installing ${binary_type} binaries..."

  echo "Installing ytt..."
  $dl_bin https://github.com/vmware-tanzu/carvel-ytt/releases/download/${ytt_version}/ytt-${binary_type} > /tmp/ytt
  echo "${ytt_checksum}  /tmp/ytt" | shasum -c -
  mv /tmp/ytt ${dst_dir}/ytt
  chmod +x ${dst_dir}/ytt
  echo "Installed ${dst_dir}/ytt ${ytt_version}"

  echo "Installing kbld..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kbld/releases/download/${kbld_version}/kbld-${binary_type} > /tmp/kbld
  echo "${kbld_checksum}  /tmp/kbld" | shasum -c -
  mv /tmp/kbld ${dst_dir}/kbld
  chmod +x ${dst_dir}/kbld
  echo "Installed ${dst_dir}/kbld ${kbld_version}"

  echo "Installing kapp..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kapp/releases/download/${kapp_version}/kapp-${binary_type} > /tmp/kapp
  echo "${kapp_checksum}  /tmp/kapp" | shasum -c -
  mv /tmp/kapp ${dst_dir}/kapp
  chmod +x ${dst_dir}/kapp
  echo "Installed ${dst_dir}/kapp ${kapp_version}"

  echo "Installing kwt..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kwt/releases/download/${kwt_version}/kwt-${binary_type} > /tmp/kwt
  echo "${kwt_checksum}  /tmp/kwt" | shasum -c -
  mv /tmp/kwt ${dst_dir}/kwt
  chmod +x ${dst_dir}/kwt
  echo "Installed ${dst_dir}/kwt ${kwt_version}"

  echo "Installing imgpkg..."
  $dl_bin https://github.com/vmware-tanzu/carvel-imgpkg/releases/download/${imgpkg_version}/imgpkg-${binary_type} > /tmp/imgpkg
  echo "${imgpkg_checksum}  /tmp/imgpkg" | shasum -c -
  mv /tmp/imgpkg ${dst_dir}/imgpkg
  chmod +x ${dst_dir}/imgpkg
  echo "Installed ${dst_dir}/imgpkg ${imgpkg_version}"

  echo "Installing vendir..."
  $dl_bin https://github.com/vmware-tanzu/carvel-vendir/releases/download/${vendir_version}/vendir-${binary_type} > /tmp/vendir
  echo "${vendir_checksum}  /tmp/vendir" | shasum -c -
  mv /tmp/vendir ${dst_dir}/vendir
  chmod +x ${dst_dir}/vendir
  echo "Installed ${dst_dir}/vendir ${vendir_version}"
}

install




