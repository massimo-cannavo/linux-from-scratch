#!/usr/bin/env bash
#
# Builds Binutils Pass 2 as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../binutils.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  # shellcheck disable=SC2016
  sed '6009s/$add_dir//' -i ltmain.sh

  mkdir -pv build-pass2
  cd build-pass2
  ../configure --prefix=/usr                \
               --host="$LFS_TGT"            \
               --build="$(../config.guess)" \
               --disable-nls                \
               --enable-shared              \
               --enable-gprofng=no          \
               --disable-werror             \
               --enable-64-bit-bfd

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
  rm -v "$LFS"/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.{a,la}
popdq
