#!/usr/bin/env bash
#
# Builds Binutils Pass 1 as part of the cross-compiler build.

# Exit when any command fails.
set -e

YAML_FILE=../binutils.yaml
PKG_FILE="$(
  yq '.source' $YAML_FILE  \
    | xargs basename       \
    | sed 's/\.tar\.xz//g'
)"

python ../../scripts/download.py -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  mkdir -pv build
  cd build

  ../configure --prefix="$LFS/tools" \
               --with-sysroot="$LFS" \
               --target="$LFS_TGT"   \
               --disable-nls         \
               --enable-gprofng=no   \
               --disable-werror

  make -j"$(nproc)"
  make install
popdq
