#!/usr/bin/env bash
#
# Builds Zstd as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../zstd.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  make -j"$(nproc)" prefix=/usr

  make prefix=/usr install
  rm -v /usr/lib/libzstd.a
popdq
