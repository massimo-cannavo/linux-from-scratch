#!/usr/bin/env bash
#
# Builds Expect as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../expect.yaml
VERSION=$(yaml -f $YAML_FILE -q .version)
PKG_FILE=expect-$VERSION

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  mv -v "$LFS_SOURCES/expect" "$LFS_SOURCES/$PKG_FILE"
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr                  \
              --with-tcl=/usr/lib            \
              --enable-shared                \
              --mandir=/usr/share/man        \
              --with-tclinclude=/usr/include

  make -j"$(nproc)"
  make install

  ln -svf "expect$VERSION/libexpect$VERSION.so" /usr/lib
popdq
