#!/usr/bin/env bash
#
# Builds Binutils as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../binutils.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  mkdir -v build-pass3
  cd build-pass3
  ../configure --prefix=/usr       \
               --sysconfdir=/etc   \
               --enable-gold       \
               --enable-ld=default \
               --enable-plugins    \
               --enable-shared     \
               --disable-werror    \
               --enable-64-bit-bfd \
               --with-system-zlib

  make -j"$(nproc)" tooldir=/usr
  make tooldir=/usr install

  rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,sframe,opcodes}.a
  rm -fv /usr/share/man/man1/{gprofng,gp-*}.1
popdq
