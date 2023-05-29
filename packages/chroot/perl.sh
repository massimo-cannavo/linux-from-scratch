#!/usr/bin/env bash
#
# Builds Perl as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../perl.yaml
PKG_FILE="$(
  grep 'source:' $YAML_FILE \
    | cut -d ':' -f 2-3     \
    | xargs basename        \
    | sed 's/\.tar\.xz//g'
)"
VERSION=$(
  grep 'version:' $YAML_FILE \
    | cut -d ':' -f 2-3      \
    | sed 's/"//g'           \
    | xargs                  \
    | cut -d '.' -f 1-2
)
MAJOR_VERSION="$(echo "$VERSION" | cut -d '.' -f 1)"
PERL_LIB=/usr/lib/perl$MAJOR_VERSION/$VERSION

pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  sh Configure -des                                 \
               -Dprefix=/usr                        \
               -Dvendorprefix=/usr                  \
               -Dprivlib="$PERL_LIB/core_perl"      \
               -Darchlib="$PERL_LIB/core_perl"      \
               -Dsitelib="$PERL_LIB/site_perl"      \
               -Dsitearch="$PERL_LIB/site_perl"     \
               -Dvendorlib="$PERL_LIB/vendor_perl"  \
               -Dvendorarch="$PERL_LIB/vendor_perl"

  make -j"$(nproc)"
  make install
popdq
