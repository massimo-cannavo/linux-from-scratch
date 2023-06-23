#!/usr/bin/env bash
#
# Builds Linux API Headers as part of the cross-compiler build.

# Exit when any command fails.
set -e

YAML_FILE=../linux.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  make mrproper
  make headers

  find usr/include -type f ! -name '*.h' -delete
  cp -rv usr/include "$LFS/usr"
popdq
