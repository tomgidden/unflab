#!/usr/bin/env bash
# Stage built utilities into release archives, one .tar.gz per package.
#
# Reads out/<pkg>/ (as produced by a recipe's unflab_stage) plus that
# package's manifest, generates a self-contained install.sh with the
# manifest inlined, and tars the result.
#
# Usage: scripts/package.sh <arch-triple> [package ...]
#   e.g. scripts/package.sh arm64-apple-darwin
#        scripts/package.sh arm64-apple-darwin ftp telnet

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="${ROOT_DIR}/out"
DIST_DIR="${ROOT_DIR}/dist"
TEMPLATE="${SCRIPT_DIR}/templates/install.sh"

ARCH="${1:?usage: package.sh <arch-triple> [package ...]}"; shift

[[ -d "$OUT_DIR" ]] || { echo "package.sh: no out/ -- run a build first" >&2; exit 1; }

packages=("$@")
if [[ ${#packages[@]} -eq 0 ]]; then
  for d in "$OUT_DIR"/*/; do
    [[ -d "$d" ]] && packages+=("$(basename "$d")")
  done
fi
[[ ${#packages[@]} -gt 0 ]] || { echo "package.sh: nothing in out/" >&2; exit 1; }

mkdir -p "$DIST_DIR"

for pkg in "${packages[@]}"; do
  stage="$OUT_DIR/$pkg"
  [[ -d "$stage" ]] || { echo "package.sh: no out/$pkg" >&2; exit 1; }

  # Each staged package carries the metadata its recipe recorded.
  [[ -f "$stage/.unflab/version" ]] || { echo "package.sh: $pkg missing .unflab/version" >&2; exit 1; }
  version="$(cat "$stage/.unflab/version")"

  manifest="$stage/.unflab/manifest.tsv"
  [[ -f "$manifest" ]] || { echo "package.sh: $pkg missing .unflab/manifest.tsv" >&2; exit 1; }

  # Every source named by the manifest must actually be present, or the
  # package would fail at install time on the user's machine instead of
  # here, where it's cheap to catch.
  while IFS=$'\t' read -r kind mode src dest plain; do
    [[ -z "$kind" || "$kind" == \#* ]] && continue
    [[ -f "$stage/$src" ]] || { echo "package.sh: $pkg manifest names missing file: $src" >&2; exit 1; }
  done < "$manifest"

  # Generate install.sh with the manifest inlined. sed's `r` reads the
  # file in verbatim, preserving the tabs that separate its fields; an
  # s/// substitution can't insert multi-line content and would mangle
  # any metacharacters in it.
  install_sh="$stage/install.sh"
  sed -e "/{{MANIFEST}}/r $manifest" \
      -e "/{{MANIFEST}}/d" \
      -e "s|{{UTIL}}|$pkg|g" \
      -e "s|{{VERSION}}|$version|g" \
      "$TEMPLATE" > "$install_sh"
  chmod +x "$install_sh"

  # The generated script must be valid sh -- a broken one would only be
  # discovered by a user, on their machine, after downloading.
  sh -n "$install_sh" || { echo "package.sh: generated install.sh for $pkg is not valid sh" >&2; exit 1; }

  archive="$DIST_DIR/unflab-${pkg}-${version}-${ARCH}.tar.gz"
  # --exclude .unflab: build metadata, not part of what users get.
  tar czf "$archive" -C "$stage" --exclude='./.unflab' .
  echo "==> Packaged $archive"
done

# One checksum file per arch, which the `get` bootstrap verifies each
# download against.
( cd "$DIST_DIR" && shasum -a 256 unflab-*-"${ARCH}".tar.gz > "SHA256SUMS-${ARCH}.txt" )
echo "==> Wrote $DIST_DIR/SHA256SUMS-${ARCH}.txt"
