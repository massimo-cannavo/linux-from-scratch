#!/usr/bin/env bash
# shellcheck disable=SC1091
#
# Builds GCC Pass 2 as part of the Cross Compiling temporary tools.

# Exit when any command fails.
set -e

SCRIPTS=$(realpath ../../scripts)
export SCRIPTS
export CROSS_TOOLCHAIN=$PWD/../cross-toolchain

YAML_FILE=../gcc.yaml
PKG_FILE=$(python ../../scripts/pyaml.py -f $YAML_FILE -q package)

python ../../scripts/download.py -f $YAML_FILE
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

  sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

  mkdir -pv build-pass2
  cd build-pass2

  ../configure --host="$LFS_TGT"            \
               --build="$(../config.guess)" \
               --target="$LFS_TGT"          \
               --prefix=/usr                \
               --with-build-sysroot="$LFS"  \
               --enable-default-pie         \
               --enable-default-ssp         \
               --disable-nls                \
               --disable-multilib           \
               --disable-libatomic          \
               --disable-libgomp            \
               --disable-libquadmath        \
               --disable-libssp             \
               --disable-libvtv             \
               --enable-languages=c,c++     \
              LDFLAGS_FOR_TARGET="-L$PWD/$LFS_TGT/libgcc"

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
  ln -sv gcc "$LFS/usr/bin/cc"
popdq
