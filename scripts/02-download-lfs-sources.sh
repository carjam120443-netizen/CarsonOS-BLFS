#!/usr/bin/env bash
set -euo pipefail

# Download the exact package set published for LFS 13.0-systemd.
# The upstream wget-list is used instead of guessing individual source URLs.

ROOT_DIR="${LFS:-/mnt/carsonos}"
SOURCES_DIR="${SOURCES:-$ROOT_DIR/sources}"
WGET_LIST_URL="https://www.linuxfromscratch.org/lfs/downloads/13.0-systemd/wget-list"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run this script as the normal LFS build user, not root."
  exit 1
fi

mkdir -p "$SOURCES_DIR"
cd "$SOURCES_DIR"

if command -v wget >/dev/null 2>&1; then
  wget --continue --input-file="$WGET_LIST_URL"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$WGET_LIST_URL" | while read -r url; do
    [[ -z "$url" ]] && continue
    curl -fL -C - -O "$url"
  done
else
  echo "ERROR: wget or curl is required."
  exit 1
fi

echo "LFS source download complete."
