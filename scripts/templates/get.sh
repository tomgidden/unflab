#!/bin/sh
#
# https://unflab.app/
#
## unflab bootstrap. Fetched and piped to a shell:
#
#   curl -fsSL {{BASE_URL}}/get | sh -s -- tree
#   curl -fsSL {{BASE_URL}}/get | sh -s -- wget jq tree
#   curl -fsSL {{BASE_URL}}/get | sh -s -- --prefix=/usr/local wget jq
#   curl -fsSL {{BASE_URL}}/get | sh -s -- --uninstall tree
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

#set -e
#set -u

# A leading `--` may or may not survive: sh/dash pass it through, zsh eats it.
[ $# -gt 0 ] && [ "$1" = "--" ] && shift

# Parse the arguments into flags and utility names, with special handling for --prefix
utils=""
no_color=     # Don't use colours
want_prefix=  # Have we just seen --prefix, so need to consume the next arg?
keep=         # Keep the downloaded packages after installing
no_plain=     # Don't create unprefixed name symlinks
no_helper=    # Don't install "unflab" (explicitly requested, or during --uninstall / --purge)
no_checksum=  # Don't verify the checksums of the downloaded archives (not documented)
need_usage=   # As we're parsing before usage() is defined, we just flag it for now.
bad_args=     # Anything that didn't parse
bad_prefix=   # A prefix set was attempted but failed (probably `-p -x` or similar)
no_more_args= # We've seen the -- and are done parsing flags
finished=     # We've seen the last arg and are done parsing all args
prefix=       # Non-default location to install (usually $HOME/.local)
questionable= # Was 'install'/'uninstall'/etc. included as a bare word?  Could be a brew habit
cmds=         # List of command flags

interpret_arg() {
  arg="$1"
  if [[ "$want_prefix" == "1" || "$no_more_args" == "1" ]]; then
    case "$arg" in
      "") finished=1; return ;;
      -*)
        if   [ "$want_prefix" ]; then
          bad_prefix="$arg"
        else
          bad_args="$bad_args $arg"
        fi
        ;;
      *)
        if   [ "$want_prefix" ]; then
          prefix="$arg"; want_prefix=; return
        elif [ ! "$no_more_args" ]; then
          case "$arg" in
            ginstall)  utils="$utils install" ;;
            install)   questionable+=",install"; return ;;
            uninstall) questionable+=",uninstall"; return ;;
            purge)     questionable+=",purge"; return ;;
            list)      questionable+=",list"; return ;;
          esac
        fi
        utils="$utils $arg"
        ;;
    esac
    want_prefix=
  else
    case "$arg" in
      --)               no_more_args=1 ;;
      "")               finished=1; break;;
      install)          questionable+=",install" ;;
      uninstall)        questionable+=",uninstall" ;;
      purge)            questionable+=",purge" ;;
      list)             questionable+=",list" ;;
      ginstall)         questionable=${questionable//,install/}; utils="$utils install" ;;
      -h | --help)      need_usage=1; break ;;
      -i | --install)   cmds+=",install" ;;
      -u | --uninstall) cmds+=",uninstall" ;;
      -x | --purge)     cmds+=",purge" ;;
      -l | --list)      cmds+=",list" ;;
      -p | --prefix)    want_prefix=1 ;;
           --prefix=*)  prefix="${arg#--prefix=}" ;;
      -k | --keep)      keep=1 ;;
      -c | --no-color | --no-colour) no_color=1 ;;
           --no-plain)  no_plain=1 ;;
           --no-helper) no_helper=1 ;;
           --no-checksum) no_checksum=1 ;;
      -*)               bad_args="$bad_args $arg" ;;
      *)                utils="$utils $arg" ;;
    esac
  fi
}

set -- $*
while :; do
  interpret_arg $1
  shift
  [ "$finished" = 1 ] && break
done

# Terminal colours: default to none
ESC=; RESET=; BLACK=; RED=
GREEN=; YELLOW=; BLUE=;
MAGENTA=; CYAN=; WHITE=;
DIM=; NORMAL=; BOLD=; NO_BOLD=;
ITALIC=; NO_ITALIC=; UNDERLINE=; NO_UNDERLINE=
CO="<"; CC=">"; ELLIP="..."; NELLIP="   "
EM1="‘"; EM0="’"

