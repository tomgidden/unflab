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
# Usage: scripts/verify.sh [--script-only] <file-or-dir> [...]
#   Directories are searched for Mach-O executables.
#
# --script-only: the package legitimately ships no compiled binary (webi
# is a shell script), so finding no Mach-O is the expected result rather
# than a sign the build staged nothing. The gate itself is unchanged --
# any Mach-O that IS present is still checked.

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

script_only=0
if [[ "${1:-}" == "--script-only" ]]; then
  script_only=1
  shift
fi

[[ $# -gt 0 ]] || { echo "usage: verify.sh [--script-only] <file-or-dir> [...]" >&2; exit 2; }

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
  # Normally this means the build staged nothing and the package is
  # empty -- a silent failure worth catching loudly. A script-only
  # recipe says so up front, so there it's simply the expected outcome.
  if [[ "$script_only" -eq 0 ]]; then
    echo "verify.sh: no Mach-O binaries found in: $*" >&2
    exit 2
  fi

  echo "verify.sh: no binaries to check (script-only package)."
  exit 0
fi

if [[ "$fail" -ne 0 ]]; then
  echo "" >&2
  echo "verify.sh: the gate failed. A shipped binary must depend only on" >&2
  echo "libraries present on a stock macOS install." >&2
  exit 1
fi

echo ""
echo "verify.sh: $checked binary/binaries OK -- system libraries only."
