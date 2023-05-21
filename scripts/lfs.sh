#!/usr/bin/env bash
#
# TODO: add info about script

# Exit when any command fails.
set -e

source utils.sh
export LFS=/mnt/lfs

is_root
if ! grep -q "$LFS" /proc/mounts; then
  python mount.py
fi

mkdir -pv "${LFS}/sources"
mkdir -pv "${LFS}/home"
