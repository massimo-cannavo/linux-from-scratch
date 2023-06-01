#!/usr/bin/env bash
#
# Builds Coreutils as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../coreutils.yaml
PKG_FILE=$(python ../../scripts/pyaml.py -f $YAML_FILE -q package)

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
