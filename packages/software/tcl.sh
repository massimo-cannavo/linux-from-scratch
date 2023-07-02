#!/usr/bin/env bash
#
# Builds Tcl as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../tcl.yaml
VERSION=$(yaml -f $YAML_FILE -q .version)
MAJOR_VERSION="$(echo "$VERSION" | cut -d '.' -f 1,2)"
PKG_FILE=tcl-$VERSION

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  mv -v "$LFS_SOURCES/tcl" "$LFS_SOURCES/$PKG_FILE"
  cd "$LFS_SOURCES/$PKG_FILE"
  SRCDIR=$(pwd)
  cd unix
  ./configure --prefix=/usr           \
              --mandir=/usr/share/man

  make -j"$(nproc)"

  sed -e "s|$SRCDIR/unix|/usr/lib|" \
      -e "s|$SRCDIR|/usr/include|"  \
      -i tclConfig.sh

  sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|"            \
      -e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|"               \
      -e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl$MAJOR_VERSION|" \
      -e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|"                       \
      -i pkgs/tdbc1.1.5/tdbcConfig.sh

  sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
      -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
      -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
      -i pkgs/itcl4.2.3/itclConfig.sh

  make install
  chmod -v u+w "/usr/lib/libtcl$MAJOR_VERSION.so"
  make install-private-headers

  ln -sfv "tclsh$MAJOR_VERSION" /usr/bin/tclsh
  mv /usr/share/man/man3/{Thread,Tcl_Thread}.3

  cd ..
  mkdir -v -p "/usr/share/doc/tcl-$VERSION"
  cp -v -r  ./html/* "/usr/share/doc/tcl-$VERSION"

  unset SRCDIR
popdq
