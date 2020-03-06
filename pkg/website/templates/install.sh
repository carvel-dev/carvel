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

  ytt_version=v0.25.0
  kbld_version=v0.13.0
  kapp_version=v0.21.0
  kwt_version=v0.0.6
  imgpkg_version=v0.1.0
  vendir_version=v0.7.0

  if [[ x`uname` == xDarwin ]]; then
    binary_type=darwin-amd64
    ytt_checksum=84a5aa9a9d5c3b67f21136542ecb73aa2c809298094fea21edffb4d2a0cb2f0d
    kbld_checksum=62d3201b31e7f78ae3d6c1d0621aeb21a59be94bd990811e8af28b61f9ec86c1
    kapp_checksum=09c49473b7fa31633203867f253c10d0bbd543cda5bc640ff2ebc91aec9be130
    kwt_checksum=555d50d5bed601c2e91f7444b3f44fdc424d721d7da72955725a97f3860e2517
    imgpkg_checksum=39f1925e39cec7f5837c06c8fce3499a4a24aace9612b8cb15d3835cef4222a0
    vendir_checksum=8c753b9efda146171b511c6e8d9964c8dee7dd43320d468e600f47413d990287
  else
    binary_type=linux-amd64
    ytt_checksum=2ccd2c74fea87748515ed3fd74cd45c31f91472fabadf42e6a958f52312e3b47
    kbld_checksum=c5dc9a5e2fc1795f64f674cbc528a28c269432ce9485ee4dc74d8d18890dd4be
    kapp_checksum=9dfeb831f8caf5515dff968f040f06cb9cb8942dec7df3626a44eee1e63cf460
    kwt_checksum=92a1f18be6a8dca15b7537f4cc666713b556630c20c9246b335931a9379196a0
    imgpkg_checksum=a9d0ba0edaa792d0aaab2af812fda85ca31eca81079505a8a5705e8ee1d8be93
    vendir_checksum=58c09e2b22e8bc2136534405f5e76a544cfac3a57d165670ab3fcfb18cb3e604
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
