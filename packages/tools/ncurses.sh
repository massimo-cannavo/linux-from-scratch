#!/usr/bin/env bash
#
# Builds NCURSES as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../ncurses.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  sed -i s/mawk// configure

  mkdir -v build
  pushdq build
    ../configure
    make -C include
    make -C progs tic
  popdq

  ./configure --prefix=/usr                \
              --host="$LFS_TGT"            \
              --build="$(./config.guess)"  \
              --mandir=/usr/share/man      \
              --with-manpage-format=normal \
              --with-shared                \
              --without-normal             \
              --with-cxx-shared            \
              --without-debug              \
              --without-ada                \
              --disable-stripping          \
              --enable-widec

  make -j"$(nproc)"
  make DESTDIR="$LFS" TIC_PATH="$(pwd)/build/progs/tic" install
  echo "INPUT(-lncursesw)" > "$LFS/usr/lib/libncurses.so"
popdq
