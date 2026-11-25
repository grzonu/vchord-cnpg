#!/bin/sh
# Lays out one vchord release for one PostgreSQL major as the root of an extension image:
#   <out>/<arch>/lib/                 vchord.so, the dynamic_library_path
#   <out>/<arch>/share/extension/     control and SQL files, under the extension_control_path
#   <out>/<arch>/licenses/vchord/     the upstream licence
# Every archive is checked against the .sha256 the release publishes next to it.
set -eu

version=$1
pg=$2
out=$3

base="https://github.com/pgsty/vchord/releases/download/$version"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for pair in amd64:x86_64 arm64:aarch64; do
  arch=${pair%%:*}
  triple=${pair#*:}
  zip="postgresql-$pg-vchord_${version}_${triple}-linux-gnu.zip"
  curl -fsSL -o "$tmp/$zip" "$base/$zip"
  curl -fsSL -o "$tmp/$zip.sha256" "$base/$zip.sha256"
  (cd "$tmp" && sha256sum -c "$zip.sha256")
  unzip -q "$tmp/$zip" -d "$tmp/$arch"

  dst="$out/$arch"
  mkdir -p "$dst/lib" "$dst/share/extension" "$dst/licenses/vchord"
  cp -R "$tmp/$arch/pkglibdir/." "$dst/lib/"
  cp -R "$tmp/$arch/sharedir/extension/." "$dst/share/extension/"
  cp "$tmp/$arch/LICENSE" "$dst/licenses/vchord/"
done
