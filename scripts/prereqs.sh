#!/usr/bin/env bash
# Report what building a utility needs, and what's missing.
#
# Deliberately does NOT install anything heavy. The point of this project
# is not needing a package manager or a large toolchain; silently
# installing one to build a 50KB binary would be self-defeating. Small,
# safe things are offered; anything large is explained so you can decide.
#
# Usage: scripts/prereqs.sh <name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

NAME="${1:?usage: prereqs.sh <name>}"
RECIPE="$ROOT_DIR/utils/$NAME/recipe.sh"
[[ -f "$RECIPE" ]] || { echo "prereqs.sh: no recipe: $RECIPE" >&2; exit 1; }

# Read the declaration without running the build functions.
UNFLAB_TOOLCHAIN="$(sed -n 's/^UNFLAB_TOOLCHAIN=//p' "$RECIPE" | tr -d '"' )"

echo "$NAME needs: ${UNFLAB_TOOLCHAIN:-(unspecified)}"
echo ""

missing=()
seen=""
have() { command -v "$1" >/dev/null 2>&1; }
# A recipe may name both `c` and `make`; both resolve to the same check.
first_time() { case " $seen " in *" $1 "*) return 1 ;; esac; seen="$seen $1"; return 0; }

# Always needed.
if xcode-select -p >/dev/null 2>&1; then
  echo "  ok       C toolchain (Xcode Command Line Tools)"
else
  echo "  MISSING  C toolchain"
  echo "           Install with:  xcode-select --install"
  missing+=(clt)
fi

for tool in $UNFLAB_TOOLCHAIN; do
  case "$tool" in
    c|make)
      first_time make || continue
      have make && echo "  ok       make" || { echo "  MISSING  make (comes with the CLT)"; missing+=(make); } ;;
    autotools)
      if have autoconf && have automake; then
        echo "  ok       autotools"
      else
        echo "  MISSING  autotools (autoconf, automake, libtool)"
        echo "           Only needed to build from a git checkout; release"
        echo "           tarballs ship a pre-generated ./configure."
        missing+=(autotools)
      fi ;;
    cmake)
      have cmake && echo "  ok       cmake" || {
        echo "  MISSING  cmake"
        echo "           A large dependency for a small tool. Consider the"
        echo "           prebuilt package instead:  make $NAME.package is"
        echo "           what CI runs, and releases are published already."
        missing+=(cmake); } ;;
    go)
      have go && echo "  ok       go ($(go version 2>/dev/null | awk '{print $3}'))" || {
        echo "  MISSING  go"
        echo "           Install from https://go.dev/dl/ (or use the"
        echo "           published release rather than building locally)."
        missing+=(go); } ;;
    rust|cargo)
      have cargo && echo "  ok       cargo" || {
        echo "  MISSING  cargo"
        echo "           Install from https://rustup.rs/"
        missing+=(cargo); } ;;
    pkg-config|pkgconf)
      have pkg-config && echo "  ok       pkg-config" || { echo "  MISSING  pkg-config"; missing+=(pkg-config); } ;;
    *)
      have "$tool" && echo "  ok       $tool" || { echo "  MISSING  $tool"; missing+=("$tool"); } ;;
  esac
done

echo ""
if [[ ${#missing[@]} -eq 0 ]]; then
  echo "All prerequisites present -- 'make $NAME.build' should work."
else
  echo "${#missing[@]} missing. Install the above, or just use the published"
  echo "release:  curl -fsSL <site>/get | sh -s -- $NAME"
  exit 1
fi
