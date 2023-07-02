#!/usr/bin/env bash
#
# Builds Xz as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../xz.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)
VERSION=$(yaml -f $YAML_FILE -q .version)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr                         \
              --disable-static                      \
              --docdir="/usr/share/doc/xz-$VERSION"

  make -j"$(nproc)"
  make install
popdq
