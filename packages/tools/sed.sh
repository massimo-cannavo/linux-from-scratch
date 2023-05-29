#!/usr/bin/env bash
#
# Builds Sed as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../sed.yaml
PKG_FILE="$(
  yq '.source' $YAML_FILE  \
    | xargs basename       \
    | sed 's/\.tar\.xz//g'
)"

python ../../scripts/download.py -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr --host="$LFS_TGT"

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
popdq
