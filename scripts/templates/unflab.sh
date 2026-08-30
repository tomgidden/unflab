#!/bin/sh
# unflab -- install and remove unflab utilities.
#
#   unflab tree jq            install some
#   unflab --uninstall ftp    remove one
#   unflab --purge doggo      remove it and its config
#   unflab --list             what's available
#
# Don't worry: this isn't a slippery slope into a bloated package
# manager. It is a dozen lines of shell that re-runs the same
# `curl … | sh` line you used in the first place, so you don't have to
# remember or retype it. It keeps no database, tracks no state, and
# updates nothing behind your back.
#
# If its mere presence offends you, delete it. Nothing else depends on
# it, and the curl line keeps working:
#
#     curl -fsSL {{BASE_URL}}/get | sh -s -- <utility>
#
# Everything it can do, that line can do.

set -eu

BASE_URL="{{BASE_URL}}"

case "${1:-}" in
  ""|-h|--help)
    cat <<USAGE
unflab -- install and remove standalone macOS utilities

  unflab <utility> [utility ...]     install
  unflab --uninstall <utility>       remove
  unflab --purge <utility>           remove, including config files
  unflab --list                      list available utilities
  unflab --prefix DIR <utility>      install somewhere else

Anything else is passed straight through to the installer.

This script is a convenience wrapper, not a package manager. It runs:

  curl -fsSL $BASE_URL/get | sh -s -- "\$@"

Delete it whenever you like; that line does the same job.
USAGE
    exit 0
    ;;
  --list)
    # The index the installer itself reads: name, then version.
    curl -fsSL --connect-timeout 15 --max-time 60 "$BASE_URL/index.txt" \
      | awk -F'\t' '{printf "%-14s %s\n", $1, $2}'
    exit 0
    ;;
esac

curl -fsSL --connect-timeout 15 --max-time 60 "$BASE_URL/get" | sh -s -- "$@"
