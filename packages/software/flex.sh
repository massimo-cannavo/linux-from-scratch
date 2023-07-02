#!/usr/bin/env bash
#
# Builds Flex as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../flex.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)
VERSION=$(yaml -f $YAML_FILE -q .version)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr                           \
              --docdir="/usr/share/doc/flex-$VERSION" \
              --disable-static

  make -j"$(nproc)"
  make install
  ln -sv flex /usr/bin/lex
popdq
