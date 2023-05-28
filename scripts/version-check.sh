#!/usr/bin/env bash
# shellcheck disable=SC2185
#
# Simple script to check that the host system has all the appropriate versions.

source utils.sh

# The C locale is a special locale that is meant to be the simplest locale.
# Avoids the user's settings to interfere with the script.
export LC_ALL=C
bash --version | head -n1 | cut -d" " -f1-4

SH_LINK=$(readlink -f /bin/sh)
echo "/bin/sh -> $SH_LINK"
echo "$SH_LINK" | grep -q bash \
  || echo -e "${RED}ERROR: /bin/sh does not point to bash${RESET}"

echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1

if [[ -h /usr/bin/yacc ]]; then
  echo -e "/usr/bin/yacc -> ${GREEN}$(readlink -f /usr/bin/yacc)${RESET}"
elif [[ -x /usr/bin/yacc ]]; then
  echo -e "yacc is ${GREEN}$(/usr/bin/yacc --version | head -n1)${RESET}"
else
  echo -e "${RED}yacc not found${RESET}"
fi

echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1

if [[ -h /usr/bin/awk ]]; then
  echo -e "/usr/bin/awk -> ${GREEN}$(readlink -f /usr/bin/awk)${RESET}"
elif [[ -x /usr/bin/awak ]]; then
  echo -e "awk is ${GREEN}$(/usr/bin/awk --version | head -n1)${RESET}"
else
  echo -e "${RED}awk not found${RESET}"
fi

parted --version | head -n1
cryptsetup --version | cut -d" " -f1-2
gcc --version | head -n1
g++ --version | head -n1
grep --version | head -n1
gzip --version | head -n1
uname -srv
m4 --version | head -n1
make --version | head -n1
patch --version | head -n1
echo Perl "$(perl -V:version)"
python3 --version
sed --version | head -n1
tar --version | head -n1
makeinfo --version | head -n1
xz --version | head -n1
yq --version

echo "int main(){}" > dummy.c && g++ -o dummy dummy.c
if [[ -x dummy ]]; then
  echo -e "g++ compilation ${GREEN}OK${RESET}"
else
  echo -e "g++ compilation ${RED}FAILED${RESET}"
fi

rm -f dummy.c dummy
