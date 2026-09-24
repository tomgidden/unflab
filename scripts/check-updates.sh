#!/usr/bin/env bash
# check-updates.sh [recipe ...] -- report recipes whose upstream has
# moved on. Reports only; it never edits a recipe.
#
# Bumping a version means changing UNFLAB_SHA256 too, and that pin is
# the project's only integrity check across upstreams that mostly don't
# sign their releases. An automated bump would be a robot rewriting the
# thing that makes a supply-chain attack detectable, so this deliberately
# stops at telling you.
#
# Each recipe declares how to find its latest version in UNFLAB_CHECK:
#
#   github:<owner>/<repo>        latest *release* tag
#   github-tags:<owner>/<repo>   newest tag (for repos with no releases)
#   gitlab-tags:<owner>/<repo>   newest tag
#   gnu:<package>                ftp.gnu.org directory listing
#   html:<url>:<prefix>          scrape <prefix>-<version>.tar.* from a page
#
# A recipe with no UNFLAB_CHECK is reported as unchecked rather than
# skipped silently -- an upstream nobody is watching is worth knowing
# about.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CURL=(curl -fsSL --connect-timeout 15 --max-time 60 --retry 2 --retry-delay 3)

# GitHub's unauthenticated API allows 60 requests an hour, which is
# fewer than this repo has recipes once tags are counted. In CI,
# GH_TOKEN raises that; locally its absence is fine for a one-off run.
gh_curl() {
  if [ -n "${GH_TOKEN:-}" ]; then
    "${CURL[@]}" -H "Authorization: Bearer $GH_TOKEN" "$@"
  else
    "${CURL[@]}" "$@"
  fi
}

# Upstreams disagree about tag style: v1.1, 3.5.3, jq-1.8.2. Strip a
# leading "v" or "<name>-" so the comparison is version-to-version.
strip_prefix() {
  printf '%s' "$1" | sed -E 's/^v//; s/^[A-Za-z][A-Za-z0-9_.-]*-([0-9])/\1/'
}

latest_version() {
  local spec="$1" kind="${1%%:*}" rest="${1#*:}"

  case "$kind" in
    github)
      gh_curl "https://api.github.com/repos/$rest/releases/latest" |
        sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
        head -1
      ;;
    github-tags)
      gh_curl "https://api.github.com/repos/$rest/tags?per_page=1" |
        sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
        head -1
      ;;
    gitlab-tags)
      # The project path has to be URL-encoded for the API.
      local enc="${rest//\//%2F}"
      "${CURL[@]}" "https://gitlab.com/api/v4/projects/$enc/repository/tags?per_page=1" |
        sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
        head -1
      ;;
    gnu)
      "${CURL[@]}" "https://ftp.gnu.org/gnu/$rest/" |
        grep -oE "$rest-[0-9][0-9.]*\.tar\.(gz|xz)" |
        sed -E "s/^$rest-//; s/\.tar\.(gz|xz)$//" |
        sort -V | tail -1
      ;;
    html)
      # html:<url>:<prefix> -- the URL may itself contain colons, so
      # the prefix is taken from the end rather than by splitting on
      # the first colon.
      local url="${rest%:*}" prefix="${rest##*:}"
      # The optional -<word> between the version and the extension is
      # for tarballs like mupdf-1.28.3-source.tar.gz. Without it the
      # pattern still matched mupdf's ancient mupdf-0.7.tar.gz files,
      # which are on the same page -- so the check reported "ours is
      # newer" rather than failing, which is the worst way to be wrong.
      "${CURL[@]}" "$url" |
        grep -oE "$prefix-[0-9][0-9.]*(-[a-z]+)?\.tar\.(gz|xz|bz2)" |
        sed -E "s/^$prefix-//; s/(-[a-z]+)?\.tar\.(gz|xz|bz2)$//" |
        sort -V | tail -1
      ;;
    *)
      return 1
      ;;
  esac
}

recipes=("$@")
if [ ${#recipes[@]} -eq 0 ]; then
  # shellcheck disable=SC2207
  recipes=($("$SCRIPT_DIR/resolve.sh" list-recipes))
fi

behind=0
failed=0
unchecked=0

printf '%-12s %-12s %-12s %s\n' RECIPE CURRENT LATEST ""
printf '%-12s %-12s %-12s %s\n' ------ ------- ------ ""

# One line of the report: a recipe's main upstream, or one of the
# extra sources it pins alongside (see below).
report() {
  local label="$1" current="$2" spec="$3" raw latest newer

  if [ -z "$spec" ]; then
    printf '%-12s %-12s %-12s %s\n' "$label" "$current" "-" "no UNFLAB_CHECK"
    unchecked=$((unchecked + 1))
    return
  fi

  raw="$(latest_version "$spec" 2>/dev/null || true)"
  latest="$(strip_prefix "${raw:-}")"

  if [ -z "$latest" ]; then
    printf '%-12s %-12s %-12s %s\n' "$label" "$current" "?" "CHECK FAILED"
    failed=$((failed + 1))
  elif [ "$latest" != "$current" ]; then
    # sort -V decides which is actually newer: an upstream that pulls a
    # release, or a pin deliberately held back, shouldn't read as an
    # available update.
    newer="$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -1)"
    if [ "$newer" = "$current" ]; then
      printf '%-12s %-12s %-12s %s\n' "$label" "$current" "$latest" "(ours is newer)"
    else
      printf '%-12s %-12s %-12s %s\n' "$label" "$current" "$latest" "UPDATE"
      behind=$((behind + 1))
    fi
  else
    printf '%-12s %-12s %-12s %s\n' "$label" "$current" "$latest" "up to date"
  fi
}

for r in "${recipes[@]}"; do
  recipe="$ROOT_DIR/utils/$r/recipe.sh"
  [ -f "$recipe" ] || continue

  report "$r" \
    "$(sed -n 's/^UNFLAB_VERSION=//p' "$recipe" | head -1 | tr -d '"')" \
    "$(sed -n 's/^UNFLAB_CHECK=//p' "$recipe" | head -1 | tr -d '"')"

  # A second upstream pinned in the same recipe -- dutis inside duti --
  # is watched when the recipe gives it a UNFLAB_<PART>_CHECK beside its
  # UNFLAB_<PART>_VERSION. Opt-in, so the static libraries some recipes
  # bundle (nettle, apr) aren't reported as unchecked until someone
  # decides they should be watched.
  for part in $(sed -n 's/^UNFLAB_\([A-Z0-9]*\)_CHECK=.*/\1/p' "$recipe"); do
    lower="$(printf '%s' "$part" | tr 'A-Z' 'a-z')"
    report "$r/$lower" \
      "$(sed -n "s/^UNFLAB_${part}_VERSION=//p" "$recipe" | head -1 | tr -d '"')" \
      "$(sed -n "s/^UNFLAB_${part}_CHECK=//p" "$recipe" | head -1 | tr -d '"')"
  done
done

echo
echo "$behind update(s) available, $failed check(s) failed, $unchecked unchecked."

# A failed check is a broken checker, not a broken build: exit non-zero
# so CI surfaces it, but keep updates themselves as information.
[ "$failed" -eq 0 ]
