#!/usr/bin/env bash
#
# Downloads MPFR dependency for GCC.

# Exit when any command fails.
set -e

YAML_FILE="$CROSS_TOOLCHAIN/../mpfr.yaml"
PKG_FILE=$(yaml -f "$YAML_FILE" -q package)

download -f "$YAML_FILE"
if [[ -d $LFS_SOURCES/$PKG_FILE ]]; then
  mv -v "$LFS_SOURCES/$PKG_FILE" mpfr
fi