# Interactivity is decided by *opening* /dev/tty, not by testing it.
# Probed in a subshell first because some shells treat a failed
# redirection on `exec` as fatal to the whole script.
if [[ ! "$no_color" ]]; then
  no_color=1
  if (exec 3<>/dev/tty) 2>/dev/null; then
    exec 3<>/dev/tty
    tty_ok=1
    no_color=
  fi
fi

# If we want colours and have found a terminal, set them.
if [ ! "$no_color" ]; then
  ESC=$(printf '\033');
  RESET="$ESC[0m";			BLACK="$ESC[90m";			RED="$ESC[91m";
  GREEN="$ESC[92m";			YELLOW="$ESC[93m";		BLUE="$ESC[94m";
  MAGENTA="$ESC[95m";		CYAN="$ESC[96m";			WHITE="$ESC[97m";
  DIM="$ESC[2m";				NORMAL="$ESC[22m";
  BOLD="$ESC[1m";				NO_BOLD="$ESC[22m";
  ITALIC="$ESC[3m";			NO_ITALIC="$ESC[23m";
  UNDERLINE="$ESC[4m";	NO_UNDERLINE="$ESC[24m";
  CO="‹";		CC="›";			ELLIP="…";		NELLIP=" "
  EM1="$EM1$ITALIC$UNDERLINE"  EM0="$NO_UNDERLINE$NO_ITALIC$EM0"
fi
  
SELF="${0##*/}"
WARNING="$MAGENTA"
ERROR="$RED"
FLAG="$GREEN"
COMMAND="$YELLOW"
PARAM="$BOLD$CYAN"
OPTIONAL="$DIM$CYAN"
COMMENT="$RESET$DIM # $ITALIC"

UTIL="{{UTIL}}"
VERSION="{{VERSION}}"
BASE_URL="{{BASE_URL}}"
RELEASE_URL="{{RELEASE_URL}}"

# Error helpers
warn() {      echo "${CYAN}unflab: ${YELLOW}$*${RESET}" >&2; }
error() { 	  echo "${CYAN}unflab: ${RED}$*${RESET}" >&2; }
warn_np() {   echo "${YELLOW}$*${RESET}" >&2; }
error_np() { 	echo "${RED}$*${RESET}" >&2; }
throw() {
  echo "\n${CYAN}unflab: ${RED}$*${RESET}\n" >&2
  exit 1
}

usage() {
  cat <<END_USAGE

$UNDERLINE${BOLD}unflab$NORMAL : ${ITALIC}install and remove standalone macOS utilities$RESET
${DIM}{{BASE_URL}}$RESET

  ${YELLOW}curl $FLAG-fsSL $CYAN$BASE_URL/get $COMMAND| sh $FLAG-s -- [options] $CYAN${CO}utility${CC} [${CO}utility${CC} $ELLIP]$RESET

${UNDERLINE}Options are passed to each package's installer:${NO_UNDERLINE}

  $FLAG-h $RESET|$FLAG --help          ${COMMENT}show this help$RESET
  $FLAG-i $RESET|$FLAG --install       ${COMMENT}install one or more utilities$RESET
  $FLAG-u $RESET|$FLAG --uninstall     ${COMMENT}remove one or more previously installed utilities$RESET
  $FLAG-x $RESET|$FLAG --purge         ${COMMENT}remove it and its config files$RESET
  $FLAG-l $RESET|$FLAG --list          ${COMMENT}list the available utilities$RESET
  $FLAG-p $RESET|$FLAG --prefix ${PARAM}DIR    ${COMMENT}install somewhere other than $prefix$RESET
  $FLAG-k $RESET|$FLAG --keep          ${COMMENT}keep the downloaded packages after installing$RESET
  $FLAG     --no-plain      ${COMMENT}don't create unprefixed name symlinks (eg. timeout -> gtimeout)$RESET
  $FLAG     --no-helper     ${COMMENT}don't install the 'unflab' helper script$RESET

${UNDERLINE}Available utilities:${RESET} ${MAGENTA}$BASE_URL${RESET} ${COMMENT}(use --list to see them)${RESET}
END_USAGE
}


