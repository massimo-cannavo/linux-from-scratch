#!/usr/bin/env bash
#
# Builds Libcap as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../libcap.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  sed -i '/install -m.*STA/d' libcap/Makefile

  make -j"$(nproc)" prefix=/usr lib=lib
  make prefix=/usr lib=lib install
popdq
