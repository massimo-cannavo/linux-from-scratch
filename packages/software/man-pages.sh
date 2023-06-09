#!/usr/bin/env bash
#
# Builds Man-pages as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../man-pages.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  make prefix=/usr install
popdq
