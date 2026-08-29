#!/usr/bin/env bash
# Install a locally-staged utility straight from out/, without building a
# release archive first. This is what `make <util>.install` uses.
#
# It generates the same install.sh a real package gets and runs it, so the
# local path exercises exactly the code users run -- a local install that
# worked while the real one was broken would be worse than useless.
#
# Usage: scripts/install-local.sh <package> <prefix> [extra install.sh args...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PKG="${1:?usage: install-local.sh <package> <prefix> [args...]}"
PREFIX="${2:?usage: install-local.sh <package> <prefix> [args...]}"
shift 2

STAGE="$ROOT_DIR/out/$PKG"
[[ -d "$STAGE" ]] || { echo "install-local.sh: nothing staged at out/$PKG -- run 'make $PKG.build'" >&2; exit 1; }

version="$(cat "$STAGE/.unflab/version")"
manifest="$STAGE/.unflab/manifest.tsv"

sed -e "/{{MANIFEST}}/r $manifest" \
    -e "/{{MANIFEST}}/d" \
    -e "s|{{UTIL}}|$PKG|g" \
    -e "s|{{VERSION}}|$version|g" \
    "$SCRIPT_DIR/templates/install.sh" > "$STAGE/install.sh"
chmod +x "$STAGE/install.sh"

exec sh "$STAGE/install.sh" --prefix "$PREFIX" "$@"
