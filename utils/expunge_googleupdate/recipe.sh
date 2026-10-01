# expunge_googleupdate -- kill off all Adobe Creative Cloud jobs

# Class 3 (convenience): expunge_googleupdate has no Homebrew formula; it's
# a little Gist that Tom wrote.

UNFLAB_NAME=expunge_googleupdate
UNFLAB_VERSION=1
UNFLAB_VERSION_FLAG=-
UNFLAB_HOMEPAGE=https://gist.github.com/tomgidden/6cfc0e2a3faa0300edd86e36c35a18f7
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://gist.github.com/tomgidden/6cfc0e2a3faa0300edd86e36c35a18f7/archive/main.tar.gz
UNFLAB_SHA256=2c3f4fe0067c6d76ca22cbe0ee6eac433d5fdd8c7718ae8d6f6f6a13fb362af0
UNFLAB_ATTEST='none:upstream publishes no checksum'
UNFLAB_TOOLCHAIN=""
UNFLAB_CLASS=3
UNFLAB_PACKAGES=expunge_googleupdate

UNFLAB_SCRIPT_ONLY=1

UNFLAB_SRC_DIR="$BUILD_ROOT/6cfc0e2a3faa0300edd86e36c35a18f7-main"

unflab_build() {
  [ -f $UNFLAB_SRC_DIR/expunge_googleupdate ] || {
    echo "expunge_googleupdate: expunge_googleupdate missing from upstream tarball" >&2
    return 1
  }

  sh -n expunge_googleupdate || {
    echo "expunge_googleupdate: expunge_googleupdate is not valid POSIX shell" >&2
    return 1
  }
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  install -m 755 expunge_googleupdate "$STAGE_DIR/bin/expunge_googleupdate"
  install -m 644 "$RECIPE_DIR/LICENSE" "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
