#!/usr/bin/env bash
set -euo pipefail

# Prepare the directory layout for the LFS build.
# This script intentionally does not format disks, mount arbitrary devices,
# create partitions, or modify the host system. Those operations stay manual.

ROOT_DIR="${LFS:-/mnt/carsonos}"
SOURCES_DIR="${SOURCES:-$ROOT_DIR/sources}"
BUILD_DIR="${BUILD:-$ROOT_DIR/build}"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run this preparation script as root."
  echo "Create the build location with appropriate permissions first."
  exit 1
fi

mkdir -p "$SOURCES_DIR" "$BUILD_DIR" "$ROOT_DIR/logs"
chmod 1777 "$SOURCES_DIR"

echo "== CarsonOS BLFS LFS preparation =="
echo "LFS root: $ROOT_DIR"
echo "Sources:  $SOURCES_DIR"
echo "Build:    $BUILD_DIR"
echo
echo "Directories prepared."
echo "Next: populate sources from the pinned LFS package manifest."
