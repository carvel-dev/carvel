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

  ytt_version=v0.27.0
  kbld_version=v0.20.0
  kapp_version=v0.24.0
  kwt_version=v0.0.6
  imgpkg_version=v0.1.0
  vendir_version=v0.8.0

  if [[ x`uname` == xDarwin ]]; then
    binary_type=darwin-amd64
    ytt_checksum=96cc4cd6131849964feebf0b82ed4302453af015a6b0edfb29a3af672ad6715d
    kbld_checksum=3b6b9a66c1307cae48fdf066b6b713550ad5db7cdb41c3bdefffb92a486ae3d7
    kapp_checksum=e021f9ba9a1398b502e8e4146d695fb79c1f1f975136a9c3ec0a2b29a2bfcaf5
    kwt_checksum=555d50d5bed601c2e91f7444b3f44fdc424d721d7da72955725a97f3860e2517
    imgpkg_checksum=39f1925e39cec7f5837c06c8fce3499a4a24aace9612b8cb15d3835cef4222a0
    vendir_checksum=ae3ba30add41e209f98732b3c319cd1bd59fc5fdfc06e33d7a3e17c30f0569f8
  else
    binary_type=linux-amd64
    ytt_checksum=addd3f27dbffca09a8c7e7610e48dc53d127b08a91eb2b1097544327a6629a8c
    kbld_checksum=a0e7dd4072587aa26db59a74bb2aadeee55ab5d285dd0544cb8eaff11821ed33
    kapp_checksum=044a8355c1a3aa4c9e427fc64f7074b80cb759e539771d70d38933886dbd2df4
    kwt_checksum=92a1f18be6a8dca15b7537f4cc666713b556630c20c9246b335931a9379196a0
    imgpkg_checksum=a9d0ba0edaa792d0aaab2af812fda85ca31eca81079505a8a5705e8ee1d8be93
    vendir_checksum=6a9afd04835020b0901c19991f138e293be99d755a5db15bed8b4dfe34920c17
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
