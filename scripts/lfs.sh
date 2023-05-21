#!/usr/bin/env bash
#
# TODO: add info about script

# Exit when any command fails.
set -e

source utils.sh
export LFS=/mnt/lfs

is_root
if ! grep -q $LFS /proc/mounts; then
  python mount.py
fi

mkdir -pv $LFS/sources
mkdir -pv $LFS/tools
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  symlink=$LFS/$i
  [[ ! -e $symlink ]] && ln -sv usr/$i $symlink
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
