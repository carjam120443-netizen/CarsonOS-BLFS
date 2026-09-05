#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config/lfs.conf"
cd "$SOURCES/findutils-${FINDUTILS_VERSION}"
./configure --prefix=/usr --localstatedir=/var/lib/locate --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make
make DESTDIR="$LFS" install
