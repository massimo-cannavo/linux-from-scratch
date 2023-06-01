#!/usr/bin/env bash
#
# Builds Findutils as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../findutils.yaml
PKG_FILE=$(python ../../scripts/pyaml.py -f $YAML_FILE -q package)

python ../../scripts/download.py -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr                   \
              --localstatedir=/var/lib/locate \
              --host="$LFS_TGT"               \
              --build="$(build-aux/config.guess)"

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
popdq