# Deal with bare commands, and 'install' being cited without being clear it's ‹ginstall›
clean_questionable() {
  IFS=',' read -ra q_cmds <<<"${questionable#,}"
  if [[ "${questionable}" =~ ",install" ]]; then
    q_bad="install"; q_suggest="ginstall";
    need_usage="${EM1}install$EM0 specified as a bare word; did you mean the package ${EM1}ginstall${EM0}, or did you mean ${EM1}--install$EM0?"
    return 1
  fi

  q_cmds=("${q_cmds[@]:1}")
  q_head=${questionable%,*}
  q_head=${q_head#,*}
  q_tail=${questionable##*,}
  case "${#q_cmds[*]}" in
    0) q_bad=; q_suggest=; return 0 ;;
    1) q_bad="$EM1${q_tail}$EM0"; q_suggest="$EM1--$q_cmds$EM0" ;;
    2) q_bad="$EM1${q_head//,}$EM0 and $EM1${q_tail}$EM0"; q_suggest="$EM1--$q_cmds$EM0" ;;
    *) q_bad="$EM1${q_head//,/$EM0, $EM1}$EM0 and $EM1${q_tail}$EM0"; q_suggest="$EM1--$q_cmds$EM0" ;;
  esac
  need_usage="bare commands like $q_bad are not valid; did you mean $q_suggest?"
  return 1
}

clean_questionable


clean_commands() {
  commands="${cmds#,}"
  IFS=',' read -ra c_cmds <<< "${commands}"
  c_head=${commands%,*}
  c_head=${c_head#,*}
  c_tail=${commands##*,}
  case "${#c_cmds[@]}" in
    0) command=install; return 0 ;;
    1) command=$c_head; return 0 ;;
    2) c_bad="$EM1${c_head//,}$EM0 and $EM1${c_tail}$EM0"; c_suggest="$EM1--$c_cmds$EM0" ;;
    *) c_bad="$EM1${c_head//,/$EM0, $EM1}$EM0 and $EM1${c_tail}$EM0"; c_suggest="$EM1--$c_cmds$EM0" ;;
  esac
  need_usage="you can only specify one of $c_bad"
  return 1
}

clean_commands

case "$command" in
  "") ;;
  install)   install=1 ;;
  uninstall) uninstall=1; no_helper=1 ;;
  purge)     purge=1; uninstall=1; no_helper=1 ;;
  list)      list=1; no_helper=1 ;;
  *)         need_usage="Unknown command: $command"; echo ;;
esac

# Set a reasonable default for --prefix if it wasn't specified: fall back to
# $PREFIX from the environment, then to ~/.local/bin.
#
# ${HOME:-} rather than $HOME: under `set -u` an unset HOME is a fatal
# error, and this script gets run in stripped environments (cron, CI,
# `env -i`) where it isn't always set. Falling back to the current
# directory is odd but harmless -- anyone in that situation is passing
# --prefix anyway, and --list shouldn't need a home directory at all.
prefix="${prefix:-${PREFIX:-${HOME:-.}/.local/bin}}"

# Rebuild the flags that belong to install.sh rather than to us. Parsing
# them into named variables above is easier to read, but the package's
# own installer still has to be told what was asked for -- it's the thing
# that actually does the work.
#
# --keep, --list, --no-helper and --no-checksum are ours alone and are
# deliberately not passed on; install.sh doesn't know them and would
# exit 2.
install_flags="--prefix $prefix"
[ -n "$purge" ] && install_flags="$install_flags --purge"
[ -n "$uninstall" ] && [ -z "$purge" ] && install_flags="$install_flags --uninstall"
[ -n "$no_plain" ] && install_flags="$install_flags --no-plain"

if [ "$need_usage" != 1 ]; then
  [ "$want_prefix" = 1 ] && need_usage="--prefix needs a directory"
  [ -n "$bad_prefix" ] && need_usage="--prefix needs a directory, not $EM1$bad_prefix$EM0"
  [ -n "$bad_args" ] && need_usage="unknown option: $EM1${bad_args# }$EM0"
fi

if [ "$need_usage" != '' ]; then
  usage
  if [ "$need_usage" == 1 ]; then
    exit 0
  else
    throw "$need_usage"
  fi
fi

# If no utilities were specified, show the help.
if [ -z "$utils$list" ]; then
  usage >&2
  throw "no utility named."
fi

BASE_URL=https://unflab.app
# Sane defaults for the curl command line.
CURL="curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 --retry-delay 5"

