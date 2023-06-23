#!/usr/bin/env bash
#
# Builds Patch as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../patch.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr     \
              --host="$LFS_TGT" \
              --build="$(build-aux/config.guess)"

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
popdq
