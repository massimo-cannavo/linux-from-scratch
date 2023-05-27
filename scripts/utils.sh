#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# Code to be sourced by other scripts.

readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
readonly BLUE="\033[1;34m"
readonly RESET="\033[m"

ARCH=$(uname -m)
readonly ARCH

is_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ ERROR ]${RESET} run as root"
    exit 1
  fi
}

pushdq() {
  pushd "$@" > /dev/null || exit
}

popdq() {
  popd > /dev/null || exit
}
