#!/usr/bin/env bash
#
# Builds Iana-Etc as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../iana-etc.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  cp -v services protocols /etc
popdq