# Fetch the index once, so an unknown name fails before anything is
# downloaded rather than half way through a multi-utility install.
INDEX="$($CURL "$BASE_URL/index.txt" 2>/dev/null || true)"
[ -z "$INDEX" ] && throw "couldn't fetch the utility index from $BASE_URL/index.txt"

# Word-wrapped, column-aligned list of the utilities in $INDEX, one per
# line to stdout. Callers decide what to do with it -- feed it to throw
# for an error, or just print it for something like --list.
available_utilities() {
  printf '%s\n' "$INDEX" | awk -F'\t' '
    $4 == "refer" { next }
    $4 == "delegate" { d = d "  " $1; next }
    { n++; name[n]=$1; package[n]=$2; ver[n]=$3
      if (length($1) > m) m = length($1)
      if (length($3) > v) v = length($3) }
    END {
      NR = n
      m += 2; v += 2
      pad = length("'$DIM$NORMAL'")

      print "\n'$UNDERLINE'Standalone utilities:'$RESET'"
      c = 0
      for (i = 1; i <= NR; i++) {
        if (package[i] != "coreutils") {
          c += pad
          line  = line  sprintf("  '$NORMAL'%-*s'$DIM'%-*s'$NORMAL'", m, name[i], v, "(" ver[i] ")")
          if (length(line)-c > 70) { print line; line=""; c=0 }
        }
      }
      if (line != "") { print line; line="" }

      print "\n'$UNDERLINE$ITALIC'coreutils'$NO_ITALIC' utilities:'$RESET'"
      c = 0
      for (i = 1; i <= NR; i++) {
        if (package[i] == "coreutils") {
          c += pad
          line  = line  sprintf("  '$NORMAL'%-*s'$DIM'%-*s'$NORMAL'", m, name[i], v, "(" ver[i] ")")
          if (length(line)-c > 70) { print line; line=""; c=0 }
        }
      }
      if (line != "") { print line; line="" }

      if (d != "") {
        print "\n'$UNDERLINE'Installed by upstream'"'"'s own installer:'$RESET'"
        print d
      }
      print " "
    }'
}

if [ -n "$list" ]; then
  # printf, not echo: whether echo expands \n is shell-dependent (bash
  # prints it literally unless xpg_echo is set), and this script is run
  # by whichever sh the user piped it to.
  available_utilities
  exit 0
fi

# Check the OS. `unflab` is macOS-only, for now (and probably forever)
case "$(uname -s)" in
  Darwin) ;;
  *)      throw "these packages are macOS-only (this is $(uname -s))." ;;
esac

# Check the architecture. I'm only testing for Apple Silicon, but in
# theory it should work on Intel too; it's just that with deprecation of
# Intel macOS, the two build pipelines will diverge. As it is, the
# GitHub CI runners that generatesthe release archives use different versions
# of macOS for each architecture.
case "$(uname -m)" in
  arm64)  ARCH=arm64-apple-darwin ;;
  x86_64) ARCH=x86_64-apple-darwin ;;
  *)      throw "unsupported architecture $(uname -m)." ;;
esac

# index.txt lines are: name, recipe, version, kind, package. An older
# index has only the first three.
lookup() {
  version=; kind=; package=
  while IFS='	' read -r name recipe v k p _; do
    [ "$name" = "$1" ] || continue
    version="$v"; kind="${k:-build}"; package="${p:-$name}"
    return 0
  done <<INDEX_EOF
$INDEX
INDEX_EOF
  return 1
}

unknown=""
for u in $utils; do
  lookup "$u" || unknown="$unknown $u"
done

# A name unflab doesn't have may be one webi does.
webi=""
if [ -n "$unknown" ]; then
  SITEMAP="$($CURL https://webinstall.dev/sitemap.xml 2>/dev/null || true)"
  rest=""
  for u in $unknown; do
    case "$SITEMAP" in
      *"<loc>https://webinstall.dev/$u</loc>"*) webi="$webi $u" ;;
      *) rest="$rest $u" ;;
    esac
  done
  unknown="$rest"
fi

# If there are any unknown utilities, complain and exit.
if [ -n "$unknown" ]; then
  throw "unknown utility:$unknown$RESET

$(available_utilities)"
fi

# Create a temporary directory to hold the downloaded archives.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/unflab.XXXXXX")"

