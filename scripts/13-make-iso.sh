#!/usr/bin/env bash
set -Eeuo pipefail

# Assemble a bootable CarsonOS ISO from a completed LFS target root.
# GRUB's grub-mkrescue uses xorriso to create the ISO filesystem.

: "${LFS:=/mnt/carsonos}"
: "${OUTPUT_DIR:=$PWD/output}"
: "${ISO_NAME:=carsonos-blfs-x86_64.iso}"
: "${KERNEL_IMAGE:=}"

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run the ISO assembly stage as root.' >&2; exit 1; }
[[ -d "$LFS" ]] || { echo "LFS root does not exist: $LFS" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing required command: $1" >&2; exit 1; }; }
need_cmd grub-mkrescue
need_cmd xorriso
need_cmd cp
need_cmd find
need_cmd sha256sum

mkdir -p "$OUTPUT_DIR"
WORK="$(mktemp -d /tmp/carsonos-iso.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
ISO_ROOT="$WORK/iso"
mkdir -p "$ISO_ROOT/boot/grub"

# Put the completed target filesystem in the ISO. This first image is
# intentionally an inspectable root tree rather than a SquashFS live image.
mkdir -p "$ISO_ROOT/carsonos-root"
cp -a "$LFS"/. "$ISO_ROOT/carsonos-root/"

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

cat > "$ISO_ROOT/boot/grub/grub.cfg" <<'EOF'
set timeout=5
set default=0

menuentry 'CarsonOS BLFS' {
    linux /boot/vmlinuz-carsonos root=/dev/ram0 rw console=tty0
}

menuentry 'CarsonOS BLFS (safe mode)' {
    linux /boot/vmlinuz-carsonos root=/dev/ram0 rw nomodeset
}
EOF

grub-mkrescue -o "$OUTPUT_DIR/$ISO_NAME" "$ISO_ROOT"
[[ -s "$OUTPUT_DIR/$ISO_NAME" ]] || { echo 'ERROR: ISO was not created.' >&2; exit 1; }
sha256sum "$OUTPUT_DIR/$ISO_NAME" > "$OUTPUT_DIR/$ISO_NAME.sha256"
printf '\nCarsonOS ISO created successfully:\n  %s\n' "$OUTPUT_DIR/$ISO_NAME"
