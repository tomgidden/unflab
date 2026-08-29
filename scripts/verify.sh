#!/usr/bin/env bash
# The gate: a shipped binary must link against NOTHING outside /usr/lib
# and /System/.
#
# macOS has no static libSystem and doesn't support fully-static
# executables, so "self-contained" can't mean "statically linked". What
# it means here is that every dylib the binary needs is part of the base
# OS and present on any Mac -- nothing from /opt/homebrew, /usr/local,
# or a build-time prefix that won't exist on the user's machine.
#
# Homebrew is therefore fine to use at BUILD time (to get a static
# libnettle.a, headers, tooling); this check is what proves none of it
# survived into the artefact.
#
# Usage: scripts/verify.sh <file-or-dir> [...]
#   Directories are searched for Mach-O executables.

set -euo pipefail

fail=0
checked=0

check_one() {
  local f="$1"

  # Only Mach-O binaries: skip scripts, man pages, licences.
  file -b "$f" | grep -q 'Mach-O' || return 0

  checked=$((checked + 1))

  local bad
  # Skip line 1 (the file's own name) and the binary's own LC_ID_DYLIB.
  bad="$(otool -L "$f" | tail -n +2 \
    | grep -v -E '^\s+(/usr/lib/|/System/)' || true)"

  if [[ -n "$bad" ]]; then
    echo "FAIL  $f links against non-system libraries:" >&2
    echo "$bad" >&2
    fail=1
  else
    echo "ok    $f"
  fi

  # A binary carrying an rpath into a build-time prefix will still run on
  # the build machine but can break, or silently pick up a different
  # library, elsewhere. Flag those too.
  local rpaths
  rpaths="$(otool -l "$f" | awk '/LC_RPATH/{p=1} p&&/path /{print $2; p=0}' \
    | grep -v -E '^(/usr/lib|/System)' || true)"
  if [[ -n "$rpaths" ]]; then
    echo "FAIL  $f has non-system LC_RPATH entries:" >&2
    echo "$rpaths" >&2
    fail=1
  fi
}

[[ $# -gt 0 ]] || { echo "usage: verify.sh <file-or-dir> [...]" >&2; exit 2; }

for target in "$@"; do
  if [[ -d "$target" ]]; then
    while IFS= read -r f; do check_one "$f"; done \
      < <(find "$target" -type f -perm -u+x)
  elif [[ -f "$target" ]]; then
    check_one "$target"
  else
    echo "verify.sh: no such file: $target" >&2
    exit 2
  fi
done

if [[ "$checked" -eq 0 ]]; then
  echo "verify.sh: no Mach-O binaries found in: $*" >&2
  exit 2
fi

if [[ "$fail" -ne 0 ]]; then
  echo "" >&2
  echo "verify.sh: the gate failed. A shipped binary must depend only on" >&2
  echo "libraries present on a stock macOS install." >&2
  exit 1
fi

echo ""
echo "verify.sh: $checked binary/binaries OK -- system libraries only."