# Register a clean-up job to remove the temp dir on exit.
cleanup() {
  # If --keep is not specified, remove the temp dir on exit.
  if [ -n "$keep" ]; then
    warn "keeping downloaded archives in $TMP"
  else
    rm -rf "$TMP"
  fi
}
trap cleanup EXIT INT TERM

# Track what utils we've processed
ok=""
failed=""
skipped=""

# Stub text uses $PREFIX and $BASE for this run's directories.
expand() {
  sed -e "s|\\\$PREFIX|$prefix|g" -e "s|\\\$BASE|${prefix%/*}|g"
}

# 0 for yes, 1 for no, 2 when there's no terminal to ask on.
ask() {
  (exec </dev/tty) 2>/dev/null || return 2
  printf '%s [y/N] ' "$1" >/dev/tty
  read -r answer </dev/tty || return 1
  case "$answer" in y|Y|yes|Yes|YES) return 0 ;; esac
  return 1
}

stub_text() {
  $CURL "$BASE_URL/stub/$1" 2>/dev/null | expand
}

run_offered() {
  echo ""
  echo "    $2"
  echo ""
  ask "    Run it?"
  case $? in
    0) if sh -c "set -o pipefail; $2"; then ok="$ok $1"; else failed="$failed $1"; fi ;;
    2) warn_np "    no terminal to ask on; run it yourself if you want it"
       skipped="$skipped $1" ;;
    *) skipped="$skipped $1" ;;
  esac
}

refer() {
  echo "==> $1"
  stub_text "$2" | sed '/./s/^/    /'
  skipped="$skipped $1"
}

delegate() {
  echo "==> $1"
  stub_text "$2" | sed '/./s/^/    /'
  if [ -n "$uninstall" ]; then
    echo ""
    echo "    It isn't an unflab package, so unflab won't remove it. To do it yourself:"
    echo ""
    stub_text "$2.remove" | sed '/./s/^/      /'
    skipped="$skipped $1"
    return
  fi
  run_offered "$1" "$(stub_text "$2.install")"
}

from_webi() {
  echo "==> $1"
  echo "    Not in unflab, but webi has it: https://webinstall.dev/$1"
  if [ -n "$uninstall" ]; then
    echo "    unflab won't remove what webi installed; that page says how."
    skipped="$skipped $1"
    return
  fi
  echo "    webi installs under ~/.local whatever --prefix says, and adds"
  echo "    itself to PATH by editing your shell's rc files."
  run_offered "$1" "curl -fsS https://webi.sh/$1 | sh"
}

# For each util specified...
for u in $utils; do
  case " $webi " in *" $u "*) from_webi "$u"; echo ""; continue ;; esac
  lookup "$u"
  case "$kind" in
    refer)    refer "$u" "$package"; echo ""; continue ;;
    delegate) delegate "$u" "$package"; echo ""; continue ;;
  esac

  # Construct the archive name
  archive="unflab-${package}-${version}-${ARCH}.tar.gz"
  if [ "$package" = "$u" ]; then
    echo "==> $u $version"
  else
    echo "==> $u: in the $package package, $version"
  fi
  u="$package"

  # Download the archive
  if ! $CURL -o "$TMP/$archive" "$RELEASE_URL/$archive"; then
    warn_np "    download failed"
    failed="$failed $u"
    continue
  fi

  # Verify against the published checksum list rather than trusting the
  # transport alone -- this whole script is running piped into a shell.
  sums="$TMP/SHA256SUMS-${ARCH}.txt"

  # Assuming we're checksumming...
  if [ -z "$no_checksum" ]; then

    # If the checksums file doesn't exist, fetch it.
    if [ ! -f "$sums" ]; then
      $CURL -o "$sums" "$RELEASE_URL/SHA256SUMS-${ARCH}.txt" || true
    fi

    # No checksums file, or an empty one, means we can't verify anything.
    if [ ! -s "$sums" ]; then
      warn_np "    couldn't fetch checksums; use --no-checksum to install anyway"
      failed="$failed $u"
      continue
    fi

    # Get the expected checksum for the archive
    want="$(awk -v f="$archive" '$2 == f || $2 == "*"f {print $1}' "$sums" | head -1)"

    # Get the actual checksum for the archive
    got="$(shasum -a 256 "$TMP/$archive" | awk '{print $1}')"

    # If the expected checksum is empty, there's no published checksum for
    # this archive, so we can't check it.
    if [ -z "$want" ]; then
      warn_np "    no checksum published for $archive; use --no-checksum to install anyway"
      failed="$failed $u"
      continue
    fi

    if [ "$want" != "$got" ]; then
      warn_np "    CHECKSUM MISMATCH; use --no-checksum to install anyway"
      warn_np "      expected $want"
      warn_np "      actual   $got"
      failed="$failed $u"
      continue
    fi
  fi

  # Unpack the archive into its own directory. This happens whether or
  # not we checksummed -- it used to sit inside the block above, which
  # meant --no-checksum quietly installed nothing at all.
  dir="$TMP/$u"
  mkdir -p "$dir"
  if ! tar xzf "$TMP/$archive" -C "$dir"; then
    warn_np "    couldn't unpack"
    failed="$failed $u"
    continue
  fi

  # Hand off to the package's own installer: same script, same code path
  # as a manual download. Run as a file, not piped, so it can find the
  # payload sitting beside it.
  # shellcheck disable=SC2086
  if sh "$dir/install.sh" $install_flags; then
    ok="$ok $u"
  else
    failed="$failed $u"
  fi

  echo ""
