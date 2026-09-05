#!/usr/bin/env bash
set -Eeuo pipefail

# Verify the host has the tools required by the ISO assembly stage.
for cmd in grub-mkrescue xorriso file sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing ISO build dependency: $cmd" >&2
    exit 1
  }
done

echo 'ISO build dependencies are available.'
