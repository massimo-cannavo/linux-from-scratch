#!/usr/bin/env bash
#
# Builds Linux API Headers as part of the cross-compiler build.

# Exit when any command fails.
set -e

YAML_FILE=../linux.yaml
PKG_FILE="$(
  yq '.source' $YAML_FILE  \
    | xargs basename       \
    | sed 's/\.tar\.xz//g'
)"

python ../../scripts/download.py -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  make mrproper
  make headers

  find usr/include -type f ! -name '*.h' -delete
  cp -rv usr/include "$LFS/usr"
popdq
