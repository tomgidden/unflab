#!/usr/bin/env bash
# build-key.sh <recipe> -- a content hash of everything that determines
# a recipe's built artefacts.
#
# Used to skip recompiling a package whose inputs haven't changed:
# if the key matches what a previous release was built from, that
# release's archives are still correct and can be copied forward.
#
# What goes into the key, and why each is load-bearing:
#
#   utils/<recipe>/*      the recipe, its manifest and its README --
#                         the README ships inside the package, so a
#                         prose fix does change the artefact
#   scripts/lib/<h>.sh    only the helpers this recipe actually sources
#                         -- bumping OpenSSL must rebuild socat and
#                         wget, and must NOT rebuild tree
#   scripts/build.sh      the driver: staging layout, the brew-path
#   scripts/package.sh    scrubbing, the archive layout
#   scripts/verify.sh     the gate itself
#   templates/install.sh  shipped inside every package
#   the runner image      a new Xcode changes the compiler, so the
#                         caller passes it in
#
# Deliberately NOT included: the upstream tarball's own content. It is
# pinned by UNFLAB_SHA256, which is inside recipe.sh and therefore
# already in the key. A moved upstream that kept its version would fail
# the checksum at build time rather than silently producing a different
# binary.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --inputs lists the files the key covers, repo-relative, instead of
# hashing them. The release workflow diffs them against the last tag to
# say which recipes a release will rebuild.
LIST=
[[ "${1:-}" == --inputs ]] && { LIST=1; shift; }

RECIPE="${1:?usage: build-key.sh [--inputs] <recipe> [image-tag]}"
IMAGE="${2:-$(uname -m)-$(sw_vers -productVersion 2>/dev/null || echo unknown)}"

[[ -d "$ROOT_DIR/utils/$RECIPE" ]] || {
  echo "build-key.sh: no such recipe: $RECIPE" >&2; exit 1; }

inputs() {
  # Sorted for stability: find's order is filesystem-dependent, and a
  # key that changes with directory order would defeat the whole point.
  find "$ROOT_DIR/utils/$RECIPE" -type f | sort | while read -r f; do
    printf '%s\n' "${f#"$ROOT_DIR/"}"
  done

  printf '%s\n' scripts/build.sh scripts/package.sh scripts/verify.sh \
    scripts/templates/install.sh

  # Only the helpers this recipe sources. Hashing all of scripts/lib
  # would make an OpenSSL bump rebuild every package in the repo,
  # which is the opposite of the point.
  #
  # The `|| true` is load-bearing: most recipes source no helper at all,
  # and a grep that matches nothing exits 1, which under pipefail fails
  # the whole key.
  { grep -ho 'scripts/lib/[A-Za-z0-9_-]*\.sh' \
      "$ROOT_DIR/utils/$RECIPE/recipe.sh" 2>/dev/null || true; } | sort -u |
  while read -r rel; do
    [[ -f "$ROOT_DIR/$rel" ]] && printf '%s\n' "$rel"
  done
}

if [[ -n "$LIST" ]]; then
  inputs
  exit 0
fi

{
  echo "image=$IMAGE"
  inputs | while read -r rel; do
    printf '%s ' "$rel"
    shasum -a 256 "$ROOT_DIR/$rel" | awk '{print $1}'
  done
} | shasum -a 256 | awk '{print substr($1, 1, 16)}'
