#!/usr/bin/env bash
#
# Downloads packages for the chroot environment.

# Exit when any command fails.
set -e

source utils.sh

mkdir -vp "$LFS_SOURCES/packages/chroot"
cp -v ../packages/gettext.yaml "$LFS_SOURCES/packages"
cp -v ../packages/bison.yaml "$LFS_SOURCES/packages"
cp -v ../packages/perl.yaml "$LFS_SOURCES/packages"
cp -v ../packages/python.yaml "$LFS_SOURCES/packages"
cp -v ../packages/texinfo.yaml "$LFS_SOURCES/packages"
cp -v ../packages/util-linux.yaml "$LFS_SOURCES/packages"

pushdq .
  cd ../packages
  python ../scripts/download.py -f gettext.yaml
  python ../scripts/download.py -f bison.yaml
  python ../scripts/download.py -f perl.yaml
  python ../scripts/download.py -f python.yaml
  python ../scripts/download.py -f texinfo.yaml
  python ../scripts/download.py -f util-linux.yaml
popdq
