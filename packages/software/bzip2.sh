#!/usr/bin/env bash
#
# Builds Bzip2 as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../bzip2.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)
PATCHES=$(yaml -f $YAML_FILE -q .patches)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  for patch in $PATCHES; do
    patch_file=$(echo "$patch" | xargs basename)
    patch -Np1 -i "../$patch_file"
  done

  #shellcheck disable=SC2016
  sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
  sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

  make -f Makefile-libbz2_so
  make clean

  make -j"$(nproc)"
  make PREFIX=/usr install

  cp -av libbz2.so.* /usr/lib
  ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
  cp -v bzip2-shared /usr/bin/bzip2
  for i in /usr/bin/{bzcat,bunzip2}; do
    ln -sfv bzip2 "$i"
  done

  rm -fv /usr/lib/libbz2.a
popdq
