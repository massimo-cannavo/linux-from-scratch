#!/usr/bin/env bash
#
# Builds MPFR as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../mpfr.yaml
PKG_FILE=$(yaml -f ../gcc.yaml -q package)
VERSION=$(yaml -f $YAML_FILE -q .version)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE/mpfr"
  ./configure --prefix=/usr                           \
              --disable-static                        \
              --enable-thread-safe                    \
              --docdir="/usr/share/doc/mpfr-$VERSION"

  make -j"$(nproc)"
  make html

  make install
  make install-html
popdq
