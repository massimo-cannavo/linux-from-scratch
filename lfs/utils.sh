#!/usr/bin/env bash
#
# Code to be sourced by other scripts.

# shellcheck disable=SC2034
readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
readonly BLUE="\033[1;34m"
readonly RESET="\033[m"

is_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}run as root${RESET}"
    exit 1
  fi
}
