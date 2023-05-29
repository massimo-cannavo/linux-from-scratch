#!/usr/bin/env bash
#
# Prepares the chroot environment for the build.

# Exit when any command fails.
set -e

source utils.sh
is_root

PROC_MOUNTS=/proc/mounts

LFS_DEV=$LFS/dev
LFS_PTS=$LFS/dev/pts
LFS_SHM=$LFS/dev/shm

LFS_PROC=$LFS/proc
LFS_SYS=$LFS/sys
LFS_RUN=$LFS/run

sudo chown -vR root:root "$LFS"/{usr,lib,var,etc,bin,sbin,tools,sources}
[[ -d $LFS/boot ]] && sudo chown -vR root:root "$LFS/boot"
case $ARCH in
  x86_64)
    sudo chown -vR root:root "$LFS/lib64"
    ;;
esac

mkdir -pv "$LFS"/{dev,proc,sys,run}
grep -q "$LFS_DEV" $PROC_MOUNTS || mount -v --bind /dev "$LFS_DEV"
grep -q "$LFS_PTS" $PROC_MOUNTS || mount -v --bind /dev/pts "$LFS_PTS"

grep -q "$LFS_PROC" $PROC_MOUNTS || mount -vt proc proc "$LFS_PROC"
grep -q "$LFS_SYS"  $PROC_MOUNTS || mount -vt sysfs sysfs "$LFS_SYS"
grep -q "$LFS_RUN"  $PROC_MOUNTS || mount -vt tmpfs tmpfs "$LFS_RUN"

if ! grep -q "$LFS_SHM" $PROC_MOUNTS; then
  if [[ -h $LFS_SHM ]]; then
    mkdir -pv "$LFS/$(readlink "$LFS_SHM")"
  else
    mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS_SHM"
  fi
fi

cp -v ./chroot.sh "$LFS_SOURCES"

chroot "$LFS" /usr/bin/env -i \
  HOME=/root                  \
  TERM="$TERM"                \
  PS1='(lfs chroot) \u:\w\$ ' \
  PATH=/usr/bin:/usr/sbin     \
  /bin/bash --login -c /sources/chroot.sh
