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
#     curl -fsSL {{BASE_URL/get | sh -s -- <utility>
#
# Everything it can do, that line can do.

SWITCH="${1:-}"
SELF="${0##*/}"

set -eu

BASE_URL="{{BASE_URL}}"

# Terminal colours: default to none
TTY_OK=0
ESC=; RED=; GREEN=; YELLOW=; BLUE=; MAGENTA=; CYAN=
NORMAL=; BOLD=; NO_BOLD=; DIM=; ITALIC=; NO_ITALIC=; UNDERLINE=; NO_UNDERLINE=
RESET_COLOR=; RESET_STYLE=; RESET=
CO="<"; CC=">";
ELLIP="..."
NELLIP="   "

# Probed in a subshell first because some shells treat a failed
# redirection on `exec` as fatal to the whole script.
if (exec 3<>/dev/tty) 2>/dev/null; then
  exec 3<>/dev/tty
  TTY_OK=1
fi

# If we found a terminal, use colours.
if [ "$TTY_OK" = 1 ]; then
  ESC=$(printf '\033')
  RED="$ESC[91m";      GREEN="$ESC[92m";   YELLOW="$ESC[93m"
  BLUE="$ESC[94m";     MAGENTA="$ESC[95m"; CYAN="$ESC[96m"
  BOLD="$ESC[1m";      NO_BOLD="$ESC[22m"
  DIM="$ESC[2m";       NORMAL="$ESC[22m"
  ITALIC="$ESC[3m";    NO_ITALIC="$ESC[23m"
  UNDERLINE="$ESC[4m"; NO_UNDERLINE="$ESC[24m"
  RESET_COLOR="$ESC[39;49;9m"; RESET_STYLE="$ESC[29m"; RESET="$ESC[0m"
  CO="‹"; CC="›"; ELLIP="…"; NELLIP=" "
fi

DEFAULT_PATH="$HOME/.local/bin"

NAME="${CO}name$CC"
DIR="${CO}dir$CC"
FLAG="$GREEN"
COMMAND="$YELLOW"
PARAM="$BOLD$CYAN"
OPTIONAL="$DIM$CYAN"
NAMES="$PARAM$NAME $OPTIONAL[$NAME$ELLIP]$RESET"
COMMENT="$DIM # $ITALIC"

case $SWITCH in
  ""|-h|--help)
    cat <<USAGE

$UNDERLINE$BOLD$SELF$NORMAL : ${ITALIC}install and remove standalone macOS utilities$RESET

  ${UNDERLINE}Commands:$RESET
    $COMMAND$SELF$RESET             $NAMES ${COMMENT}download and install$RESET
    $COMMAND$SELF$RESET $FLAG--uninstall $NAMES ${COMMENT}remove$RESET
    $COMMAND$SELF$RESET $FLAG--purge     $NAMES ${COMMENT}remove, including config files$RESET
    $COMMAND$SELF$RESET $FLAG--list$RESET $NELLIP                     ${COMMENT}list available package names$RESET

  ${UNDERLINE}Options:$RESET
    $FLAG--prefix $PARAM${CO}dir${CC}$RESET ${COMMENT}install somewhere else (usually $BOLD$DEFAULT_PATH$NORMAL$DIM)$RESET
    $FLAG--keep$RESET         ${COMMENT}keep the downloaded packages after installing$RESET
    $FLAG--no-plain$RESET     ${COMMENT}don't create unprefixed name symlinks (eg. timeout -> gtimeout)$RESET
    $FLAG--no-helper$RESET    ${COMMENT}don't install the 'unflab' helper script$RESET
$DIM
Anything else is passed straight through to the installer.
This script is just a convenience wrapper, not a package manager. It runs:
$RESET
    ${COMMAND}curl$FLAG -fsSL $CYAN$BASE_URL/get $COMMAND| sh $FLAG-s -- $CYAN"\$@"$RESET

USAGE
    exit 0
    ;;
esac

curl -fsSL --connect-timeout 15 --max-time 60 "$BASE_URL/get" | sh -s -- "$@"
