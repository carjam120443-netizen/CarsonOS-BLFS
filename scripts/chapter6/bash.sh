#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config/lfs.conf"
cd "$SOURCES/bash-${BASH_VERSION}"
./configure --prefix=/usr --build="$(sh support/config.guess)" --host="$LFS_TGT" --without-bash-malloc
make
make DESTDIR="$LFS" install
ln -sfv bash "$LFS/bin/sh"
