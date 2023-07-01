#!/usr/bin/env bash
#
# Builds Glibc as part of the cross-compiler build.

# Exit when any command fails.
set -e

YAML_FILE=../glibc.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)
PATCHES=$(yaml -f $YAML_FILE -q .patches)

download -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  case $(uname -m) in
    i?86)
      ln -sfv ld-linux.so.2 "$LFS/lib/ld-lsb.so.3"
      ;;
    x86_64)
      ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64"
      ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64/ld-lsb-x86-64.so.3"
      ;;
  esac

  for patch in $PATCHES; do
    patch_file=$(echo "$patch" | xargs basename)
    patch -Np1 -i "../$patch_file"
  done

  mkdir -pv build
  cd build
  echo "rootsbindir=/usr/sbin" > configparms
  ../configure --prefix=/usr                        \
               --host="$LFS_TGT"                    \
               --build="$(../scripts/config.guess)" \
               --enable-kernel=3.2                  \
               --with-headers="$LFS/usr/include"    \
               libc_cv_slibdir=/usr/lib

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
  sed '/RTLDLIST=/s@/usr@@g' -i "$LFS/usr/bin/ldd"

  echo 'int main(){}' | "$LFS_TGT-gcc" -xc -
  readelf -l a.out | grep ld-linux
  rm -v a.out

  "$LFS/tools/libexec/gcc/$LFS_TGT/12.2.0/install-tools/mkheaders"
  for patch in $PATCHES; do
    patch_file=$(echo "$patch" | xargs basename)
    patch -Rp1 -i "../$patch_file"
  done
popdq
