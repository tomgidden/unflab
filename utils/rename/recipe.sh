# rename -- Perl-powered file rename script with many helpful built-ins

# Class 3 (convenience): adobekill has no Homebrew formula; it's
# a little Gist that Tom wrote.

UNFLAB_NAME=rename
UNFLAB_VERSION=1.601
UNFLAB_HOMEPAGE=http://plasmasturm.org/code/rename
UNFLAB_LICENSE="Artistic-1.0-Perl OR GPL-1.0-or-later"
UNFLAB_SOURCE=https://github.com/ap/rename/archive/refs/tags/v1.601.tar.gz
UNFLAB_CHECK=github-tags:ap/rename
UNFLAB_SHA256=e8fd67b662b9deddfb6a19853652306f8694d7959dfac15538a9b67339c87af4
UNFLAB_TOOLCHAIN="perl"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=rename
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream release publishes zips but no checksum for the source'

UNFLAB_SCRIPT_ONLY=1

UNFLAB_SRC_DIR="$BUILD_ROOT/rename-1.601"

unflab_build() {
  [ -f $UNFLAB_SRC_DIR/rename ] || {
    echo "rename: rename missing from upstream tarball" >&2
    return 1
  }

  perl -c $UNFLAB_SRC_DIR/rename || {
    echo "rename: rename is not valid Perl script" >&2
    return 1
  }
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  install -m 755 rename "$STAGE_DIR/bin/rename"
  install -m 644 "$RECIPE_DIR/LICENSE" "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # The documentation is POD inside the script, and macOS's own Perl
  # ships pod2man, so nothing extra is needed.
  install -d "$STAGE_DIR/share/man/man1"
  pod2man --section=1 --center='User Commands' \
    --release="rename $UNFLAB_VERSION" --name=RENAME \
    rename > "$STAGE_DIR/share/man/man1/rename.1"
  printf 'man1\t644\tshare/man/man1/rename.1\trename.1\t-\n' \
    >> "$STAGE_DIR/manifest.tsv"
}
