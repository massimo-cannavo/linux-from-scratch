#!/usr/bin/env bash
#
# Builds File as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../file.yaml
PKG_FILE="$(
  yq '.source' $YAML_FILE  \
    | xargs basename       \
    | sed 's/\.tar\.gz//g'
)"

python ../../scripts/download.py -f $YAML_FILE
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
