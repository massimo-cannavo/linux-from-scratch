#!/usr/bin/env bash
#
# Builds Zlib as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../zlib.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr

  make -j"$(nproc)"
  make install
  rm -fv /usr/lib/libz.a
popdq
