#!/usr/bin/env bash
#
# Downloads GMP dependency for GCC.

# Exit when any command fails.
set -e

PKG_FILE="$(
  grep 'source:' ../gmp.yaml \
    | cut -d ':' -f 2-3      \
    | xargs basename         \
    | sed 's/\.tar\.xz//g'
)"
readonly PKG_FILE

python "$SCRIPTS_PATH/download.py" -f ../gmp.yaml
mv -v "$PKG_FILE" gmp
