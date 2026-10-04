#!/usr/bin/env bash
# refresh-keyrings.sh <out-dir> -- fetch every keyring a recipe's
# UNFLAB_ATTEST names into <out-dir>/<host>/<path>, and say whether
# that set should become the new `keyrings` artifact.
#
# attest.sh falls back on the newest such artifact when an upstream's
# keyring can't be fetched -- ftp.gnu.org going quiet would otherwise
# fail every GNU build. The keyrings aren't ours, so they live in an
# artifact rather than the repo.
#
# Upload when there is no artifact yet, when any keyring has changed
# upstream, or when the newest is more than MAX_AGE_DAYS old, so one is
# always well inside its 90-day retention. A keyring that can't be
# fetched today is carried forward from the previous artifact, so one
# dead upstream doesn't drop the others' copies or its own.
#
# Prints upload=true|false, and appends it to $GITHUB_OUTPUT if set.
# Exits 0 whatever upstream does: a missing keyring is reported, not
# fatal, since today's builds are unaffected by it.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAX_AGE_DAYS=5

out="${1:?usage: refresh-keyrings.sh <out-dir>}"
rm -rf "$out"
mkdir -p "$out"

# shellcheck source=lib/attest.sh
source "$SCRIPT_DIR/lib/attest.sh"

prev="$(mktemp -d)"
trap 'rm -rf "$prev"' EXIT
when=""
when="$(unflab_keyring_cache "$prev")" || when=""

urls="$(grep -h '^UNFLAB_ATTEST=' "$ROOT_DIR"/utils/*/recipe.sh |
        sed -E "s/^UNFLAB_ATTEST=['\"]?//; s/['\"]?$//" |
        sed -n 's/^gnupg://p' | sort -u)"

for url in $urls; do
  path="${url#*://}"
  mkdir -p "$out/$(dirname "$path")"
  if curl -fsSL --connect-timeout 15 --max-time 120 --retry 3 \
       -o "$out/$path" "$url"; then
    echo "fetched  $url"
  elif [ -s "$prev/$path" ]; then
    cp "$prev/$path" "$out/$path"
    echo "kept     $url (unreachable; copy from $when)"
  else
    rm -f "$out/$path"
    echo "MISSING  $url (unreachable, and no previous copy)"
  fi
done

upload=false
if [ -z "$when" ]; then
  echo "no previous keyrings artifact"
  upload=true
elif ! diff -rq "$prev" "$out" >/dev/null; then
  diff -rq "$prev" "$out" | sed 's/^/changed  /'
  upload=true
else
  age=$(( ( $(date +%s) - $(date -d "$when" +%s 2>/dev/null ||
                             date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$when" +%s) ) / 86400 ))
  echo "unchanged since $when ($age days)"
  [ "$age" -gt "$MAX_AGE_DAYS" ] && upload=true
fi

# Nothing fetched and nothing carried forward: an empty artifact would
# only displace a useful one.
[ -n "$(find "$out" -type f)" ] || upload=false

echo "upload=$upload"
[ -n "${GITHUB_OUTPUT:-}" ] && echo "upload=$upload" >> "$GITHUB_OUTPUT"
exit 0
