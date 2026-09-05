#!/usr/bin/env bash
set -euo pipefail

# CarsonOS BLFS — LFS Chapter 5 bootstrap
#
# This begins the isolated cross-toolchain described by LFS 13.0-systemd.
# It deliberately stops after Binutils Pass 1 and GCC Pass 1 so each stage
# can be tested before the next stage is enabled.

ROOT_DIR="${LFS:-/mnt/carsonos}"
SOURCES_DIR="${SOURCES:-$ROOT_DIR/sources}"
BUILD_DIR="${BUILD:-$ROOT_DIR/build}"
TARGET="${TARGET:-x86_64-carsonos-linux-gnu}"
JOBS="${JOBS:-$(nproc)}"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run the temporary toolchain as root."
  exit 1
fi

source "$(dirname "$0")/../config/lfs.conf"

mkdir -p "$BUILD_DIR" "$ROOT_DIR/tools"

if [[ ! -d "$SOURCES_DIR" ]]; then
  echo "ERROR: source directory does not exist: $SOURCES_DIR"
  echo "Run 01-prepare-lfs.sh and 02-download-lfs-sources.sh first."
  exit 1
fi

export LFS="$ROOT_DIR"
export PATH="$ROOT_DIR/tools/bin:$PATH"
export LC_ALL=POSIX
export CONFIG_SITE=/dev/null
export MAKEFLAGS="-j$JOBS"

PREFIX="$ROOT_DIR/tools"

BINUTILS_TARBALL="$SOURCES_DIR/binutils-${BINUTILS_VERSION}.tar.xz"
GCC_TARBALL="$SOURCES_DIR/gcc-${GCC_VERSION}.tar.xz"

[[ -f "$BINUTILS_TARBALL" ]] || { echo "Missing $BINUTILS_TARBALL"; exit 1; }
[[ -f "$GCC_TARBALL" ]] || { echo "Missing $GCC_TARBALL"; exit 1; }

build_binutils() {
  echo "== Building Binutils ${BINUTILS_VERSION} — Pass 1 =="
  rm -rf "$BUILD_DIR/binutils-${BINUTILS_VERSION}"
  tar -xf "$BINUTILS_TARBALL" -C "$BUILD_DIR"
  cd "$BUILD_DIR/binutils-${BINUTILS_VERSION}"

  mkdir -p build
  cd build
  ../configure \
    --prefix="$PREFIX" \
    --with-sysroot="$ROOT_DIR" \
    --target="$TARGET" \
    --disable-nls \
    --disable-werror
  make
  make install
}

build_gcc() {
  echo "== Building GCC ${GCC_VERSION} — Pass 1 =="
  rm -rf "$BUILD_DIR/gcc-${GCC_VERSION}"
  tar -xf "$GCC_TARBALL" -C "$BUILD_DIR"
  cd "$BUILD_DIR/gcc-${GCC_VERSION}"

  tar -xf "$SOURCES_DIR/mpfr-4.2.2.tar.xz"
  tar -xf "$SOURCES_DIR/gmp-6.3.0.tar.xz"
  tar -xf "$SOURCES_DIR/mpc-1.3.1.tar.gz"
  mv mpfr-* mpfr
  mv gmp-* gmp
  mv mpc-* mpc

  mkdir -p build
  cd build
  ../configure \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --with-glibc-version="$GLIBC_VERSION" \
    --with-sysroot="$ROOT_DIR" \
    --with-newlib \
    --without-headers \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-decimal-float \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++
  make
  make install
}

build_binutils
build_gcc

echo
echo "Temporary cross-toolchain Pass 1 complete."
echo "Next stages: Linux API headers, Glibc, Libstdc++, then temporary tools."
