#!/usr/bin/env bash
#
# Builds GCC Pass 1 as part of the cross-compiler build.

# Exit when any command fails.
set -e

SCRIPTS=$(realpath ../../scripts)
export SCRIPTS
export CROSS_TOOLCHAIN=$PWD

YAML_FILE=../gcc.yaml
PKG_FILE=$(python "$SCRIPTS/pyaml.py" -f $YAML_FILE -q package)
GLIBC_VERSION=$(
  python "$SCRIPTS/pyaml.py" \
    -f ../glibc.yaml         \
    -q .version
)

python "$SCRIPTS/download.py" -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  source "$CROSS_TOOLCHAIN/gmp.sh"
  source "$CROSS_TOOLCHAIN/mpc.sh"
  source "$CROSS_TOOLCHAIN/mpfr.sh"

  case $ARCH in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
      ;;
  esac

  mkdir -pv build
  cd build

  ../configure --target="$LFS_TGT"                   \
               --prefix="$LFS/tools"                 \
               --with-glibc-version="$GLIBC_VERSION" \
               --with-sysroot="$LFS"                 \
               --with-newlib                         \
               --without-headers                     \
               --enable-default-pie                  \
               --enable-default-ssp                  \
               --disable-nls                         \
               --disable-shared                      \
               --disable-multilib                    \
               --disable-threads                     \
               --disable-libatomic                   \
               --disable-libgomp                     \
               --disable-libquadmath                 \
               --disable-libssp                      \
               --disable-libvtv                      \
               --disable-libstdcxx                   \
               --enable-languages=c,c++

  make -j"$(nproc)"
  make install

  cd ../
  libgcc_file=$("$LFS_TGT"-gcc -print-libgcc-file-name)
  cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    "$(dirname "$libgcc_file")/install-tools/include/limits.h"
popdq
