#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config/lfs.conf"
cd "$SOURCES/diffutils-${DIFFUTILS_VERSION}"
./configure --prefix=/usr --host="$LFS_TGT" gl_cv_func_strcasecmp_works=y --build="$(./build-aux/config.guess)"
make
make DESTDIR="$LFS" install
