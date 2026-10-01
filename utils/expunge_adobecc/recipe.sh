# expunge_adobecc -- kill off all Adobe Creative Cloud jobs

# Class 3 (convenience): expunge_adobecc has no Homebrew formula; it's
# a little Gist that Tom wrote.

UNFLAB_NAME=expunge_adobecc
UNFLAB_VERSION=2
UNFLAB_VERSION_FLAG=-
UNFLAB_HOMEPAGE=https://gist.github.com/tomgidden/6a9f083988f7d4505d4e38674d416c04
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://gist.github.com/tomgidden/6a9f083988f7d4505d4e38674d416c04/archive/main.tar.gz
UNFLAB_SHA256=015f440a8b55690bfce21445c82a032ea758c9ce41be13d49773d835c242936d
UNFLAB_ATTEST='none:upstream publishes no checksum'
UNFLAB_TOOLCHAIN=""
UNFLAB_CLASS=3
UNFLAB_PACKAGES=expunge_adobecc

UNFLAB_SCRIPT_ONLY=1

UNFLAB_SRC_DIR="$BUILD_ROOT/6a9f083988f7d4505d4e38674d416c04-main"

unflab_build() {
  [ -f $UNFLAB_SRC_DIR/expunge_adobecc ] || {
    echo "expunge_adobecc: expunge_adobecc missing from upstream tarball" >&2
    return 1
  }

  sh -n expunge_adobecc || {
    echo "expunge_adobecc: expunge_adobecc is not valid POSIX shell" >&2
    return 1
  }
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  install -m 755 expunge_adobecc "$STAGE_DIR/bin/expunge_adobecc"
  install -m 644 "$RECIPE_DIR/LICENSE" "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
