#!/usr/bin/env bash
#
# Builds Gettext as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../gettext.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  ./configure --disable-shared

  make -j"$(nproc)"
  cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
popdq
