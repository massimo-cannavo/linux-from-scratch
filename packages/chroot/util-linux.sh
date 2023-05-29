#!/usr/bin/env bash
#
# Builds Util-linux as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../util-linux.yaml
PKG_FILE="$(
  grep 'source:' $YAML_FILE \
    | cut -d ':' -f 2-3     \
    | xargs basename        \
    | sed 's/\.tar\.xz//g'
)"
VERSION=$(
  grep 'version:' $YAML_FILE \
    | cut -d ':' -f 2-3      \
    | sed 's/"//g'           \
    | xargs
)

mkdir -pv /var/lib/hwclock
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime       \
            --libdir=/usr/lib                             \
            --docdir="/usr/share/doc/util-linux-$VERSION" \
            --disable-chfn-chsh                           \
            --disable-login                               \
            --disable-nologin                             \
            --disable-su                                  \
            --disable-setpriv                             \
            --disable-runuser                             \
            --disable-pylibmount                          \
            --disable-static                              \
            --without-python                              \
            runstatedir=/run

  make -j"$(nproc)"
  make install
popdq
