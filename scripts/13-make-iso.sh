#!/usr/bin/env bash
set -Eeuo pipefail

# Build a bootable CarsonOS live ISO and optional VirtualBox VDI.
# The ISO contains the completed LFS root as a compressed initramfs, so the
# Linux kernel can unpack it and execute /init directly. This is intentionally
# a first live-image implementation; a future release can switch to SquashFS.

: "${LFS:=/mnt/carsonos}"
: "${OUTPUT_DIR:=$PWD/output}"
: "${ISO_NAME:=carsonos-blfs-x86_64.iso}"
: "${VDI_NAME:=carsonos-blfs-x86_64.vdi}"
: "${KERNEL_IMAGE:=}"
: "${DISK_SIZE_MB:=8192}"

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run the ISO assembly stage as root.' >&2; exit 1; }
[[ -d "$LFS" ]] || { echo "LFS root does not exist: $LFS" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing required command: $1" >&2; exit 1; }; }
for cmd in grub-mkrescue xorriso cpio gzip cp find sha256sum; do need_cmd "$cmd"; done

mkdir -p "$OUTPUT_DIR"
WORK="$(mktemp -d /tmp/carsonos-iso.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
ISO_ROOT="$WORK/iso"
INITRAMFS_ROOT="$WORK/initramfs"
mkdir -p "$ISO_ROOT/boot/grub" "$INITRAMFS_ROOT"

if [[ -n "$KERNEL_IMAGE" ]]; then
  [[ -f "$KERNEL_IMAGE" ]] || { echo "Kernel not found: $KERNEL_IMAGE" >&2; exit 1; }
  cp -L "$KERNEL_IMAGE" "$ISO_ROOT/boot/vmlinuz-carsonos"
elif compgen -G "$LFS/boot/vmlinuz*" >/dev/null; then
  KERNEL_SRC="$(find "$LFS/boot" -maxdepth 1 -type f -name 'vmlinuz*' | sort | head -n1)"
  cp -L "$KERNEL_SRC" "$ISO_ROOT/boot/vmlinuz-carsonos"
elif [[ -f "$LFS/boot/bzImage" ]]; then
  cp -L "$LFS/boot/bzImage" "$ISO_ROOT/boot/vmlinuz-carsonos"
else
  echo "ERROR: no kernel image found under $LFS/boot." >&2
  exit 1
fi

# Build an initramfs containing the CarsonOS root filesystem. /init switches
# from the temporary initramfs environment into the unpacked root tree.
cp -a "$LFS"/. "$INITRAMFS_ROOT/"
mkdir -p "$INITRAMFS_ROOT/dev" "$INITRAMFS_ROOT/proc" "$INITRAMFS_ROOT/sys" "$INITRAMFS_ROOT/run"
cat > "$INITRAMFS_ROOT/init" <<'EOF'
#!/bin/bash
set -eu

mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true

# The complete CarsonOS root is already the initramfs root. Hand control to
# systemd when available, otherwise fall back to a shell for diagnostics.
if [ -x /sbin/init ]; then
    exec /sbin/init
fi
if [ -x /bin/bash ]; then
    echo 'CarsonOS: /sbin/init was not found; starting emergency shell.'
    exec /bin/bash
fi

echo 'CarsonOS: no init program was found.'
exec /bin/sh
EOF
chmod 0755 "$INITRAMFS_ROOT/init"

# Avoid stale package-manager/build state that does not belong in a live ISO.
rm -rf "$INITRAMFS_ROOT/sources" "$INITRAMFS_ROOT/build" 2>/dev/null || true

(
  cd "$INITRAMFS_ROOT"
  find . -print0 | cpio --null -o -H newc 2>/dev/null | gzip -9 > "$ISO_ROOT/boot/carsonos-initramfs.img"
)

cat > "$ISO_ROOT/boot/grub/grub.cfg" <<'EOF'
set timeout=5
set default=0

menuentry 'CarsonOS BLFS (Live)' {
    linux /boot/vmlinuz-carsonos loglevel=4
    initrd /boot/carsonos-initramfs.img
}

menuentry 'CarsonOS BLFS (safe mode)' {
    linux /boot/vmlinuz-carsonos nomodeset loglevel=4
    initrd /boot/carsonos-initramfs.img
}
EOF

grub-mkrescue -o "$OUTPUT_DIR/$ISO_NAME" "$ISO_ROOT"
[[ -s "$OUTPUT_DIR/$ISO_NAME" ]] || { echo 'ERROR: ISO was not created.' >&2; exit 1; }
sha256sum "$OUTPUT_DIR/$ISO_NAME" > "$OUTPUT_DIR/$ISO_NAME.sha256"

# Also create a VirtualBox-compatible VDI when VBoxManage is available.
# The VDI is built from a simple ext4 filesystem image containing the same
# CarsonOS root tree; GRUB is installed into the image in a later disk-image
# hardening step. For now, the ISO remains the canonical boot artifact.
if command -v VBoxManage >/dev/null 2>&1 && command -v mkfs.ext4 >/dev/null 2>&1 && command -v mount >/dev/null 2>&1; then
  RAW="$WORK/carsonos.raw"
  truncate -s "${DISK_SIZE_MB}M" "$RAW"
  mkfs.ext4 -F "$RAW" >/dev/null
  MOUNT_DIR="$WORK/disk"
  mkdir -p "$MOUNT_DIR"
  mount -o loop "$RAW" "$MOUNT_DIR"
  cp -a "$LFS"/. "$MOUNT_DIR"/
  mkdir -p "$MOUNT_DIR/boot"
  cp -L "$ISO_ROOT/boot/vmlinuz-carsonos" "$MOUNT_DIR/boot/"
  sync
  umount "$MOUNT_DIR"
  VBoxManage convertfromraw "$RAW" "$OUTPUT_DIR/$VDI_NAME" --format VDI --variant Standard
  sha256sum "$OUTPUT_DIR/$VDI_NAME" > "$OUTPUT_DIR/$VDI_NAME.sha256"
  printf '\nVirtualBox VDI created:\n  %s\n' "$OUTPUT_DIR/$VDI_NAME"
else
  echo 'VBoxManage/mkfs.ext4/mount unavailable; skipping VDI generation.'
fi

printf '\nCarsonOS live ISO created successfully:\n  %s\n' "$OUTPUT_DIR/$ISO_NAME"
printf 'Checksum:\n  %s\n' "$OUTPUT_DIR/$ISO_NAME.sha256"
