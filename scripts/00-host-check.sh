#!/usr/bin/env bash
set -euo pipefail

# Preliminary host checker for CarsonOS BLFS.
# Exact requirements will be pinned to the selected LFS release before the
# complete toolchain build is enabled.

required=(
  bash
  bison
  gcc
  g++
  make
  perl
  python3
  tar
  xz
  gzip
  bzip2
  wget
  git
  awk
  sed
  grep
  patch
  texinfo
)

missing=()
for command in "${required[@]}"; do
  if ! command -v "$command" >/dev/null 2>&1; then
    missing+=("$command")
  fi
done

echo "== CarsonOS BLFS host check =="
echo "Architecture: $(uname -m)"
echo "Kernel:      $(uname -sr)"
echo

if ((${#missing[@]})); then
  echo "Missing host tools:"
  printf '  - %s\n' "${missing[@]}"
  echo
  echo "Install the missing tools using your host distribution's package manager."
  exit 1
fi

echo "All preliminary host tools are present."
echo "NOTE: This is not yet a complete LFS host-requirements check."
