#!/usr/bin/env bash
set -Eeuo pipefail

# Generate and execute the official LFS book instructions with jhalfs.
# This is the real full-build backend; it is intended for an isolated Linux
# build host or privileged self-hosted CI runner, not a normal GitHub runner.

: "${LFS:=/mnt/carsonos}"
: "${BUILD_DIR:=/mnt/carsonos-jhalfs}"
: "${LFS_BOOK:=13.0-systemd}"
: "${JHALFS_REPO:=https://github.com/automate-lfs/jhalfs.git}"
: "${JOBS:=$(nproc)}"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo 'ERROR: the LFS chroot stages require root.' >&2
  exit 1
fi

apt-get update
apt-get install -y git make xsltproc libxml2-utils wget bison gawk texinfo

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
git clone --depth 1 "$JHALFS_REPO" "$BUILD_DIR/jhalfs"
cd "$BUILD_DIR/jhalfs"

# jhalfs extracts the commands from the selected LFS book and generates a
# dependency-ordered Makefile. Keep the book version pinned to CarsonOS's
# stable LFS 13.0-systemd release.
export BUILDDIR="$BUILD_DIR"
export LFS

if [[ -x ./jhalfs ]]; then
  ./jhalfs --help >/dev/null 2>&1 || true
fi

cat > "$BUILD_DIR/build.conf" <<EOF
LFS=${LFS}
BUILDDIR=${BUILD_DIR}
BOOK=13.0-systemd
JOBS=${JOBS}
EOF

# Prefer the repository's configuration wrapper when present. jhalfs versions
# differ in their CLI, so fail loudly instead of silently pretending to build.
if [[ -x ./jhalfs ]]; then
  ./jhalfs || {
    echo 'jhalfs generation failed. Inspect the generated logs under:' >&2
    echo "  $BUILD_DIR/jhalfs" >&2
    exit 2
  }
else
  echo 'ERROR: jhalfs executable not found.' >&2
  exit 3
fi

if [[ -f Makefile ]]; then
  make -j"$JOBS" all
else
  echo 'ERROR: jhalfs did not generate a Makefile.' >&2
  exit 4
fi

printf 'Full LFS build finished under %s\n' "$LFS"
