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
# and telnet; coreutils' ~105).

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

# The original package's tarball to fetch.
tarball="$BUILD_ROOT/$(basename "${UNFLAB_SOURCE%%\?*}")"

# Try mirrors when the primary is unreachable. ftp.gnu.org timed out on a
# CI runner while the other architecture's job downloaded the same file
# fine, so a transient outage there shouldn't fail a build. We rely on
# UNFLAB_SHA256 later to verify the tarball's checksum.
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

  # bash: read the output of `find` into an array
  mapfile -t dirs < <(find "$BUILD_ROOT" -mindepth 1 -maxdepth 1 -type d)

  # If there's only one line, it's the one we want.
  [[ ${#dirs[@]} -eq 1 ]] && SRC_DIR="${dirs[0]}"

  # XXX: This might be turn out to be too limited; I expect at some point 
  # we'll add a new utility that has a weird directory structure.
}

# If we didn't find a directory, complain.
[[ -d "$SRC_DIR" ]] || { echo "build.sh: can't find source dir under $BUILD_ROOT" >&2; exit 1; }

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
    echo "sha256=$UNFLAB_SHA256"
  } > "$STAGE_DIR/.unflab/provenance"

  # Per-package manifest: <name>.tsv if the recipe emits several, else
  # the recipe's single manifest.tsv.
  if [[ -f "$RECIPE_DIR/$PKG.tsv" ]]; then
    cp "$RECIPE_DIR/$PKG.tsv" "$STAGE_DIR/.unflab/manifest.tsv"

  elif [[ -f "$RECIPE_DIR/manifest.tsv" ]]; then
    cp "$RECIPE_DIR/manifest.tsv" "$STAGE_DIR/.unflab/manifest.tsv"

  elif [[ -f "$STAGE_DIR/.unflab/manifest.tsv" ]]; then
    : # recipe generated it itself (coreutils' ~105)

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
  "$SCRIPT_DIR/verify.sh" ${verify_flag:+"$verify_flag"} "$STAGE_DIR"
done

echo "==> Done: $UNFLAB_PACKAGES"
