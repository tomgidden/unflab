#!/usr/bin/env bash
# affected.sh <changed-file>... -- which recipes a set of changed files
# can affect. Prints recipe names, one per line, or nothing at all when
# no build is warranted.
#
# CI used to answer this with "any file outside utils/ means rebuild
# everything", which is safe but wasteful: a README or an AGENTS.md
# push spent 21 macOS runners to reproduce 21 identical artefacts.
#
# The three answers, and why each file lands where it does:
#
#   everything   the file changes what every artefact IS (the build
#                driver, the gate, the installer shipped inside every
#                package) or how every one is TESTED
#   some         a recipe's own directory, or a scripts/lib helper --
#                which rebuilds only the recipes that source it
#   nothing      the file cannot reach an artefact or a test: docs,
#                the site generator, prereqs/bump/check-updates
#
# Deliberately close to, but not the same as, build-key.sh. That answers
# "would this artefact differ?" for the release cache; this answers
# "should CI run?", which additionally covers the test scripts -- a
# change to litmus-test.sh alters no binary but must still re-run the
# tests it defines.
#
# The default is `everything`: an unrecognised path is treated as
# capable of anything, so adding a file to the repo can never silently
# skip a build. Only paths listed here as inert are skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

all_recipes() { ls -d "$ROOT_DIR"/utils/*/ | xargs -n1 basename | sort; }

# Recipes that source a given helper, e.g. scripts/lib/openssl.sh.
recipes_sourcing() {
  local helper="$1" r name
  for r in "$ROOT_DIR"/utils/*/recipe.sh; do
    [ -f "$r" ] || continue
    if grep -q "$helper" "$r" 2>/dev/null; then
      name="$(basename "$(dirname "$r")")"
      printf '%s\n' "$name"
    fi
  done
}

everything=0
selected=""

for f in "$@"; do
  [ -n "$f" ] || continue
  case "$f" in
    # A recipe's own directory: just that recipe.
    utils/*/*)
      selected="$selected $(printf '%s' "$f" | cut -d/ -f2)" ;;

    # Sourced by recipes, so scoped to the ones that source it.
    scripts/lib/attest.sh)
      # Not sourced by any recipe -- build.sh sources it for every
      # build, so it is not scoped like the others.
      everything=1 ;;
    scripts/lib/*.sh)
      selected="$selected $(recipes_sourcing "$f" | tr '\n' ' ')" ;;

    # What every artefact is, or how every one is tested.
    scripts/build.sh|scripts/package.sh|scripts/verify.sh|\
    scripts/build-key.sh|scripts/litmus-test.sh|scripts/resolve.sh|\
    scripts/templates/install.sh|.github/workflows/build.yml|\
    scripts/affected.sh)
      # This script decides what gets built, so a change to it rebuilds
      # everything -- the one case where being wrong is unrecoverable
      # by the default below.
      everything=1 ;;

    # Cannot reach an artefact or a test.
    #
    # templates/get.sh and unflab.sh are the site's bootstrap and
    # helper: served from the site, never staged into a package. The
    # docs generator, prereqs, bump and check-updates likewise touch
    # no artefact -- verified with build-key.sh, which does not hash
    # any of them.
    docs/*|site-extra/*|scripts/generate-docs.py|\
    scripts/templates/get.sh|scripts/templates/unflab.sh|\
    scripts/prereqs.sh|scripts/bump.sh|scripts/check-updates.sh|\
    scripts/install-local.sh|\
    docmd.config.base.json|docmd.config.json|\
    README.md|AGENTS.md|LICENSE|.gitignore|\
    .github/workflows/pages.yml|.github/workflows/bump.yml|\
    .github/workflows/check-updates.yml|.github/workflows/release.yml)
      : ;;

    # Anything unrecognised is assumed to matter.
    *)
      echo "affected: unrecognised path '$f' -- assuming everything" >&2
      everything=1 ;;
  esac
done

if [ "$everything" -eq 1 ]; then
  all_recipes
  exit 0
fi

# Deduplicate, and drop anything that is not actually a recipe.
for n in $selected; do
  [ -d "$ROOT_DIR/utils/$n" ] && printf '%s\n' "$n"
done | sort -u
