#!/usr/bin/env bash
#
# Builds Python as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../python.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr   \
              --enable-shared \
              --without-ensurepip

  make -j"$(nproc)"
  make install
popdq
