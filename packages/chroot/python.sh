#!/usr/bin/env bash
#
# Builds Python as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../python.yaml
PKG_FILE="$(
  grep 'source:' $YAML_FILE \
    | cut -d ':' -f 2-3     \
    | xargs basename        \
    | sed 's/\.tar\.xz//g'
)"

pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr   \
              --enable-shared \
              --without-ensurepip

  make -j"$(nproc)"
  make install
popdq
