#!/usr/bin/env bash
set -euo pipefail

# CarsonOS BLFS - LFS 13.0-systemd
# Chapter 5: Linux API Headers

: "${LFS:?Set LFS to the target filesystem root}"
: "${LFS_TGT:?Set LFS_TGT to the target triplet}"
: "${LFS_SRC:?Set LFS_SRC to the source directory}"

KERNEL_VERSION="6.18.10"
SRC="$LFS_SRC/linux-${KERNEL_VERSION}"

if [[ ! -d "$SRC" ]]; then
  echo "Missing Linux source: $SRC" >&2
  exit 1
fi

cd "$SRC"
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include "$LFS/usr/"

echo "Linux API headers installed into $LFS/usr/include"
