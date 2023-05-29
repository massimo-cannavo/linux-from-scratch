#!/usr/bin/env bash
#
# Builds Make as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../make.yaml
PKG_FILE="$(
  yq '.source' $YAML_FILE  \
    | xargs basename       \
    | sed 's/\.tar\.gz//g'
)"

python ../../scripts/download.py -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  sed -e '/ifdef SIGPIPE/,+2 d' \
      -e '/undef  FATAL_SIG/i FATAL_SIG (SIGPIPE);' \
      -i src/main.c

  ./configure --prefix=/usr     \
              --without-guile   \
              --host="$LFS_TGT" \
              --build="$(build-aux/config.guess)"

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
popdq
