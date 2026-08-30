#!/bin/sh
#
# {{BASE_URL}}/
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

set -eu

BASE_URL="{{BASE_URL}}"
RELEASE_URL="{{RELEASE_URL}}"

usage() { cat <<END_USAGE

  curl -fsSL $BASE_URL/get | sh -s -- ‹utility› [utility ...] [options]

Options are passed to each package's installer:
  --prefix DIR    install somewhere other than ~/.local/bin
  --uninstall     remove a previously installed utility
  --purge         remove it and its config files
  --keep          keep the downloaded packages after installing
  --no-plain      don't create unprefixed name symlinks (eg. timeout -> gtimeout)
  --no-helper     don't install the 'unflab' helper script
  --list          list the available utilities
  --help          show this help

Available utilities: $BASE_URL  (use --list to see them)

END_USAGE
}

# Error helpers
warn() { echo "unflab: $*" >&2 ; }
warn_np() { echo "$*" >&2 ; }
throw() { echo "unflab: $*" >&2; exit 1; }

# A leading `--` may or may not survive: sh/dash pass it through, zsh eats it.
[ $# -gt 0 ] && [ "$1" = "--" ] && shift

# Parse the arguments into flags and utility names, with special handling for --prefix
utils=""
want_prefix=   # Have we just seen --prefix, so need to consume the next arg?
purge=         # Remove a previously installed utility and its config files
uninstall=     # Remove a previously installed utility
keep=          # Keep the downloaded packages after installing
list=          # List the available utilities
no_plain=      # Don't create unprefixed name symlinks
no_helper=     # Don't install "unflab" (explicitly requested, or during --uninstall / --purge)
no_checksum=   # Don't verify the checksums of the downloaded archives (not documented)
prefix=""

for arg in "$@"; do

  # If we just had --prefix, the next arg is the prefix
  if [ "$want_prefix" = 1 ]; then
    prefix="$arg"
    want_prefix=0
    continue
  fi

  case "$arg" in
    --help)        usage; exit 0 ;;
    --prefix)      want_prefix=1 ;;
    --prefix=*)    prefix="${arg#--prefix=}" ;;
    --install)     ;;
    --purge)       purge=1; uninstall=1; no_helper=1 ;;
    --uninstall)   uninstall=1; no_helper=1 ;;
    --list)        list=1; no_helper=1 ;;
    --no-helper)   no_helper=1 ;;
    --keep)        keep=1 ;;
    --no-plain)    no_plain=1 ;;
    --no-checksum) no_checksum=1 ;;
    -*)            throw "unknown flag: $arg" ;;
    *)             utils="$utils $arg" ;;
  esac
done


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
[ -n "$purge" ]     && install_flags="$install_flags --purge"
[ -n "$uninstall" ] && [ -z "$purge" ] && install_flags="$install_flags --uninstall"
[ -n "$no_plain" ]  && install_flags="$install_flags --no-plain"

# If no utilities were specified, show the help.
if [ -z "$utils$list" ]; then
  warn "no utility named."
  usage >&2
  exit 2
fi

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
    { name[NR]=$1; ver[NR]=$2
      if (length($1) > m) m = length($1)
      if (length($2) > v) v = length($2) }
    END {
      m += 2; v += 2
      for (i = 1; i <= NR; i++) {
        line = line sprintf("  %-*s%-*s", m, name[i], v, "(" ver[i] ")")
        if (length(line) > 72) { print line; line = "" }
      }
      if (line != "") print line
      print " "
    }'
}

if [ -n "$list" ]; then
  # printf, not echo: whether echo expands \n is shell-dependent (bash
  # prints it literally unless xpg_echo is set), and this script is run
  # by whichever sh the user piped it to.
  printf '\nAvailable utilities:\n\n'

  available_utilities
  exit 0
fi

# Check the OS. `unflab` is macOS-only, for now (and probably forever)
case "$(uname -s)" in
  Darwin) ;;
  *) throw "these packages are macOS-only (this is $(uname -s))." ;;
esac

# Check the architecture. I'm only testing for Apple Silicon, but in
# theory it should work on Intel too; it's just that with deprecation of
# Intel macOS, the two build pipelines will diverge. As it is, the
# GitHub CI runners that generatesthe release archives use different versions
# of macOS for each architecture.
case "$(uname -m)" in
  arm64)  ARCH=arm64-apple-darwin ;;
  x86_64) ARCH=x86_64-apple-darwin ;;
  *) throw "unsupported architecture $(uname -m)." ;;
esac

# Search the index for the requested utilities, just for
# validation at this point.
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

# If there are any unknown utilities, complain and exit.
if [ -n "$unknown" ]; then
  throw "unknown utility:$unknown

Available utilities:
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

# For each util specified...
for u in $utils; do
  version=""

  # Get the version from the index
  while IFS='	' read -r name v; do
    [ "$name" = "$u" ] && { version="$v"; break; }
  done <<INDEX_EOF
$INDEX
INDEX_EOF

  # Construct the archive name
  archive="unflab-${u}-${version}-${ARCH}.tar.gz"
  echo "==> $u $version"

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
      failed="$failed $u"; continue
    fi

    # Get the expected checksum for the archive
    want="$(awk -v f="$archive" '$2 == f || $2 == "*"f {print $1}' "$sums" | head -1)"

    # Get the actual checksum for the archive
    got="$(shasum -a 256 "$TMP/$archive" | awk '{print $1}')"

    # If the expected checksum is empty, there's no published checksum for
    # this archive, so we can't check it.
    if [ -z "$want" ]; then
      warn_np "    no checksum published for $archive; use --no-checksum to install anyway"
      failed="$failed $u"; continue
    fi

    if [ "$want" != "$got" ]; then
      warn_np "    CHECKSUM MISMATCH; use --no-checksum to install anyway"
      warn_np "      expected $want"
      warn_np "      actual   $got"
      failed="$failed $u"; continue
    fi
  fi

  # Unpack the archive into its own directory. This happens whether or
  # not we checksummed -- it used to sit inside the block above, which
  # meant --no-checksum quietly installed nothing at all.
  dir="$TMP/$u"
  mkdir -p "$dir"
  if ! tar xzf "$TMP/$archive" -C "$dir"; then
    warn_np "    couldn't unpack"
    failed="$failed $u"; continue
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
if [ -n "$purge" ]; then verb="purged"
elif [ -n "$uninstall" ]; then verb="removed"
else verb="installed"
fi

# `curl | sh` output scrolls past, so end with the bit worth reading.
if [ -n "$ok" ] && [ -z "$failed" ]; then
  echo "unflab: $verb$ok"
  helper_note
  exit 0
fi

[ -n "$ok" ]     && echo "unflab: $verb$ok"
[ -n "$failed" ] && warn "FAILED$failed"
[ -n "$ok" ]     && helper_note
[ -n "$failed" ] && exit 1

exit 0
