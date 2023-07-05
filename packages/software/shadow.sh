#!/usr/bin/env bash
#
# Builds Shadow as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../shadow.yaml
PKG_FILE=$(yaml -f $YAML_FILE -q package)

download -f $YAML_FILE -d "$LFS_SOURCES"
pushdq .
  cd "$LFS_SOURCES/$PKG_FILE"
  #shellcheck disable=SC2016
  sed -i 's/groups$(EXEEXT) //' src/Makefile.in

  find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
  find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
  find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

  sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
      -e 's@#\(SHA_CRYPT_..._ROUNDS 5000\)@\100@'       \
      -e 's:/var/spool/mail:/var/mail:'                 \
      -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                \
      -i etc/login.defs

  touch /usr/bin/passwd
  ./configure --sysconfdir=/etc               \
              --disable-static                \
              --with-group-name-max-length=32

  make -j"$(nproc)"
  make exec_prefix=/usr install
  make -C man install-man

  pwconv
  grpconv

  mkdir -p /etc/default
  useradd -D --gid 999
popdq
