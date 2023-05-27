#!/usr/bin/env bash
#
# Builds binutils Pass 1 as part of the cross-compiler build.

# Exit when any command fails.
set -e

PKG_FILE="$(
  grep 'source:' ../binutils.yaml \
    | cut -d ':' -f 2-3           \
    | xargs basename              \
    | sed 's/\.tar\.xz//g'
)"

python ../../scripts/download.py -f ../binutils.yaml
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
