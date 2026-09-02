# unflab_attest <tarball> <sha256> <spec> -- check a downloaded tarball
# against evidence the upstream published, independently of our own
# download.
#
# Why this exists: bump.sh computes a SHA-256 from a tarball it just
# fetched. That hash attests to nothing on its own -- if the download
# were tampered with, the bot would faithfully record the tampered
# file's hash. Comparing against a signature or checksum the upstream
# published separately is what turns a recomputation into a check.
#
# Recipes declare what their upstream offers in UNFLAB_ATTEST:
#
#   gnupg:<keyring-url>   detached OpenPGP signature at <source>.sig,
#                         verified against a pinned keyring
#   sha256:<url>          a shasum-format file listing <basename>
#   none:<reason>         nothing published -- the reason is recorded
#                         so "unverifiable" is a stated fact rather
#                         than an omission nobody noticed
#
# Prints a one-line verdict and returns:
#   0  verified, or declared unverifiable
#   1  evidence existed and DISAGREED -- treat as hostile
#   2  evidence was expected but could not be fetched
#
# The distinction between 1 and 2 matters: a mismatch means the bytes
# are wrong, a fetch failure means the network is. Only the first is a
# security event.

unflab_attest() {
  local tarball="$1" sha="$2" spec="${3:-}" version="${4:-}"

  # Specs embed $V where the version goes. Substituted rather than
  # eval'd: a recipe is trusted input, but running eval over a URL
  # string is a habit worth not forming.
  spec="${spec//\$V/$version}"

  local kind="${spec%%:*}" rest="${spec#*:}"
  local base
  base="$(basename "$tarball")"

  case "$kind" in
    none)
      echo "attest: not verifiable -- ${rest:-no reason recorded}"
      return 0
      ;;

    sha256)
      local published
      published="$(curl -fsSL --connect-timeout 15 --max-time 60 --retry 2 \
                     "$rest" 2>/dev/null)" || {
        echo "attest: could not fetch $rest" >&2
        return 2
      }

      # Match the basename as a whole field. A substring match would
      # let jq-1.8.1.tar.gz.asc satisfy a check meant for the tarball.
      local want
      want="$(printf '%s\n' "$published" |
              awk -v f="$base" '$2 == f || $2 == "*" f { print $1; exit }')"

      if [ -z "$want" ]; then
        echo "attest: $base not listed in $rest" >&2
        return 2
      fi

      if [ "$want" != "$sha" ]; then
        echo "attest: MISMATCH for $base" >&2
        echo "  published: $want" >&2
        echo "  ours:      $sha" >&2
        return 1
      fi

      echo "attest: sha256 matches upstream's published checksum"
      return 0
      ;;

    gnupg)
      local sig_url="${5:-$tarball.sig}"

      # Distinguish "no gpg here" from "verification failed". A
      # developer without gnupg installed should be told that, not
      # handed a keyring error that looks like a bad signature.
      if ! command -v gpg >/dev/null 2>&1; then
        echo "attest: gpg not installed -- cannot verify the signature" >&2
        return 2
      fi
      local tmp
      tmp="$(mktemp -d)"
      # A short GNUPGHOME: gpg-agent's socket path has a ~104 byte
      # limit and a long temp path silently breaks agent startup.
      local home="/tmp/ua.$$"
      mkdir -p "$home"
      chmod 700 "$home"

      _cleanup() { rm -rf "$tmp" "$home"; }

      if ! curl -fsSL --connect-timeout 15 --max-time 60 --retry 2 \
             -o "$tmp/sig" "$sig_url" 2>/dev/null; then
        echo "attest: could not fetch signature $sig_url" >&2
        _cleanup; return 2
      fi

      if ! curl -fsSL --connect-timeout 15 --max-time 60 --retry 2 \
             -o "$tmp/keyring" "$rest" 2>/dev/null; then
        echo "attest: could not fetch keyring $rest" >&2
        _cleanup; return 2
      fi

      # The keyring is the trust anchor: it is fetched from the
      # upstream's own site and pinned in the recipe. Importing keys
      # from a keyserver on demand would verify only that *someone*
      # signed it.
      if ! gpg --homedir "$home" --batch --quiet \
             --no-default-keyring --keyring "$tmp/keyring.gpg" \
             --import "$tmp/keyring" 2>/dev/null; then
        echo "attest: could not import keyring" >&2
        _cleanup; return 2
      fi

      if gpg --homedir "$home" --batch --quiet \
           --no-default-keyring --keyring "$tmp/keyring.gpg" \
           --verify "$tmp/sig" "$tarball" 2>/dev/null; then
        echo "attest: OpenPGP signature verified"
        _cleanup; return 0
      fi

      echo "attest: SIGNATURE VERIFICATION FAILED for $base" >&2
      _cleanup; return 1
      ;;

    *)
      echo "attest: no UNFLAB_ATTEST declared" >&2
      return 2
      ;;
  esac
}
