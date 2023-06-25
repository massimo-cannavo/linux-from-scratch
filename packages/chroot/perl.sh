#!/usr/bin/env bash
#
# Builds Perl as part of the chroot temporary tools.

# Exit when any command fails.
set -e

YAML_FILE=../perl.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)
VERSION=$(yaml -f $YAML_FILE -q .version)
MAJOR_VERSION="$(echo "$VERSION" | cut -d '.' -f 1)"

PERL_LIB=/usr/lib/perl$MAJOR_VERSION/$VERSION
download -f $YAML_FILE -d "$LFS_SOURCES"
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
