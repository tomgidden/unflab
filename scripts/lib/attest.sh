# unflab_attest <tarball> <sha256> <spec> -- check a downloaded tarball
# against evidence the upstream published, independently of our own
# download.
#
# bump.sh computes a SHA-256 from a tarball it just fetched. 
# That hash attests to nothing on its own -- if the download
# were tampered with, the bot would faithfully record the tampered
# file's hash. 
#
# This script attempts to verify that hash against a signature or
# checksum published separately by the upstream.
#
# Recipes declare what their upstream offers in UNFLAB_ATTEST:
#
#   gnupg:<keyring-url>   detached OpenPGP signature at <source>.sig,
#                         verified against a pinned keyring
#
#   sha256:<url>          a shasum-format file listing <basename>
#
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

      # A release may carry several signatures -- Subversion's .asc has
      # two, from different release managers -- and gpg exits non-zero
      # if ANY of them fails, including one whose key simply isn't in
      # the keyring. Taking that exit status at face value rejects a
      # perfectly good release.
      #
      # What actually matters is whether at least one signature is
      # good, so read the machine-readable status instead of the exit
      # code. GOODSIG means a signature verified against a key from
      # the keyring this recipe pinned; nothing else counts.
      #
      # TRUST_UNDEFINED is expected and ignored: the keyring is a
      # throwaway with no web of trust, and the trust anchor here is
      # having fetched KEYS from the project's own site, not gpg's
      # opinion of who signed whose key.
      local status
      status="$(gpg --homedir "$home" --batch --quiet \
                  --no-default-keyring --keyring "$tmp/keyring.gpg" \
                  --status-fd 1 --verify "$tmp/sig" "$tarball" 2>/dev/null)"

      # EXPKEYSIG counts as verified. It means the signature is
      # cryptographically good but the key has since expired -- which
      # is the normal state of any archived release whose maintainer
      # rotated a key afterwards (wget 1.25.0 is signed by a key that
      # has since expired). Expiry says nothing about whether these
      # bytes are the ones that were signed, which is the only question
      # being asked here. A revoked key would be REVKEYSIG and is not
      # accepted.
      local good
      good="$(grep -m1 -E '^\[GNUPG:\] (GOODSIG|EXPKEYSIG) ' <<<"$status")"

      if [ -n "$good" ]; then
        local who note=""
        who="$(sed -E 's/^\[GNUPG:\] (GOODSIG|EXPKEYSIG) [0-9A-F]+ //' \
               <<<"$good")"
        grep -q '^\[GNUPG:\] EXPKEYSIG ' <<<"$good" && note=", key since expired"
        echo "attest: OpenPGP signature verified (${who:-unknown signer}$note)"
        _cleanup; return 0
      fi

      # An explicitly revoked key is a refusal, not a warning: the owner
      # withdrew it, which is exactly the case expiry is not.
      if grep -q '^\[GNUPG:\] REVKEYSIG ' <<<"$status"; then
        echo "attest: signature is from a REVOKED key for $base" >&2
        _cleanup; return 1
      fi

      # No good signature. Distinguish a bad one from one we simply
      # have no key for: the first is an attack, the second is a
      # keyring that needs updating.
      if grep -q '^\[GNUPG:\] BADSIG ' <<<"$status"; then
        echo "attest: BAD SIGNATURE for $base -- the bytes do not match" >&2
        _cleanup; return 1
      fi

      echo "attest: no usable signature for $base" >&2
      echo "  none of the signatures matched a key in the pinned keyring" >&2
      _cleanup; return 1
      ;;

    *)
      echo "attest: no UNFLAB_ATTEST declared" >&2
      return 2
      ;;
  esac
}
