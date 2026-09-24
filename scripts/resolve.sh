#!/usr/bin/env bash
# Map a name to what it means, so `make <name>.<verb>` works whether the
# user names a package or a recipe.
#
# The two namespaces overlap on purpose. Most recipes emit one package of
# the same name (tree, jq, wget), but some emit several: inetutils emits
# ftp and telnet, coreutils one per utility. Both granularities are useful --
# `make ftp.install` for the one binary you want, `make coreutils.install`
# for the whole suite deliberately -- so both have to resolve.
#
# Usage:
#   resolve.sh recipe   <name>   -> the recipe that builds it
#   resolve.sh packages <name>   -> the package(s) that name refers to
#   resolve.sh list-packages     -> every package, one per line
#   resolve.sh list-recipes      -> every recipe that builds, one per line
#   resolve.sh list-stubs        -> every stub recipe (refer, delegate)
#
# Stub recipes build nothing, so the lists that drive builds leave them
# out; the docs generator reads utils/ itself.
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

# A recipe's UNFLAB_KIND; `build` when it doesn't say.
recipe_kind() {
  local k
  k="$(sed -n 's/^UNFLAB_KIND=//p' "$1" | head -1 | tr -d "\"'")"
  printf '%s' "${k:-build}"
}

case "${1:-}" in
  list-recipes|list-stubs)
    for r in "$ROOT_DIR"/utils/*/recipe.sh; do
      [[ -f "$r" ]] || continue
      k="$(recipe_kind "$r")"
      if [[ "$1" == list-recipes ]]; then [[ "$k" == build ]] || continue
      else [[ "$k" != build ]] || continue; fi
      basename "$(dirname "$r")"
    done | sort
    ;;

  list-packages)
    for r in "$ROOT_DIR"/utils/*/recipe.sh; do
      [[ -f "$r" ]] || continue
      [[ "$(recipe_kind "$r")" == build ]] || continue
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
    echo "usage: resolve.sh {recipe|packages} <name> | list-recipes | list-stubs | list-packages" >&2
    exit 2
    ;;
esac