done

# Drop in a small `unflab` command so installing or removing something
# else doesn't mean finding this URL again. It is a wrapper around this
# very script -- no state, no database -- and the note below says so, and
# says it's safe to delete.
install_helper() {
  # If --no-helper was specified (or --uninstall, --purge), don't install
  # the helper script.
  [ -n "$no_helper" ] && return 0
  [ -n "$ok" ] || return 0

  # Download the helper script, and make sure it's valid
  helper="$TMP/unflab"
  $CURL -o "$helper" "$BASE_URL/unflab" 2>/dev/null || return 0
  [ -s "$helper" ] || return 0
  head -1 "$helper" | grep -q '^#!' || return 0

  # Already got one? Say whether it matches, and leave it alone either
  # way -- it might be one you've edited, and this script has no business
  # deciding that for you.
  if [ -f "$prefix/unflab" ]; then
    have="$(shasum -a 256 "$prefix/unflab" 2>/dev/null | awk '{print $1}')"
    want="$(shasum -a 256 "$helper" 2>/dev/null | awk '{print $1}')"
    [ -n "$have" ] && [ "$have" != "$want" ] && helper_stale=1
    return 0
  fi

  # Install it to the prefix
  mkdir -p "$prefix" 2>/dev/null || return 0
  cp "$helper" "$prefix/unflab" 2>/dev/null || return 0
  chmod +x "$prefix/unflab" 2>/dev/null || return 0
  helper_installed=1
}

helper_installed=
helper_stale=
install_helper

helper_note() {
  if [ -n "$helper_stale" ]; then
    echo ""
    echo "Your $prefix/unflab is out of date. No big deal -- it still"
    echo "works. To update it:"
    echo ""
    # chmod matters: curl -o writes a plain file, so without it the
    # updated copy isn't executable and "unflab: permission denied" is a
    # confusing way to find that out.
    echo "    curl -fsSL -o $prefix/unflab $BASE_URL/unflab && chmod +x $prefix/unflab"
    echo ""
    return 0
  fi

  [ -n "$helper_installed" ] || return 0
  echo ""
  echo "Also installed: $prefix/unflab -- so you don't have to find that"
  echo "curl line again:"
  echo ""
  echo "    unflab <utility>              install another"
  echo "    unflab --uninstall <utility>  remove one"
  echo "    unflab --list                 see what there is"
  echo ""
  echo "It's a wrapper around the same one-liner, not a package manager:"
  echo "no database, no state, nothing running in the background. Delete"
  echo "it if you'd rather not have it."
  echo ""
}

# Say what actually happened: "installed jq" after an --uninstall run
# would be worse than saying nothing.
if [ -n "$purge" ]; then
  verb="purged"
elif [ -n "$uninstall" ]; then
  verb="removed"
else
  verb="installed"
fi

# `curl | sh` output scrolls past, so end with the bit worth reading.
[ -n "$ok" ] && echo "unflab: $verb$ok"
[ -n "$skipped" ] && warn "not $verb:$skipped"
[ -n "$failed" ] && warn "FAILED$failed"
[ -n "$ok" ] && helper_note
[ -n "$failed$skipped" ] && exit 1

exit 0
