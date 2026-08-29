#!/bin/sh
# unflab bootstrap. Fetched and piped to a shell:
#
#   curl -fsSL https://unflab.example/get | sh -s -- tree
#   curl -fsSL https://unflab.example/get | sh -s -- wget jq tree
#   curl -fsSL https://unflab.example/get | sh -s -- --prefix=/usr/local wget jq
#   curl -fsSL https://unflab.example/get | sh -s -- --uninstall tree
#
# `-s` is required: `sh - tree` makes sh look for a *file* called tree.
# `--` is required before any flag, or sh tries to parse it as its own.
#
# This never installs anything itself. Per utility it resolves the name
# to a release asset, downloads it, verifies its checksum, unpacks it,
# and runs that package's own install.sh -- the same script, and the same
# code path, as a manual download. Flags are passed straight through.
#
# Uses only tools present on a stock macOS: curl, tar, shasum, mktemp,
# uname, sed.

set -eu

BASE_URL="{{BASE_URL}}"
RELEASE_URL="{{RELEASE_URL}}"

# A leading `--` may or may not survive: sh/dash pass it through, zsh eats it.
[ $# -gt 0 ] && [ "$1" = "--" ] && shift

utils=""
flags=""
for arg in "$@"; do
  case "$arg" in
    -*) flags="$flags $arg" ;;
    *)  utils="$utils $arg" ;;
  esac
done

if [ -z "$utils" ]; then
  cat >&2 <<USAGE
unflab: no utility named.

  curl -fsSL $BASE_URL/get | sh -s -- <utility> [utility ...] [options]

Options are passed to each package's installer:
  --prefix DIR    install somewhere other than ~/.local/bin
  --uninstall     remove a previously installed utility
  --purge         remove it and its config files
  --no-plain      don't create unprefixed name symlinks

Available utilities: $BASE_URL
USAGE
  exit 2
fi

case "$(uname -s)" in
  Darwin) ;;
  *) echo "unflab: these packages are macOS-only (this is $(uname -s))." >&2; exit 1 ;;
esac

case "$(uname -m)" in
  arm64)  ARCH=arm64-apple-darwin ;;
  x86_64) ARCH=x86_64-apple-darwin ;;
  *) echo "unflab: unsupported architecture $(uname -m)." >&2; exit 1 ;;
esac

CURL="curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 --retry-delay 5"

# Fetch the index once, so an unknown name fails before anything is
# downloaded rather than half way through a multi-utility install.
INDEX="$($CURL "$BASE_URL/index.txt" 2>/dev/null || true)"
if [ -z "$INDEX" ]; then
  echo "unflab: couldn't fetch the utility index from $BASE_URL/index.txt" >&2
  exit 1
fi

unknown=""
for u in $utils; do
  found=0
  # index.txt lines are: <name> <TAB> <version>
  while IFS='	' read -r name version; do
    [ "$name" = "$u" ] && { found=1; break; }
  done <<INDEX_EOF
$INDEX
INDEX_EOF
  [ "$found" = 1 ] || unknown="$unknown $u"
done

if [ -n "$unknown" ]; then
  echo "unflab: unknown utility:$unknown" >&2
  echo "" >&2
  echo "Available:" >&2
  echo "$INDEX" | awk -F'\t' '{printf "  %s\n", $1}' >&2
  exit 2
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/unflab.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

ok=""
failed=""

for u in $utils; do
  version=""
  while IFS='	' read -r name v; do
    [ "$name" = "$u" ] && { version="$v"; break; }
  done <<INDEX_EOF
$INDEX
INDEX_EOF

  archive="unflab-${u}-${version}-${ARCH}.tar.gz"
  echo "==> $u $version"

  if ! $CURL -o "$TMP/$archive" "$RELEASE_URL/$archive"; then
    echo "    download failed" >&2
    failed="$failed $u"
    continue
  fi

  # Verify against the published checksum list rather than trusting the
  # transport alone -- this whole script is running piped into a shell.
  sums="$TMP/SHA256SUMS-${ARCH}.txt"
  if [ ! -f "$sums" ]; then
    $CURL -o "$sums" "$RELEASE_URL/SHA256SUMS-${ARCH}.txt" || true
  fi
  if [ -s "$sums" ]; then
    want="$(awk -v f="$archive" '$2 == f || $2 == "*"f {print $1}' "$sums" | head -1)"
    got="$(shasum -a 256 "$TMP/$archive" | awk '{print $1}')"
    if [ -z "$want" ]; then
      echo "    no checksum published for $archive" >&2
      failed="$failed $u"; continue
    fi
    if [ "$want" != "$got" ]; then
      echo "    CHECKSUM MISMATCH -- refusing to install" >&2
      echo "      expected $want" >&2
      echo "      actual   $got" >&2
      failed="$failed $u"; continue
    fi
  else
    echo "    couldn't fetch checksums -- refusing to install" >&2
    failed="$failed $u"; continue
  fi

  dir="$TMP/$u"
  mkdir -p "$dir"
  if ! tar xzf "$TMP/$archive" -C "$dir"; then
    echo "    couldn't unpack" >&2
    failed="$failed $u"; continue
  fi

  # Hand off to the package's own installer: same script, same code path
  # as a manual download. Run as a file, not piped, so it can find the
  # payload sitting beside it.
  # shellcheck disable=SC2086
  if sh "$dir/install.sh" $flags; then
    ok="$ok $u"
  else
    failed="$failed $u"
  fi
  echo ""
done

# `curl | sh` output scrolls past, so end with the bit worth reading.
if [ -n "$ok" ] && [ -z "$failed" ]; then
  echo "unflab: installed$ok"
  exit 0
fi
[ -n "$ok" ]     && echo "unflab: installed$ok"
[ -n "$failed" ] && echo "unflab: FAILED$failed" >&2
[ -n "$failed" ] && exit 1
exit 0
