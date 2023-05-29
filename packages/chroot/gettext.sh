#!/usr/bin/env bash
#
# Builds Gettext as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../gettext.yaml
PKG_FILE="$(
  grep 'source:' $YAML_FILE \
    | cut -d ':' -f 2-3     \
    | xargs basename        \
    | sed 's/\.tar\.xz//g'
)"

pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --disable-shared

  make -j"$(nproc)"
  cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
popdq
