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

  ytt_version=v0.25.0
  kbld_version=v0.13.0
  kapp_version=v0.20.0
  kwt_version=v0.0.6
  imgpkg_version=v0.1.0

  if [[ x`uname` == xDarwin ]]; then
    binary_type=darwin-amd64
    ytt_checksum=84a5aa9a9d5c3b67f21136542ecb73aa2c809298094fea21edffb4d2a0cb2f0d
    kbld_checksum=62d3201b31e7f78ae3d6c1d0621aeb21a59be94bd990811e8af28b61f9ec86c1
    kapp_checksum=f4f259d3b0a226f8ea7ccbf7347de3e40529d698fb0bc2ef1f0dcf7aea25c72a
    kwt_checksum=555d50d5bed601c2e91f7444b3f44fdc424d721d7da72955725a97f3860e2517
    imgpkg_checksum=39f1925e39cec7f5837c06c8fce3499a4a24aace9612b8cb15d3835cef4222a0
  else
    binary_type=linux-amd64
    ytt_checksum=2ccd2c74fea87748515ed3fd74cd45c31f91472fabadf42e6a958f52312e3b47
    kbld_checksum=c5dc9a5e2fc1795f64f674cbc528a28c269432ce9485ee4dc74d8d18890dd4be
    kapp_checksum=3287514b8ca14fb0378af701fce94cec09e613bff473a2ee969335edf86da5b5
    kwt_checksum=92a1f18be6a8dca15b7537f4cc666713b556630c20c9246b335931a9379196a0
    imgpkg_checksum=a9d0ba0edaa792d0aaab2af812fda85ca31eca81079505a8a5705e8ee1d8be93
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
}

install
