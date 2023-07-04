#!/usr/bin/env bash
#
# Builds GMP as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../gmp.yaml
PKG_FILE=$(yaml -f ../gcc.yaml -q package)
VERSION=$(yaml -f $YAML_FILE -q .version)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE/gmp"
  ./configure --prefix=/usr                          \
              --enable-cxx                           \
              --disable-static                       \
              --docdir="/usr/share/doc/gmp-$VERSION"

  make -j"$(nproc)"
  make html

  make install
  make install-html
popdq
