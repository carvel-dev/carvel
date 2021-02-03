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

  ytt_version=v0.31.0
  kbld_version=v0.28.0
  kapp_version=v0.35.0
  kwt_version=v0.0.6
  imgpkg_version=v0.3.0
  vendir_version=v0.16.0

  if [[ `uname` == Darwin ]]; then
    binary_type=darwin-amd64
    ytt_checksum=bf85381a12954793d5a18f252579cb1bc043aada2c34ac0974e2ab8cf03a1de3
    kbld_checksum=4962a56a755fb3f12678d1024007bcf87485e350b031924d5f24c3361e7dd7f9
    kapp_checksum=2f7b37c9cf5a8fd46e7b5da181c93ac3c16fba21664e3c5e413e38fca3510cc2
    kwt_checksum=555d50d5bed601c2e91f7444b3f44fdc424d721d7da72955725a97f3860e2517
    imgpkg_checksum=05bd8815c049b61fce0935a59149f0daca06ea62526b3961a33b3608fe90835e
    vendir_checksum=3e6af7ae5cd89579f6d153af6b6a4c0ab1cfcac22f5014b983d1d942feb8bab0
  else
    binary_type=linux-amd64
    ytt_checksum=32e7cdc38202b49fe673442bd22cb2b130e13f0f05ce724222a06522d7618395
    kbld_checksum=3174e5b42286aab4359d2bc12a85356ba520744fd4e26d6511fb8d705e7170c3
    kapp_checksum=0f9d4daa8c833a8e245362c77e72f4ed06d4f0a12eed6c09813c87a992201676
    kwt_checksum=92a1f18be6a8dca15b7537f4cc666713b556630c20c9246b335931a9379196a0
    imgpkg_checksum=7ebd513bdb4d448764725202f0bfe41e052a594eddeb55e53681ebdf4c27d4dc
    vendir_checksum=05cede475c2b947772a9fe552380927054d48158959c530122a150a93bf542dd
  fi

  echo "Installing ${binary_type} binaries..."

  echo "Installing ytt..."
  $dl_bin https://github.com/vmware-tanzu/carvel-ytt/releases/download/${ytt_version}/ytt-${binary_type} > /tmp/ytt
  echo "${ytt_checksum}  /tmp/ytt" | shasum -c -
  mv /tmp/ytt ${dst_dir}/ytt
  chmod +x ${dst_dir}/ytt
  echo "Installed ${dst_dir}/ytt v${ytt_version}"

  echo "Installing kbld..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kbld/releases/download/${kbld_version}/kbld-${binary_type} > /tmp/kbld
  echo "${kbld_checksum}  /tmp/kbld" | shasum -c -
  mv /tmp/kbld ${dst_dir}/kbld
  chmod +x ${dst_dir}/kbld
  echo "Installed ${dst_dir}/kbld v${kbld_version}"

  echo "Installing kapp..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kapp/releases/download/${kapp_version}/kapp-${binary_type} > /tmp/kapp
  echo "${kapp_checksum}  /tmp/kapp" | shasum -c -
  mv /tmp/kapp ${dst_dir}/kapp
  chmod +x ${dst_dir}/kapp
  echo "Installed ${dst_dir}/kapp v${kapp_version}"

  echo "Installing kwt..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kwt/releases/download/${kwt_version}/kwt-${binary_type} > /tmp/kwt
  echo "${kwt_checksum}  /tmp/kwt" | shasum -c -
  mv /tmp/kwt ${dst_dir}/kwt
  chmod +x ${dst_dir}/kwt
  echo "Installed ${dst_dir}/kwt v${kwt_version}"

  echo "Installing imgpkg..."
  $dl_bin https://github.com/vmware-tanzu/carvel-imgpkg/releases/download/${imgpkg_version}/imgpkg-${binary_type} > /tmp/imgpkg
  echo "${imgpkg_checksum}  /tmp/imgpkg" | shasum -c -
  mv /tmp/imgpkg ${dst_dir}/imgpkg
  chmod +x ${dst_dir}/imgpkg
  echo "Installed ${dst_dir}/imgpkg v${imgpkg_version}"

  echo "Installing vendir..."
  $dl_bin https://github.com/vmware-tanzu/carvel-vendir/releases/download/${vendir_version}/vendir-${binary_type} > /tmp/vendir
  echo "${vendir_checksum}  /tmp/vendir" | shasum -c -
  mv /tmp/vendir ${dst_dir}/vendir
  chmod +x ${dst_dir}/vendir
  echo "Installed ${dst_dir}/vendir v${vendir_version}"
}

install
