#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config/lfs.conf"
cd "$SOURCES/file-${FILE_VERSION}"
rm -rf build
mkdir build && pushd build
../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib
make
popd
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)"
make FILE_COMPILE="$(pwd)/build/src/file"
make DESTDIR="$LFS" install
rm -f "$LFS/usr/lib/libmagic.la"
