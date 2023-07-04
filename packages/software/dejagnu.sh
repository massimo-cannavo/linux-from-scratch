#!/usr/bin/env bash
#
# Builds DejaGNU as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../dejagnu.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  mkdir -v build
  cd build

  ../configure --prefix=/usr
  makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
  makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

  make install
  install -v -dm755 /usr/share/doc/dejagnu-1.6.3
  install -v -m644  doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
popdq
