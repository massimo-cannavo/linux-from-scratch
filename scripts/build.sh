#!/usr/bin/env bash
#
# TODO: add info about script

# Exit when any command fails.
set -e

source utils.sh
umask 022

export LFS=/mnt/lfs
export LFS_TGT=$ARCH-lfs-linux-gnu
export LC_ALL=POSIX
export PATH=$LFS/tools/bin:$PATH
export CONFIG_SITE=$LFS/usr/share/config.site

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

chown -v "$SUDO_USER" $LFS/tools
chown -v "$SUDO_USER" $LFS/{etc,var,usr}
chown -v "$SUDO_USER" $LFS/usr/{bin,lib,sbin}
case $ARCH in
  x86_64)
    mkdir -pv $LFS/lib64
    chown -v "$SUDO_USER" $LFS/lib64
    ;;
esac
