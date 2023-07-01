#!/usr/bin/env bash
#
# Builds Time Zone Data as part of the system software build.

# Exit when any command fails.
set -e

YAML_FILE=../tzdata.yaml
PKG_FILE=tzdata

pushdq .
  mkdir -pv "$LFS_SOURCES/$PKG_FILE"
  download -f $YAML_FILE -d "$LFS_SOURCES/$PKG_FILE"

  cd "$LFS_SOURCES/$PKG_FILE"

  ZONEINFO=/usr/share/zoneinfo
  mkdir -pv $ZONEINFO/{posix,right}
  for tz in etcetera southamerica northamerica europe africa antarctica  \
            asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
  done

  cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
  zic -d $ZONEINFO -p America/New_York
  unset ZONEINFO

  ln -sfv /usr/share/zoneinfo/America/New_York /etc/localtime
  mkdir -pv /etc/ld.so.conf.d

  cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
popdq
