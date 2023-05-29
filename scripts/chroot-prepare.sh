#!/usr/bin/env bash
#
# Prepares the chroot environment for the build.

# Exit when any command fails.
set -e

sudo chown -vR root:root "$LFS"/{usr,lib,var,etc,bin,sbin,tools,sources}
[[ -d $LFS/boot ]] && sudo chown -vR root:root "$LFS/boot"
case $ARCH in
  x86_64)
    sudo chown -vR root:root "$LFS/lib64"
    ;;
esac

mkdir -pv "$LFS"/{dev,proc,sys,run}
grep -q "$LFS/dev"     /proc/mounts || mount -v --bind /dev "$LFS/dev"
grep -q "$LFS/dev/pts" /proc/mounts || mount -v --bind /dev/pts "$LFS/dev/pts"

grep -q "$LFS/proc" /proc/mounts || mount -vt proc proc "$LFS/proc"
grep -q "$LFS/sys"  /proc/mounts || mount -vt sysfs sysfs "$LFS/sys"
grep -q "$LFS/run"  /proc/mounts || mount -vt tmpfs tmpfs "$LFS/run"

if ! grep -q "$LFS/dev/shm" /proc/mounts; then
  if [[ -h $LFS/dev/shm ]]; then
    mkdir -pv "$LFS/$(readlink "$LFS/dev/shm")"
  else
    mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS_SHM"
  fi
fi

mkdir -vp "$LFS_SOURCES/scripts"
cp -v ./utils.sh "$LFS_SOURCES/scripts"
cp -v ./chroot.sh "$LFS_SOURCES/scripts"

cp -v ../packages/chroot/* "$LFS_SOURCES/packages/chroot"
source chroot-download.sh
