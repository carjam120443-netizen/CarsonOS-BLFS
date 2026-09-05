#!/usr/bin/env bash
set -euo pipefail

# CarsonOS BLFS - LFS 13.0-systemd
# Chapter 5: Glibc

: "${LFS:?Set LFS to the target filesystem root}"
: "${LFS_TGT:?Set LFS_TGT to the target triplet}"
: "${LFS_SRC:?Set LFS_SRC to the source directory}"

GLIBC_VERSION="2.43"
SRC="$LFS_SRC/glibc-${GLIBC_VERSION}"
BUILD="$LFS_SRC/glibc-build"

if [[ ! -d "$SRC" ]]; then
  echo "Missing Glibc source: $SRC" >&2
  exit 1
fi

rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"

printf '%s\n' "rootsbindir=/usr/sbin" > configparms

"$SRC/configure" \
  --prefix=/usr \
  --host="$LFS_TGT" \
  --build="$(../glibc-${GLIBC_VERSION}/scripts/config.guess)" \
  --enable-kernel=6.1 \
  --with-headers="$LFS/usr/include" \
  libc_cv_slibdir=/usr/lib

make
make DESTDIR="$LFS" install

# Verify the target loader and libc were produced.
if [[ ! -e "$LFS/usr/lib/libc.so.6" ]]; then
  echo "Glibc installation verification failed." >&2
  exit 1
fi

echo "Glibc installed into $LFS"
