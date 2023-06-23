#!/usr/bin/env bash
#
# Builds Bash as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../bash.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr                        \
              --build="$(sh support/config.guess)" \
              --host="$LFS_TGT"                    \
              --without-bash-malloc

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
  ln -sv bash "$LFS/bin/sh"
popdq
