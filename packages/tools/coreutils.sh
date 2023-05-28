#!/usr/bin/env bash
#
# Builds coreutils as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../coreutils.yaml
PKG_FILE="$(
  yq '.source' $YAML_FILE  \
    | xargs basename       \
    | sed 's/\.tar\.xz//g'
)"

python ../../scripts/download.py -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --prefix=/usr                       \
              --host="$LFS_TGT"                   \
              --build="$(build-aux/config.guess)" \
              --enable-install-program=hostname   \
              --enable-no-install-program=kill,uptime

  make -j"$(nproc)"
  make DESTDIR="$LFS" install

  mv -v "$LFS/usr/bin/chroot" "$LFS/usr/sbin"
  mkdir -pv "$LFS/usr/share/man/man8"
  mv -v "$LFS/usr/share/man/man1/chroot.1" "$LFS/usr/share/man/man8/chroot.8"
  sed -i 's/"1"/"8"/' "$LFS/usr/share/man/man8/chroot.8"
popdq
