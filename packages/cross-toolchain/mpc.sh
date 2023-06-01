#!/usr/bin/env bash
#
# Downloads MPC dependency for GCC.

# Exit when any command fails.
set -e

YAML_FILE=$CROSS_TOOLCHAIN/../mpc.yaml
PKG_FILE=$(python ../../scripts/pyaml.py -f "$YAML_FILE" -q package)

python "$SCRIPTS/download.py" -f "$YAML_FILE"
if [[ -f $LFS_SOURCES/$PKG_FILE ]]; then
  mv -v "$LFS_SOURCES/$PKG_FILE" mpc
fi
