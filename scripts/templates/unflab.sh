#!/bin/sh
#
# https://unflab.app/
#
# unflab -- install and remove unflab utilities.
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

  unflab ‹utility› [utility ...]     install
  unflab --uninstall ‹utility›       remove
  unflab --purge ‹utility›           remove, including config files
  unflab --list                      list available utilities
  unflab --prefix DIR ‹utility›      install somewhere else

  Options:
    --keep       keep the downloaded packages after installing
    --no-plain   don't create unprefixed name symlinks (eg. timeout -> gtimeout)
    --no-helper  don't install the 'unflab' helper script

Anything else is passed straight through to the installer.

This script is just a convenience wrapper, not a package manager. It runs:

  curl -fsSL $BASE_URL/get | sh -s -- "\$@"

USAGE
    exit 0
    ;;
esac

curl -fsSL --connect-timeout 15 --max-time 60 "$BASE_URL/get" | sh -s -- "$@"
