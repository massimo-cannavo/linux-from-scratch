#!/usr/bin/env bash
#
# Builds File as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../file.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"

  mkdir -pv build
  pushdq build
    ../configure --disable-bzlib      \
                 --disable-libseccomp \
                 --disable-xzlib      \
                 --disable-zlib
    make
  popdq

  ./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)"

  make -j"$(nproc)" FILE_COMPILE="$(pwd)/build/src/file"
  make DESTDIR="$LFS" install
  rm -v "$LFS/usr/lib/libmagic.la"
popdq
