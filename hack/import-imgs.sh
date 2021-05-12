#!/usr/bin/env bash

set -eu -o pipefail

# TODO: require "--force" in order to create directories or overwrite existing files

IMAGES_DIR="./static/images"

if [[ $# -ne 1 ]]; then
  echo "$0 -- copies images exported from Miro to the proper location in this repo"
  echo -e "\nUsage:"
  echo "  $0 (path-to-source-images)"
  echo -e "\nSource for images and instructions:\n   https://miro.com/app/board/o9J_lIfcKZY=/?moveToWidget=3074457358161105960&cot=14\n"
  exit 1
fi

if [[ ! -d $IMAGES_DIR ]]; then
  echo "$0: Error: unable to find the destination directory (i.e. \"$IMAGES_DIR)\")."
  echo "hint: this script must be executed from the root of this project."
  exit 2
fi

SRC_DIR="$1"
MIRO_BOARD_NAME="imgs-for-docs"
FILENAME_PREFIX="${MIRO_BOARD_NAME} - "

# use the null character as delimiter to avoid problems with spaces in filenames
find $SRC_DIR -name "${MIRO_BOARD_NAME}*" -print0 | while read -d $'\0' src_path
do
  dest_path=$(basename $src_path)
  dest_path=$(echo $dest_path | sed "s|^$FILENAME_PREFIX||")
  dest_path=$(echo $dest_path | tr '_' '/')
  dest_path="${IMAGES_DIR}/${dest_path}"

  dest_dirs=$(dirname ${dest_path})
  if [[ ! -d "${dest_dirs}" ]]; then
    ( set -x; mkdir -p "${dest_dirs}" )
  fi
  ( set -x; mv "$src_path" "$dest_path" )
done


