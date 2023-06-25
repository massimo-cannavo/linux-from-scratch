#!/usr/bin/env bash
#
# Builds Bison as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../bison.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)
VERSION=$(yaml -f $YAML_FILE -q .version)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr \
              --docdir="/usr/share/doc/bison-$VERSION"

  make -j"$(nproc)"
  make install
popdq
