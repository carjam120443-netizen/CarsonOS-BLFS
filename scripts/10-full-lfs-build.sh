#!/usr/bin/env bash
set -Eeuo pipefail

# Full CarsonOS LFS 13.0-systemd build orchestrator.
# Run this on a disposable Linux VM/host as root. It deliberately does not
# run automatically on pull requests; the GitHub workflow exposes it through
# workflow_dispatch on a sufficiently provisioned self-hosted runner.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/config/lfs.conf"

: "${LFS:=/mnt/carsonos}"
: "${SOURCES:=$LFS/sources}"
: "${BUILD:=$LFS/build}"
export LFS SOURCES BUILD

log(){ printf '\n==== %s ====\n' "$*"; }
need_root(){ [[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run the full build as root.' >&2; exit 1; }; }
run(){ log "$*"; "$@"; }

need_root
mkdir -p "$LFS" "$SOURCES" "$BUILD"

log 'Validating host'
"$ROOT_DIR/scripts/00-host-check.sh"

log 'Preparing LFS filesystem and sources'
"$ROOT_DIR/scripts/01-prepare-lfs.sh"
"$ROOT_DIR/scripts/02-download-lfs-sources.sh"

log 'Building Chapter 5/6 bootstrap toolchain'
"$ROOT_DIR/scripts/03-build-toolchain-pass1.sh"
"$ROOT_DIR/scripts/04-linux-headers.sh"
"$ROOT_DIR/scripts/05-glibc.sh"
"$ROOT_DIR/scripts/06-libstdcxx.sh"
"$ROOT_DIR/scripts/07-build-temporary-tools.sh"

log 'Entering Chapter 7/8/9/10 full-system build'
if [[ -x "$ROOT_DIR/scripts/11-chroot-lfs.sh" ]]; then
  "$ROOT_DIR/scripts/11-chroot-lfs.sh"
else
  echo 'ERROR: scripts/11-chroot-lfs.sh is not present yet.' >&2
  echo 'The bootstrap stages completed; Chapter 7-10 package recipes must be generated before this stage can safely run.' >&2
  exit 2
fi

log 'Installing CarsonOS Porg package manager'
if [[ -x "$ROOT_DIR/scripts/12-install-porg.sh" ]]; then
  "$ROOT_DIR/scripts/12-install-porg.sh"
else
  echo 'ERROR: scripts/12-install-porg.sh is not present yet.' >&2
  exit 2
fi

log 'Full LFS build completed'
printf 'Target root: %s\n' "$LFS"
