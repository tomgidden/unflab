# htop -- interactive process viewer
#
# Class 1 (dependency escape), modestly: `brew install htop` brings its
# own ncurses. macOS already ships one in /usr/lib, so this build uses
# that and depends on nothing extra.

UNFLAB_NAME=htop
UNFLAB_VERSION=3.5.3
UNFLAB_HOMEPAGE=https://htop.dev/
UNFLAB_LICENSE=GPL-2.0-or-later
UNFLAB_SOURCE=https://github.com/htop-dev/htop/releases/download/3.5.3/htop-3.5.3.tar.xz
UNFLAB_SHA256=a8b164386494cb85bb255a415a3f5f80afe7a0c4491da5d113b3a0f951087e65
UNFLAB_TOOLCHAIN="c autotools make"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=htop

unflab_build() {
  # --disable-unicode is the trade that keeps this dependency-free.
  #
  # macOS ships ncurses 5.4 (2004-vintage) in /usr/lib, and its wide
  # character library, libncursesw, isn't among the SDK's stubs. htop's
  # unicode support needs ncursesw, so enabling it would mean building
  # and statically linking a modern ncurses 6.x -- several megabytes of
  # dependency for box-drawing characters. Without it htop draws its
  # meters in ASCII and works exactly as well otherwise.
  #
  # Verified: the result links only libncurses and libSystem from
  # /usr/lib, plus IOKit and CoreFoundation from /System, and displays
  # real process data.
  ./configure --disable-unicode >/dev/null
  make
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 htop "$STAGE_DIR/bin/htop"
  install -m 644 htop.1 "$STAGE_DIR/share/man/man1/htop.1"
  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
