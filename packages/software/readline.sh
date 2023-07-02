#!/usr/bin/env bash
#
# Builds Readline as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../readline.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)
VERSION=$(yaml -f $YAML_FILE -q .version)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  sed -i '/MV.*old/d' Makefile.in
  sed -i '/{OLDSUFF}/c:' support/shlib-install

  for patch in $PATCHES; do
    patch_file=$(echo "$patch" | xargs basename)
    patch -Np1 -i "../$patch_file"
  done

  ./configure --prefix=/usr                               \
              --disable-static                            \
              --with-curses                               \
              --docdir="/usr/share/doc/readline-$VERSION"

  make -j"$(nproc)" SHLIB_LIBS="-lncursesw"
  make SHLIB_LIBS="-lncursesw" install
  install -v -m644 doc/*.{ps,pdf,html,dvi} "/usr/share/doc/readline-$VERSION"
popdq
