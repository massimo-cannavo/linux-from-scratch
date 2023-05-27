#!/usr/bin/env bash
#
# Downloads MPC dependency for GCC.

# Exit when any command fails.
set -e

PKG_FILE="$(
  grep 'source:' ../mpc.yaml \
    | cut -d ':' -f 2-3      \
    | xargs basename         \
    | sed 's/\.tar\.gz//g'
)"
readonly PKG_FILE

python "$SCRIPTS_PATH/download.py" -f ../mpc.yaml
mv -v "$PKG_FILE" mpc
