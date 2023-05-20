#!/usr/bin/env bash
#
# TODO: add info about script

# Exit when any command fails.
set -e

mapfile -t DEVICE < <(python get_device.py)
export LFS_DISK=${DEVICE[0]}
export LFS_ROOT=${DEVICE[1]}
export LFS=/mnt/lfs

ROOT=$LFS_ROOT
if ! grep -q "$LFS" /proc/mounts; then
  ENCRYPTED="${DEVICE[2]}"
  if [[ $ENCRYPTED == "True" ]] && ! sudo cryptsetup status root; then
    echo "$LUKS_PASSPHRASE" | sudo cryptsetup -v open "$LFS_ROOT" root
    ROOT='/dev/mapper/root'
  fi

  sudo mkdir -pv "$LFS"
  sudo mount -v "$ROOT" "$LFS"
fi
