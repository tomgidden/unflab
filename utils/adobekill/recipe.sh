# adobekill -- kill off all Adobe Creative Cloud jobs

# Class 3 (convenience): adobekill has no Homebrew formula; it's
# a little Gist that Tom wrote.

UNFLAB_NAME=adobekill
UNFLAB_VERSION=1
UNFLAB_HOMEPAGE=https://gist.github.com/tomgidden/6a9f083988f7d4505d4e38674d416c04
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://gist.github.com/tomgidden/6a9f083988f7d4505d4e38674d416c04/archive/main.tar.gz
UNFLAB_SHA256=4230b715db84cc13524cd54c4623ada8c07929d32bce5835bbd3f23d5dbf2b97
UNFLAB_ATTEST='none:upstream publishes no checksum'
UNFLAB_TOOLCHAIN=""
UNFLAB_CLASS=3
UNFLAB_PACKAGES=adobekill

UNFLAB_SCRIPT_ONLY=1

UNFLAB_SRC_DIR="$BUILD_ROOT/6a9f083988f7d4505d4e38674d416c04-main"

unflab_build() {
  [ -f $UNFLAB_SRC_DIR/adobekill ] || {
    echo "adobekill: adobekill missing from upstream tarball" >&2
    return 1
  }

  sh -n adobekill || {
    echo "adobekill: adobekill is not valid POSIX shell" >&2
    return 1
  }
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  install -m 755 adobekill "$STAGE_DIR/bin/adobekill"
  install -m 644 "$RECIPE_DIR/LICENSE" "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
