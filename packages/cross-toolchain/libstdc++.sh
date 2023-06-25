#!/usr/bin/env bash
#
# Builds Libstdc++ as part of the cross-compiler build.

# Exit when any command fails.
set -e

YAML_FILE=../libstdc++.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)
GCC_VERSION=$(yaml -f ../gcc.yaml -q .version)

download -f $YAML_FILE
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  mkdir -v build-libstdc++
  cd build-libstdc++

  ../libstdc++-v3/configure --host="$LFS_TGT"            \
                            --build="$(../config.guess)" \
                            --prefix=/usr                \
                            --disable-multilib           \
                            --disable-nls                \
                            --disable-libstdcxx-pch      \
                            --with-gxx-include-dir="/tools/$LFS_TGT/include/c++/$GCC_VERSION"

  make -j"$(nproc)"
  make DESTDIR="$LFS" install
  rm -v "$LFS"/usr/lib/lib{stdc++,stdc++fs,supc++}.la
popdq
