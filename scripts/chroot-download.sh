#!/usr/bin/env bash
#
# Downloads packages for the chroot environment.

# Exit when any command fails.
set -e

source utils.sh

pushdq .
  cd ../packages
  python ../scripts/download.py -f gettext.yaml
  python ../scripts/download.py -f bison.yaml
  python ../scripts/download.py -f perl.yaml
  python ../scripts/download.py -f python.yaml
  python ../scripts/download.py -f texinfo.yaml
  python ../scripts/download.py -f util-linux.yaml
popdq
