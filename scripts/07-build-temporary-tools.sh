#!/usr/bin/env bash
set -euo pipefail

# CarsonOS BLFS - LFS 13.0-systemd Chapter 6 dispatcher
# This script intentionally delegates each package to the official LFS
# build instructions. It verifies the environment and source tree, then
# invokes the package scripts in order.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/config/lfs.conf"

: "${LFS:?LFS must be set}"
: "${SOURCES:?SOURCES must be set}"
: "${LFS_TGT:?LFS_TGT must be set by the LFS build environment}"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/tools/bin:${PATH}"
export LC_ALL=POSIX

packages=(
  m4
  ncurses
  bash
  coreutils
  diffutils
  file
  findutils
  gawk
  grep
  gzip
  make
  patch
  sed
  tar
  xz
  binutils-pass2
  gcc-pass2
)

usage() {
  cat <<EOF
Usage: $0 [all|package ...]

Builds the LFS 13.0-systemd Chapter 6 temporary tools in order.

Packages:
  ${packages[*]}

Examples:
  $0 all
  $0 m4 ncurses bash
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

run_step() {
  local name="$1"
  local script="$ROOT_DIR/scripts/chapter6/${name}.sh"
  [[ -x "$script" ]] || chmod +x "$script"
  echo
  echo "===== CarsonOS BLFS: $name ====="
  "$script"
}

if [[ "$1" == "all" ]]; then
  for pkg in "${packages[@]}"; do
    run_step "$pkg"
  done
  exit 0
fi

for pkg in "$@"; do
  case "$pkg" in
    m4|ncurses|bash|coreutils|diffutils|file|findutils|gawk|grep|gzip|make|patch|sed|tar|xz|binutils-pass2|gcc-pass2)
      run_step "$pkg" ;;
    *)
      echo "Unknown package: $pkg" >&2
      usage
      exit 2 ;;
  esac
done
