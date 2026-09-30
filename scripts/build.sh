#!/usr/bin/env bash
#
# Build driver: fetch, verify, build and stage one utility's recipe.
#
# Usage: scripts/build.sh <name>
#
# A recipe (utils/<name>/recipe.sh) declares metadata and implements:
#   unflab_build   -- configure and compile, once, in $BUILD_DIR
#   unflab_stage   -- copy artefacts for one package into $STAGE_DIR
#
# unflab_stage runs once per entry in UNFLAB_PACKAGES, with $PKG set, so
# one source tree can emit several independent packages (inetutils' ftp
# and telnet; every one of coreutils').

# This script is run by CI, so it's a bit more strict
set -euo pipefail

# The directory this script lives in.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The parent of this directory: the root of the project.
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# The name of the utility to build.
NAME="${1:?usage: build.sh <name>}"

# The directory where the recipe lives.
RECIPE_DIR="$ROOT_DIR/utils/$NAME"

# The recipe to run.
RECIPE="$RECIPE_DIR/recipe.sh"

# If the recipe exists, great. If not, complain.
[[ -f "$RECIPE" ]] || { echo "build.sh: no recipe: $RECIPE" >&2; exit 1; }

# The directory where the build lives.
BUILD_ROOT="$ROOT_DIR/build/$NAME"

# The directory where the staged package trees live, one per package.
# Not dist/ -- that's where package.sh puts the finished archives, and
# the two shouldn't share a directory.
OUT_DIR="$ROOT_DIR/out"

# Bounded, retried downloads. An unbounded curl in a sibling project
# once stalled a CI job for ~1h45m before anything timed out.
CURL_OPTS=(
  --fail --location --silent --show-error
  --connect-timeout 15 --max-time 300 --retry 2 --retry-delay 5
)

# shellcheck source=/dev/null
source "$RECIPE"

# Get and validate the recipe's metadata.
: "${UNFLAB_NAME:?recipe must set UNFLAB_NAME}"
: "${UNFLAB_VERSION:?recipe must set UNFLAB_VERSION}"
: "${UNFLAB_LICENSE:?recipe must set UNFLAB_LICENSE}"
: "${UNFLAB_SOURCE:?recipe must set UNFLAB_SOURCE}"
UNFLAB_PACKAGES="${UNFLAB_PACKAGES:-$UNFLAB_NAME}"

# Print the recipe's metadata.
echo "==> $UNFLAB_NAME $UNFLAB_VERSION ($UNFLAB_LICENSE)"

# Remove the build directory, if it exists, and make a fresh one.
rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"

# A recipe whose source lives in the repo (the unflab helper) says
# UNFLAB_SOURCE=local. There is no download to pin: the recipe directory
# is the source, and build-key.sh already hashes every file in it.
if [[ "$UNFLAB_SOURCE" == local ]]; then
  echo "==> Using the recipe directory as the source"
  SRC_DIR="$BUILD_ROOT/src"
  mkdir -p "$SRC_DIR"
  cp -R "$RECIPE_DIR/." "$SRC_DIR"
