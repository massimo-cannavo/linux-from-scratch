#!/usr/bin/env bash
# shellcheck disable=SC1091
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

pushdq .
  cd ../utils ; make mount
popdq

if ! grep -q $LFS /proc/mounts; then
  sudo -E ../bin/mount
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
  cd ../utils ; make BIN_DIR=$LFS/tools/bin
popdq

pushdq .
  cd ../packages/cross-toolchain
  source binutils.sh
  source gcc.sh
  source linux-api-headers.sh
  source glibc.sh
  source libstdc++.sh
popdq

pushdq .
  cd ../packages/tools
  source m4.sh
  source ncurses.sh
  source bash.sh
  source coreutils.sh
  source diffutils.sh
  source file.sh
  source findutils.sh
  source gawk.sh
  source grep.sh
  source gzip.sh
  source make.sh
  source patch.sh
  source sed.sh
  source tar.sh
  source xz.sh
  source binutils.sh
  source gcc.sh
popdq

sudo -E ./chroot-prepare.sh
sudo -E chroot "$LFS" /usr/bin/env -i \
  HOME=/root                          \
  TERM="$TERM"                        \
  PS1='(lfs chroot) \u:\w\$ '         \
  PATH=/tools/bin:/usr/bin:/usr/sbin  \
  /bin/bash --login -c /sources/scripts/chroot.sh
