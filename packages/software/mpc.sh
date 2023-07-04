#!/usr/bin/env bash
#
# Builds MPC as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../mpc.yaml
PKG_FILE=$(yaml -f ../gcc.yaml -q package)
VERSION=$(yaml -f $YAML_FILE -q .version)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE/mpc"
  ./configure --prefix=/usr                          \
              --disable-static                       \
              --docdir="/usr/share/doc/mpc-$VERSION"

  make -j"$(nproc)"
  make html

  make install
  make install-html
popdq
