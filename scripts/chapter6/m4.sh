#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config/lfs.conf"
cd "$SOURCES/m4-${M4_VERSION}"
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make
make DESTDIR="$LFS" install
