#!/usr/bin/env bash
#
# Builds XZ as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../xz.yaml
PKG_FILE=$(python ../../scripts/pyaml.py -f $YAML_FILE -q package)

python ../../scripts/download.py -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr                       \
              --host="$LFS_TGT"                   \
              --build="$(build-aux/config.guess)" \
              --disable-static                    \
              --docdir=/usr/share/doc/xz-5.4.1

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
  rm -v "$LFS/usr/lib/liblzma.la"
popdq
