#!/usr/bin/env bash
# bump.sh <recipe> <new-version> -- rewrite a recipe to a new upstream
# version, re-pinning UNFLAB_SHA256 from the tarball it names.
#
# Only UNFLAB_VERSION and UNFLAB_SOURCE are rewritten. The version
# string also appears in prose ("bloaty 1.1 is from 2020"), and a
# global replace would silently turn a true comment into a false one.
# Updating prose is a judgement a human makes when merging.
#
# On its own this proves nothing about the new tarball: a hash computed
# from a download can't attest to that download. What makes it
# trustworthy is what happens next -- CI builds it, gates it and runs
# the litmus test, and the diff is reviewed before it reaches main.
# This writes a candidate, not a fact.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RECIPE_NAME="${1:?usage: bump.sh <recipe> <new-version>}"
NEW_VERSION="${2:?usage: bump.sh <recipe> <new-version>}"
RECIPE="$ROOT_DIR/utils/$RECIPE_NAME/recipe.sh"

[ -f "$RECIPE" ] || { echo "bump.sh: no such recipe: $RECIPE_NAME" >&2; exit 1; }

old_version="$(sed -n 's/^UNFLAB_VERSION=//p' "$RECIPE" | head -1 | tr -d '"')"
old_source="$(sed -n 's/^UNFLAB_SOURCE=//p' "$RECIPE" | head -1 | tr -d '"')"
old_sha="$(sed -n 's/^UNFLAB_SHA256=//p' "$RECIPE" | head -1 | tr -d '"')"

[ -n "$old_version" ] || { echo "bump.sh: no UNFLAB_VERSION in $RECIPE" >&2; exit 1; }
[ -n "$old_source" ]  || { echo "bump.sh: no UNFLAB_SOURCE in $RECIPE" >&2; exit 1; }

if [ "$old_version" = "$NEW_VERSION" ]; then
  echo "bump.sh: $RECIPE_NAME is already $NEW_VERSION" >&2
  exit 1
fi

# The URL embeds the version in forms that vary (1.8.1, v1.8.1,
# jq-1.8.1), so substitute the old version string wherever it appears
# in the URL rather than trying to reconstruct the URL's shape.
new_source="${old_source//$old_version/$NEW_VERSION}"

if [ "$new_source" = "$old_source" ]; then
  echo "bump.sh: $old_version does not appear in the source URL:" >&2
  echo "  $old_source" >&2
  echo "  the URL needs updating by hand" >&2
  exit 1
fi

echo "==> $RECIPE_NAME $old_version -> $NEW_VERSION"
echo "    $new_source"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Saved under the upstream's own filename, not a temp name: checksum
# files list assets by name, so "tarball" would never be found in one.
asset="$(basename "${new_source%%\?*}")"
if ! curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
     -o "$tmp/$asset" "$new_source"; then
  echo "bump.sh: could not download $new_source" >&2
  exit 1
fi

new_sha="$(shasum -a 256 "$tmp/$asset" | awk '{print $1}')"

# A version that resolves to the byte-identical tarball means the URL
# didn't actually change what was fetched -- a version scheme this
# script guessed wrong about.
if [ "$new_sha" = "$old_sha" ]; then
  echo "bump.sh: $NEW_VERSION has the same SHA-256 as $old_version" >&2
  echo "  the new URL is fetching the old tarball" >&2
  exit 1
fi

echo "    sha256 $new_sha"

# The hash above was computed from a tarball this script just
# downloaded, so on its own it attests to nothing: a tampered download
# would be recorded just as faithfully. If the upstream publishes a
# signature or a checksum, check the new hash against it now -- that is
# independent evidence, and the difference between a bump worth
# reviewing and a bump worth refusing.
attest_spec="$(sed -n "s/^UNFLAB_ATTEST=//p" "$RECIPE" | head -1 | tr -d "\"'")"
if [ -n "$attest_spec" ]; then
  # shellcheck source=lib/attest.sh
  source "$SCRIPT_DIR/lib/attest.sh"
  unflab_attest "$tmp/$asset" "$new_sha" "$attest_spec" "$NEW_VERSION" \
    "$new_source.sig"
  case $? in
    0) ;;
    1) echo "bump.sh: upstream evidence contradicts this download -- refusing" >&2
       exit 1 ;;
    2) echo "bump.sh: could not check upstream evidence; the branch will say so" >&2 ;;
  esac
fi

# Line-anchored so only the declarations change, never prose.
python3 - "$RECIPE" "$NEW_VERSION" "$new_source" "$new_sha" <<'PY'
import re, sys
path, version, source, sha = sys.argv[1:5]
s = open(path, encoding="utf-8").read()

def one(pattern, repl, text, what):
    text, n = re.subn(pattern, repl.replace("\\", "\\\\"), text, count=1, flags=re.M)
    if n != 1:
        sys.exit(f"bump.sh: expected exactly one {what} line, changed {n}")
    return text

s = one(r'^UNFLAB_VERSION=.*$', f'UNFLAB_VERSION={version}', s, "UNFLAB_VERSION")
s = one(r'^UNFLAB_SOURCE=.*$',  f'UNFLAB_SOURCE={source}',   s, "UNFLAB_SOURCE")
s = one(r'^UNFLAB_SHA256=.*$',  f'UNFLAB_SHA256={sha}',      s, "UNFLAB_SHA256")
open(path, "w", encoding="utf-8").write(s)
PY

bash -n "$RECIPE" || { echo "bump.sh: rewrote $RECIPE into invalid bash" >&2; exit 1; }

echo "    recipe updated"
