#!/usr/bin/env bash
set -euo pipefail

# CarsonOS BLFS - LFS 13.0-systemd
# Chapter 5: Libstdc++ from GCC

: "${LFS:?Set LFS to the target filesystem root}"
: "${LFS_TGT:?Set LFS_TGT to the target triplet}"
: "${LFS_SRC:?Set LFS_SRC to the source directory}"

GCC_VERSION="15.2.0"
SRC="$LFS_SRC/gcc-${GCC_VERSION}"
BUILD="$LFS_SRC/gcc-build-libstdcxx"

if [[ ! -d "$SRC" ]]; then
  echo "Missing GCC source: $SRC" >&2
  exit 1
fi

rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"

# Build only the C++ standard library against the cross-built Glibc.
"$SRC/libstdc++-v3/configure" \
  CXXFLAGS="-g0 -O2" \
  --host="$LFS_TGT" \
  --build="$(../gcc-${GCC_VERSION}/config.guess)" \
  --prefix=/usr \
  --disable-multilib \
  --disable-nls \
  --disable-libstdcxx-pch \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/$GCC_VERSION

make
make DESTDIR="$LFS" install

if [[ ! -e "$LFS/usr/lib/libstdc++.so" ]]; then
  echo "Libstdc++ installation verification failed." >&2
  exit 1
fi

echo "Libstdc++ installed into $LFS"
