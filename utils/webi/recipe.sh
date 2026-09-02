# webi -- the webinstall.dev bootstrap wrapper
#
# Class 3 (convenience): webi has no dependency story to escape -- it's a
# single POSIX shell script with no compile step at all. It's here for
# the same reason `jq` is: it's a good tool, and having it one
# `curl … | sh` away in the same idiom as everything else is worth more
# than the purity of an all-compiled collection.
#
# There's a pleasing symmetry to shipping it, too. webinstall.dev solves
# a neighbouring problem -- fetching upstreams' own prebuilt binaries,
# for several platforms, mostly for web-dev tooling -- where unflab
# compiles from source for macOS only. The two aren't rivals, and
# packaging their installer with ours says so more clearly than a
# paragraph of README ever could. See "Why not webi?" in the README.
#
# This is the only recipe that ships no compiled binary. verify.sh works
# that out on its own -- a package with executable scripts but no Mach-O
# is script-only, while one with nothing executable is an empty build --
# so UNFLAB_SCRIPT_ONLY only states it up front, for a clearer failure
# if this recipe ever stops staging anything.

UNFLAB_NAME=webi
UNFLAB_VERSION=1.3.2
UNFLAB_HOMEPAGE=https://webinstall.dev
UNFLAB_LICENSE=MPL-2.0
UNFLAB_SOURCE=https://github.com/webinstall/webi-installers/archive/refs/tags/v1.3.2.tar.gz
UNFLAB_CHECK=github-tags:webinstall/webi-installers
UNFLAB_SHA256=c7d5c98e6c77b8edd31d6c2efd1a451f187621eb64b3d525994eca0220875ce9
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes no releases at all'
UNFLAB_TOOLCHAIN=""
UNFLAB_CLASS=3
UNFLAB_PACKAGES=webi

# The repo is a large collection of per-package installer definitions
# plus the Node service that serves them; we want exactly one file out
# of it, webi/webi.sh. So there is nothing to build.
UNFLAB_SCRIPT_ONLY=1

# The tarball unpacks to webi-installers-<version>, not webi-<version>.
UNFLAB_SRC_DIR="$BUILD_ROOT/webi-installers-$UNFLAB_VERSION"

unflab_build() {
  # Nothing to compile. Just check the one file we ship is actually
  # there and parses as a shell script, so a reorganised upstream fails
  # here rather than shipping a broken package.
  [ -f webi/webi.sh ] || {
    echo "webi: webi/webi.sh missing from upstream tarball" >&2
    return 1
  }

  sh -n webi/webi.sh || {
    echo "webi: webi/webi.sh is not valid POSIX shell" >&2
    return 1
  }
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"

  # Ships as `webi`, without the .sh -- that's the name it's invoked by,
  # and the name its own README documents.
  install -m 755 webi/webi.sh "$STAGE_DIR/bin/webi"

  # No man page upstream: webi documents itself through `webi --help`.
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
