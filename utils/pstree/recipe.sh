# pstree -- list directories as an indented tree
#
# Class 3 (convenience): pstree's Homebrew formula has no dependencies at
# all, so there's no dependency bloat to escape here.

UNFLAB_NAME=pstree
UNFLAB_VERSION=2.40
UNFLAB_HOMEPAGE=https://github.com/FredHucht/pstree
UNFLAB_LICENSE=GPL-3.0
UNFLAB_SOURCE=https://github.com/FredHucht/pstree/archive/refs/tags/v2.40.tar.gz
UNFLAB_CHECK=github:FredHucht/pstree
UNFLAB_SHA256=64d613d8f66685b29f13a80e08cddc08616cf3e315a0692cbbf9de0d8aa376b3
UNFLAB_ATTEST='none:upstream publishes no checksum'
UNFLAB_TOOLCHAIN="c"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=pstree

unflab_build() {
  make \
    CC="${CC:-clang}" \
    CFLAGS="-O2 -std=c11 -Wall"
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 pstree "$STAGE_DIR/bin/pstree"
  install -m 644 pstree.1 "$STAGE_DIR/share/man/man1/pstree.1"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
