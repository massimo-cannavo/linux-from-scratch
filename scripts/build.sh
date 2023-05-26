#!/usr/bin/env bash
#
# The main entrypoint script for building Linux From Scratch.

# Exit when any command fails.
set -e

source utils.sh
umask 022

export LFS=/mnt/lfs
export LFS_TGT=$ARCH-lfs-linux-gnu
export LC_ALL=POSIX
export PATH=$LFS/tools/bin:$PATH
export CONFIG_SITE=$LFS/usr/share/config.site
export LFS_SOURCES="$LFS/sources"

if ! grep -q $LFS /proc/mounts; then
  sudo -E python mount.py
  sudo chown -v "$USER" $LFS
  [[ -d $LFS/boot ]] && sudo chown -v "$USER" $LFS/boot
fi

mkdir -pv $LFS/sources
mkdir -pv $LFS/tools
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  symlink=$LFS/$i
  [[ ! -e $symlink ]] && ln -sv usr/$i $symlink
done

case $ARCH in
  x86_64)
    mkdir -pv $LFS/lib64
    ;;
esac

pushdq .
  cd ../packages/cross-toolchain
  # shellcheck disable=SC1091
  source binutils.sh
popdq