else
  # The original package's tarball to fetch.
  tarball="$BUILD_ROOT/$(basename "${UNFLAB_SOURCE%%\?*}")"

  # Try mirrors when the primary is unreachable.
  sources=("$UNFLAB_SOURCE")
  case "$UNFLAB_SOURCE" in
    https://ftp.gnu.org/gnu/*)
      rest="${UNFLAB_SOURCE#https://ftp.gnu.org/gnu/}"
      sources+=("https://ftpmirror.gnu.org/gnu/$rest")
      sources+=("https://mirrors.kernel.org/gnu/$rest")
      ;;
  esac

  # Attempt to fetch the tarball
  fetched=0
  # For each source...
  for src in "${sources[@]}"; do
    echo "==> Fetching $src"

    # If we can fetch it, we're done.
    if curl "${CURL_OPTS[@]}" -o "$tarball" "$src"; then
      fetched=1
      # Which mirror actually served it: the detached signature has to
      # be fetched from beside the tarball we got, not from the URL we
      # first tried.
      fetched_from="$src"
      break
    fi

    echo "    unreachable; trying next source" >&2
  done
  [[ "$fetched" -eq 1 ]] || { echo "build.sh: could not download $UNFLAB_NAME from any source" >&2; exit 1; }

  # If the recipe has a SHA-256 checksum, verify it.
  if [[ -n "${UNFLAB_SHA256:-}" ]]; then
    echo "==> Verifying SHA-256"

    # The actual checksum of the tarball we downloaded.
    actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"

    # If the checksums don't match, complain.
    if [[ "$actual" != "$UNFLAB_SHA256" ]]; then
      echo "build.sh: checksum mismatch for $tarball" >&2
      echo "  expected: $UNFLAB_SHA256" >&2
      echo "  actual:   $actual" >&2
      exit 1
    fi

    echo "==> Checksum OK"

    # The pin proves the tarball hasn't changed since someone recorded
    # it. Attestation asks a different question: was the tarball ever
    # the right one? UNFLAB_ATTEST names what the upstream publishes --
    # a detached signature, a checksum file, or nothing -- and
    # unflab_attest checks our pin against it.
    #
    # Off by default so an ordinary build stays fast and works offline;
    # CI sets UNFLAB_ATTEST_CHECK=1 so nothing ships unattested without
    # that being a recorded, deliberate fact.
    if [[ "${UNFLAB_ATTEST_CHECK:-0}" == "1" ]]; then
      echo "==> Checking upstream attestation"
      # shellcheck source=lib/attest.sh
      source "$SCRIPT_DIR/lib/attest.sh"
      unflab_attest "$tarball" "$UNFLAB_SHA256" \
        "${UNFLAB_ATTEST:-}" "$UNFLAB_VERSION" "${UNFLAB_SIG_URL:-$fetched_from.sig}"
      rc=$?
      # 1 means the upstream's own evidence disagrees with our pin --
      # never a network problem, always a reason to stop. 2 means the
      # evidence couldn't be fetched, which fails a release but
      # shouldn't block a developer behind a flaky connection.
      if [[ $rc -eq 1 ]]; then
        echo "build.sh: upstream attestation FAILED -- refusing to build" >&2
        exit 1
      elif [[ $rc -eq 2 && "${UNFLAB_ATTEST_STRICT:-0}" == "1" ]]; then
        echo "build.sh: attestation evidence unavailable (strict mode)" >&2
        exit 1
      fi
    fi

  else
    # No checksum, so refuse rather than silently trusting it.
    # XXX: I guess we _could_ have "NO_CHECKSUM" in the recipe to skip
    # this check, but I'm not sure it's worth the risk. We can always
    # add it later easily if there's a need.
    echo "build.sh: recipe has no UNFLAB_SHA256 -- refusing to build from" >&2
    echo "an unverified download. Add the pinned checksum to $RECIPE." >&2
    exit 1
  fi

  # Extract the tarball into the build directory.
  echo "==> Extracting"
  tar xf "$tarball" -C "$BUILD_ROOT"

  # Recipes get a predictable place to work, whatever the tarball's structure.
  SRC_DIR="${UNFLAB_SRC_DIR:-$BUILD_ROOT/${UNFLAB_NAME}-${UNFLAB_VERSION}}"

  # If it didn't work, try a single top-level directory.
  [[ -d "$SRC_DIR" ]] || {
    # Fall back to the single top-level directory the tarball unpacked.

    # Read the directories into an array. Not `mapfile`: that is bash 4,
    # and macOS ships bash 3.2, where it fails with "command not found"
    # -- which is what happened the first time a tarball whose directory
    # did not match <name>-<version> reached this fallback.
    dirs=()
    while IFS= read -r d; do
      dirs+=("$d")
    done < <(find "$BUILD_ROOT" -mindepth 1 -maxdepth 1 -type d)

    # If there's only one line, it's the one we want.
    [[ ${#dirs[@]} -eq 1 ]] && SRC_DIR="${dirs[0]}"

    # XXX: This might be turn out to be too limited; I expect at some point
    # we'll add a new utility that has a weird directory structure.
  }

  # If we didn't find a directory, complain.
  [[ -d "$SRC_DIR" ]] || { echo "build.sh: can't find source dir under $BUILD_ROOT" >&2; exit 1; }
fi

# Export the variables we need for the recipe.
export BUILD_DIR="$SRC_DIR"
export RECIPE_DIR ROOT_DIR

# Keep Homebrew out of the build's default search paths unless a recipe
# deliberately opts back in with UNFLAB_ALLOW_BREW=1.
#
# Autotools configure scripts probe for optional libraries and silently
# link whatever they find. On a CI runner that includes /opt/homebrew.
# The otool check later would catch it; this stops it happening at all.
#
# Build tools themselves (cmake, go, autotools) stay on PATH -- this only
# removes the library and header search paths, not the toolchain.
if [[ "${UNFLAB_ALLOW_BREW:-0}" != "1" ]]; then
  for var in PKG_CONFIG_PATH PKG_CONFIG_LIBDIR CPATH C_INCLUDE_PATH \
             CPLUS_INCLUDE_PATH LIBRARY_PATH LD_LIBRARY_PATH \
             DYLD_LIBRARY_PATH DYLD_FALLBACK_LIBRARY_PATH; do
    unset "$var" || true
  done

  # A bare `pkg-config` with no path set still reports Homebrew's .pc
  # files on a runner, so point it at nothing rather than unsetting it.
  export PKG_CONFIG_LIBDIR="/usr/lib/pkgconfig"
fi


# Prebuilt binaries a recipe installs rather than builds, listed in
# fetch.tsv: <package> <src> <url> <sha256> <member> <team>. The package
# ships only the row; its install.sh downloads the file on the user's
# machine and repeats the checksum and signature checks made here.
#
# They are fetched here anyway so the gate can see them. A package that
# downloads its binary at install time must still install one that
# links nothing outside the base system, and this is the only place that
# can be proven before a user runs it.
export FETCH_DIR="$BUILD_ROOT/fetch"
FETCH_TSV="$RECIPE_DIR/fetch.tsv"

# Apple's Developer ID requirement, pinned to one team: the certificate
# chains to Apple's root through the Developer ID intermediate, and the
# leaf names the team. Only a Developer ID certificate issued to that
# team can satisfy it -- an ad-hoc signature, another team's, or a
# modified binary all fail.
unflab_signed_by() {
  codesign --verify --strict -R="anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] and certificate leaf[field.1.2.840.113635.100.6.1.13] and certificate leaf[subject.OU] = \"$2\"" "$1"
}

if [[ -f "$FETCH_TSV" ]]; then
  while IFS=$'\t' read -r pkg src url sha member team; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    echo "==> Fetching $pkg: $url"

    download="$BUILD_ROOT/fetch-download"
    curl "${CURL_OPTS[@]}" -o "$download" "$url"
    actual="$(shasum -a 256 "$download" | awk '{print $1}')"
    if [[ "$actual" != "$sha" ]]; then
      echo "build.sh: checksum mismatch for $url" >&2
      echo "  expected: $sha" >&2
      echo "  actual:   $actual" >&2
      exit 1
    fi

    out="$FETCH_DIR/$pkg/$src"
    mkdir -p "$(dirname "$out")"
    if [[ "$member" == - ]]; then
      mv "$download" "$out"
    else
      tar -xOf "$download" "$member" > "$out"
      rm -f "$download"
    fi
    [[ -s "$out" ]] || { echo "build.sh: $member not found in $url" >&2; exit 1; }
    chmod 755 "$out"

    if [[ "$team" != - ]]; then
      unflab_signed_by "$out" "$team" || {
        echo "build.sh: $out is not signed by Developer ID team $team" >&2
        exit 1
      }
      echo "==> Signed by Developer ID team $team"
    fi
  done < "$FETCH_TSV"
fi

# Build the package.
echo "==> Building"
( cd "$BUILD_DIR" && unflab_build )


# Stage the package(s)
for PKG in $UNFLAB_PACKAGES; do

  # The directory where the package will be staged.
  export PKG
  export STAGE_DIR="$OUT_DIR/$PKG"

  # Remove the stage directory, if it exists, and make a fresh one.
  rm -rf "$STAGE_DIR"
  mkdir -p "$STAGE_DIR/.unflab"

  # Stage the package.
  echo "==> Staging $PKG"
  ( cd "$BUILD_DIR" && unflab_stage )

  # Metadata package.sh needs, and the provenance the GPL asks for.
  echo "$UNFLAB_VERSION" > "$STAGE_DIR/.unflab/version"
  {
    echo "name=$UNFLAB_NAME"
    echo "package=$PKG"
    echo "version=$UNFLAB_VERSION"
    echo "license=$UNFLAB_LICENSE"
    echo "homepage=${UNFLAB_HOMEPAGE:-}"
    echo "source=$UNFLAB_SOURCE"
    echo "sha256=${UNFLAB_SHA256:-}"
  } > "$STAGE_DIR/.unflab/provenance"

  # This package's fetch rows, minus the package column, for package.sh
  # to inline into install.sh.
  fetched=""
  if [[ -f "$FETCH_TSV" ]]; then
    awk -F'\t' -v OFS='\t' -v p="$PKG" '$1 == p { $1 = ""; sub(/^\t/, ""); print }' \
      "$FETCH_TSV" > "$STAGE_DIR/.unflab/fetch.tsv"
    if [[ -s "$STAGE_DIR/.unflab/fetch.tsv" ]]; then
      fetched="$FETCH_DIR/$PKG"
      cut -f2 "$STAGE_DIR/.unflab/fetch.tsv" | sed 's/^/fetch=/' >> "$STAGE_DIR/.unflab/provenance"
    else
      rm -f "$STAGE_DIR/.unflab/fetch.tsv"
    fi
  fi

  # Per-package manifest: <name>.tsv if the recipe emits several, else
  # the recipe's single manifest.tsv.  So we can amend it, we'll add
  # to it rather than clobber it, and then sort.

  MANIFEST="$STAGE_DIR/.unflab/manifest.tsv"

  if [[ -f "$RECIPE_DIR/$PKG.tsv" ]]; then
    echo >> "$MANIFEST"
    cat "$RECIPE_DIR/$PKG.tsv" >> "$MANIFEST"
  elif [[ -f "$RECIPE_DIR/manifest.tsv" ]]; then
    echo >> "$MANIFEST"
    cat "$RECIPE_DIR/manifest.tsv" >> "$MANIFEST"
  fi

  # Copy any manifest created during `unflab_stage` into the target manifest.
  if [[ -f "$STAGE_DIR/manifest.tsv" ]]; then
    echo >> "$MANIFEST"
    cat "$STAGE_DIR/manifest.tsv" >> "$MANIFEST"
  fi

  # If it already exists, sort it and remove duplicates, saving over-the-top
  if [[ -s "$MANIFEST" ]]; then
    sort -R -u "$MANIFEST" -o "$MANIFEST"
  else
    echo "build.sh: no manifest for $PKG" >&2; exit 1
  fi

  # Verify before anything can be packaged. A script-only recipe (webi)
  # ships no compiled binary, so tell verify.sh that finding no Mach-O
  # is expected there rather than an empty-package bug.
  # Not an array: macOS ships bash 3.2, where expanding an empty array
  # under `set -u` is an "unbound variable" error rather than nothing.
  verify_flag=""
  [[ "${UNFLAB_SCRIPT_ONLY:-0}" == "1" ]] && verify_flag="--script-only"
  "$SCRIPT_DIR/verify.sh" ${verify_flag:+"$verify_flag"} "$STAGE_DIR" ${fetched:+"$fetched"}
done

echo "==> Done: $UNFLAB_PACKAGES"
