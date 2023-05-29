#!/usr/bin/env bash
#
# Builds Bison as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../bison.yaml
PKG_FILE="$(
  grep 'source:' $YAML_FILE \
    | cut -d ':' -f 2-3     \
    | xargs basename        \
    | sed 's/\.tar\.xz//g'
)"
VERSION=$(
  grep 'version:' $YAML_FILE \
    | cut -d ':' -f 2-3      \
    | sed 's/"//g'           \
    | xargs
)

pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr \
              --docdir="/usr/share/doc/bison-$VERSION"

  make -j"$(nproc)"
  make install
popdq
