#!/usr/bin/env bash
set -Eeuo pipefail

# Install Porg into the target CarsonOS root. Porg is used as CarsonOS's
# source-install package database/tracker; the CarsonOS wrapper adds a stable
# package-manager command interface around it.

: "${LFS:=/mnt/carsonos}"
: "${PORG_VERSION:=0.10}"
: "${SOURCES:=$LFS/sources}"

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run as root.' >&2; exit 1; }
mkdir -p "$SOURCES" "$LFS/var/lib/porg"
cd "$SOURCES"

URL="https://downloads.sourceforge.net/project/porg/porg-${PORG_VERSION}.tar.gz"
TARBALL="porg-${PORG_VERSION}.tar.gz"

if [[ ! -f "$TARBALL" ]]; then
  wget -O "$TARBALL" "$URL"
fi

tar -xf "$TARBALL"
cd "porg-${PORG_VERSION}"

./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make -j"$(nproc)"

# DESTDIR keeps this bootstrap install inside the CarsonOS target root.
make DESTDIR="$LFS" install

mkdir -p "$LFS/var/lib/porg"
cat > "$LFS/etc/porgrc" <<EOF
LOGDIR=/var/lib/porg
EOF

cat > "$LFS/usr/bin/carson-pkg" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

case "${1:-}" in
  install)
    shift
    exec porg -l -p "${1##*/}" -- "$@"
    ;;
  list)
    exec porg -a
    ;;
  info)
    shift
    exec porg -i "$@"
    ;;
  files)
    shift
    exec porg -l "$@"
    ;;
  remove|uninstall)
    shift
    exec porg -r "$@"
    ;;
  query)
    shift
    exec porg -q "$@"
    ;;
  version)
    exec porg --version
    ;;
  *)
    echo 'CarsonOS package manager (Porg backend)'
    echo 'Usage: carson-pkg {install|list|info|files|remove|query|version} ...'
    exit 2
    ;;
esac
EOF
chmod 0755 "$LFS/usr/bin/carson-pkg"

rm -rf "$SOURCES/porg-${PORG_VERSION}"
printf 'Porg %s installed as the CarsonOS package-management backend.\n' "$PORG_VERSION"
