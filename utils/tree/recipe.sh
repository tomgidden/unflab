# tree -- list directories as an indented tree
#
# Class 3 (convenience): tree's Homebrew formula has no dependencies at
# all, so there's no dependency bloat to escape here. The point is not
# needing Homebrew in the first place -- macOS ships no `tree`, and this
# is a single 110KB binary with nothing behind it.

UNFLAB_NAME=tree
UNFLAB_VERSION=2.3.2
UNFLAB_HOMEPAGE=https://oldmanprogrammer.net/source.php?dir=projects/tree
UNFLAB_LICENSE=GPL-2.0-or-later
UNFLAB_SOURCE=https://gitlab.com/OldManProgrammer/unix-tree/-/archive/2.3.2/unix-tree-2.3.2.tar.gz
UNFLAB_CHECK=gitlab-tags:OldManProgrammer/unix-tree
UNFLAB_SHA256=513a53cbc42ca1f4ea06af2bab1f5283524a3848266b1d162416f8033afc4985
UNFLAB_TOOLCHAIN="c make"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=tree

# The tarball unpacks to unix-tree-<version>, not tree-<version>.
UNFLAB_SRC_DIR="$BUILD_ROOT/unix-tree-$UNFLAB_VERSION"

unflab_build() {
  # tree's Makefile is a per-OS affair driven by commented-out blocks,
  # with the Linux defaults left active: it hardcodes gcc and passes
  # -Wdiscarded-qualifiers, a GCC warning clang doesn't have. It does
  # ship a `macos` pseudo-target, but that just re-runs make with its own
  # opinions; overriding CC and CFLAGS directly is simpler and keeps the
  # flags visible here rather than buried in the upstream Makefile.
  #
  # CPPFLAGS matches upstream's own large-file defines.
  make clean >/dev/null 2>&1 || true
  make \
    CC="${CC:-clang}" \
    CFLAGS="-O2 -std=c11 -Wall" \
    CPPFLAGS="-DLARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 tree "$STAGE_DIR/bin/tree"
  install -m 644 doc/tree.1 "$STAGE_DIR/share/man/man1/tree.1"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
