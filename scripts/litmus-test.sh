#!/usr/bin/env bash
# The project's acceptance test, in the form of the promise it makes:
#
#   On a clean machine, install a package and use it, with nothing
#   present beyond what the install put there.
#
# Runs every packaged archive through a real install into a throwaway
# HOME, then runs the installed binary and resolves its man page -- with
# Homebrew and /usr/local stripped from PATH, so a missed dependency
# fails here instead of on a user's Mac. CI runners have Homebrew
# installed, which would otherwise hide exactly the mistake this project
# exists to avoid.
#
# Usage: scripts/litmus-test.sh <arch-triple>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ARCH="${1:?usage: litmus-test.sh <arch-triple>}"

DIST="$ROOT_DIR/dist"
shopt -s nullglob
archives=("$DIST"/unflab-*-"$ARCH".tar.gz)
[[ ${#archives[@]} -gt 0 ]] || { echo "litmus-test: no archives for $ARCH in dist/" >&2; exit 1; }

# A PATH with nothing but the base system on it.
CLEAN_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

pass=0
fail=0

for archive in "${archives[@]}"; do
  base="$(basename "$archive" ".tar.gz")"
  pkg="$(echo "$base" | sed -E "s/^unflab-(.+)-[^-]+-${ARCH}$/\1/")"

  echo "=============================================================="
  echo "== $pkg"
  echo "=============================================================="

  work="$(mktemp -d /tmp/litmus.XXXXXX)"
  home="$work/home"
  mkdir -p "$home" "$work/unpack"
  tar xzf "$archive" -C "$work/unpack"

  # Install exactly as a user would, non-interactively.
  if ! env -i HOME="$home" PATH="$CLEAN_PATH" SHELL=/bin/zsh \
       /bin/sh "$work/unpack/install.sh" --prefix "$home/.local/bin" --no-path </dev/null; then
    echo "FAIL  $pkg: install.sh failed"
    fail=$((fail + 1)); rm -rf "$work"; continue
  fi

  # Run every installed binary with nothing else on PATH. --version is
  # the one flag essentially everything supports; fall back to --help.
  ran_any=0
  ok_all=1
  for bin in "$home/.local/bin"/*; do
    [[ -f "$bin" && -x "$bin" ]] || continue
    [[ -L "$bin" ]] && continue          # aliases point at the real one
    name="$(basename "$bin")"
    ran_any=1
    # "Runs" means the binary loaded and executed -- not that it exited
    # zero. `false` exits 1 by definition, and so does `test` with no
    # arguments; judging those by exit status marks a working package
    # broken. What actually distinguishes a broken binary here is a
    # dynamic-link failure, which the shell reports as 126/127 and dyld
    # writes to stderr. So check for that instead.
    # `|| rc=$?` is required, not defensive: under `set -e` a failing
    # command substitution kills the script before $? can be read -- and
    # a non-zero exit is exactly what we're here to tolerate.
    rc=0
    out="$(env -i HOME="$home" PATH="$home/.local/bin:$CLEAN_PATH" \
             "$bin" --version 2>&1)" || rc=$?
    if [[ "$rc" -ge 126 ]] || grep -qiE 'dyld|image not found|Library not loaded|Symbol not found' <<<"$out"; then
      echo "  FAIL  $name did not run (exit $rc)"
      [[ -n "$out" ]] && echo "$out" | head -3 | sed 's/^/          /'
      ok_all=0
    else
      echo "  ok    $name runs"
    fi
  done

  if [[ "$ran_any" -eq 0 ]]; then
    echo "FAIL  $pkg: nothing executable was installed"
    ok_all=0
  fi

  # Man pages must resolve through PATH alone: macOS derives its man
  # search path from PATH, so MANPATH is deliberately left unset.
  for page in "$home/.local/share/man/man1"/*.1; do
    [[ -f "$page" ]] || continue
    [[ -L "$page" ]] && continue
    name="$(basename "$page" .1)"
    if env -i HOME="$home" PATH="$home/.local/bin:$CLEAN_PATH" \
         /usr/bin/man -w "$name" >/dev/null 2>&1; then
      echo "  ok    man $name resolves"
    else
      echo "  FAIL  man $name did not resolve"
      ok_all=0
    fi
  done

  # Uninstall must leave nothing behind.
  env -i HOME="$home" PATH="$CLEAN_PATH" \
    /bin/sh "$work/unpack/install.sh" --prefix "$home/.local/bin" --purge >/dev/null </dev/null || true
  leftover="$(find "$home/.local" "$home/.config" -type f 2>/dev/null || true)"
  if [[ -n "$leftover" ]]; then
    echo "  FAIL  purge left files behind:"
    echo "$leftover" | sed 's/^/          /'
    ok_all=0
  else
    echo "  ok    purge left nothing behind"
  fi

  if [[ "$ok_all" -eq 1 ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  rm -rf "$work"
  echo ""
done

echo "=============================================================="
echo "litmus: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
