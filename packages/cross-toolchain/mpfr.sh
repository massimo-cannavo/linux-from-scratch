#!/usr/bin/env bash
#
# Downloads MPFR dependency for GCC.

# Exit when any command fails.
set -e

PKG_FILE="$(
  grep 'source:' ../mpfr.yaml \
    | cut -d ':' -f 2-3      \
    | xargs basename         \
    | sed 's/\.tar\.xz//g'
)"
readonly PKG_FILE

python "$SCRIPTS_PATH/download.py" -f ../mpfr.yaml
mv -v "$PKG_FILE" mpfr
