#!/usr/bin/env bash
#
# Builds Linux API Headers as part of the cross-compiler build.

# Exit when any command fails.
set -e

PKG_FILE="$(
  grep 'source:' ../linux.yaml \
    | cut -d ':' -f 2-3        \
    | xargs basename           \
    | sed 's/\.tar\.xz//g'
)"

python ../../scripts/download.py -f ../linux.yaml
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  make mrproper
  make headers

  find usr/include -type f ! -name '*.h' -delete
  cp -rv usr/include "$LFS/usr"
popdq
