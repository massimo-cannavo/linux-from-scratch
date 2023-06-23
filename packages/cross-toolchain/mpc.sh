#!/usr/bin/env bash
#
# Downloads MPC dependency for GCC.

# Exit when any command fails.
set -e

YAML_FILE=$CROSS_TOOLCHAIN/../mpc.yaml
PKG_FILE=$(yaml -f "$YAML_FILE" -q package)

download -f "$YAML_FILE"
if [[ -d $LFS_SOURCES/$PKG_FILE ]]; then
  mv -v "$LFS_SOURCES/$PKG_FILE" mpc
fi
