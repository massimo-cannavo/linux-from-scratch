#!/usr/bin/env bash
#
# Builds Man-pages as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../man-pages.yaml
PKG_FILE=$(python3 ../../scripts/pyaml.py -f $YAML_FILE -q package)

python ../../scripts/download.py -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  make prefix=/usr install
popdq
