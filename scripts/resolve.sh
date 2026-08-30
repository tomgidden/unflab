#!/usr/bin/env bash
# Map a name to what it means, so `make <name>.<verb>` works whether the
# user names a package or a recipe.
#
# The two namespaces overlap on purpose. Most recipes emit one package of
# the same name (tree, jq, wget), but some emit several: inetutils emits
# ftp and telnet, coreutils emits 105. Both granularities are useful --
# `make ftp.install` for the one binary you want, `make coreutils.install`
# for the whole suite deliberately -- so both have to resolve.
#
# Usage:
#   resolve.sh recipe   <name>   -> the recipe that builds it
#   resolve.sh packages <name>   -> the package(s) that name refers to
#   resolve.sh list-packages     -> every package, one per line
#   resolve.sh list-recipes      -> every recipe, one per line
#
# A name that is both a recipe and a package (tree) resolves to the same
# thing either way, so the ambiguity is harmless.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Evaluate a recipe's UNFLAB_PACKAGES: coreutils computes its list from
# utils.txt, so it can't be scraped with sed.
recipe_packages() {
  local recipe="$1" dir
  dir="$(dirname "$recipe")"
  RECIPE_DIR="$dir" BUILD_ROOT="" bash -c '
    set -eu
    # shellcheck disable=SC1090
    . "$1" >/dev/null 2>&1 || true
    printf "%s" "${UNFLAB_PACKAGES:-${UNFLAB_NAME:-}}"
  ' _ "$recipe"
}

case "${1:-}" in
  list-recipes)
    ls -d "$ROOT_DIR"/utils/*/ 2>/dev/null | xargs -n1 basename | sort
    ;;

  list-packages)
    for r in "$ROOT_DIR"/utils/*/recipe.sh; do
      [[ -f "$r" ]] || continue
      # shellcheck disable=SC2086
      printf '%s\n' $(recipe_packages "$r")
    done | sort -u
    ;;

  recipe)
    name="${2:?usage: resolve.sh recipe <name>}"
    # A recipe directory of that name wins: `make coreutils.build` should
    # build the suite, not look for a package called coreutils.
    if [[ -d "$ROOT_DIR/utils/$name" ]]; then
      printf '%s\n' "$name"
      exit 0
    fi
    for r in "$ROOT_DIR"/utils/*/recipe.sh; do
      [[ -f "$r" ]] || continue
      for p in $(recipe_packages "$r"); do
        if [[ "$p" == "$name" ]]; then
          basename "$(dirname "$r")"
          exit 0
        fi
      done
    done
    echo "resolve.sh: no recipe builds '$name'" >&2
    exit 1
    ;;

  packages)
    name="${2:?usage: resolve.sh packages <name>}"
    # A recipe name means all of its packages; anything else is one
    # package, which must actually exist.
    if [[ -d "$ROOT_DIR/utils/$name" ]]; then
      # shellcheck disable=SC2086
      printf '%s\n' $(recipe_packages "$ROOT_DIR/utils/$name/recipe.sh")
      exit 0
    fi
    for r in "$ROOT_DIR"/utils/*/recipe.sh; do
      [[ -f "$r" ]] || continue
      for p in $(recipe_packages "$r"); do
        if [[ "$p" == "$name" ]]; then
          printf '%s\n' "$name"
          exit 0
        fi
      done
    done
    echo "resolve.sh: unknown utility '$name'" >&2
    exit 1
    ;;

  *)
    echo "usage: resolve.sh {recipe|packages} <name> | list-recipes | list-packages" >&2
    exit 2
    ;;
esac
