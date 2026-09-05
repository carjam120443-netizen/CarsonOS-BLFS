#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config/lfs.conf"
cd "$SOURCES/ncurses-${NCURSES_VERSION}"
rm -rf build
mkdir build && pushd build
../configure --prefix="$LFS/tools" AWK=gawk
make -C include
make -C progs tic
install progs/tic "$LFS/tools/bin"
popd
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)" --mandir=/usr/share/man --with-manpage-format=normal --with-shared --without-normal --with-cxx-shared --without-debug --without-ada --disable-stripping AWK=gawk
make
make DESTDIR="$LFS" install
ln -sfv libncursesw.so "$LFS/usr/lib/libncurses.so"
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "$LFS/usr/include/curses.h"
