#!/usr/bin/env bash
#
# Builds bc as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../bc.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  CC=gcc ./configure --prefix=/usr -G -O3 -r

  make -j"$(nproc)"
  make install
popdq
