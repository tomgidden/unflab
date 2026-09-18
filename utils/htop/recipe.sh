# htop -- interactive process viewer
#
# Class 1 (dependency escape): `brew install htop` brings its own
# ncurses. This build compiles one from source and links it statically,
# so the result depends on nothing outside the base OS -- not even
# macOS's own libncurses.

UNFLAB_NAME=htop
UNFLAB_VERSION=3.5.3
UNFLAB_HOMEPAGE=https://htop.dev/
UNFLAB_LICENSE=GPL-2.0-or-later
UNFLAB_SOURCE=https://github.com/htop-dev/htop/releases/download/3.5.3/htop-3.5.3.tar.xz
UNFLAB_CHECK=github:htop-dev/htop
UNFLAB_SHA256=a8b164386494cb85bb255a415a3f5f80afe7a0c4491da5d113b3a0f951087e65
UNFLAB_ATTEST='sha256:https://github.com/htop-dev/htop/releases/download/$V/htop-$V.tar.xz.sha256'
UNFLAB_TOOLCHAIN="c autotools make pkg-config"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=htop

# shellcheck source=../../scripts/lib/ncurses.sh
source "$ROOT_DIR/scripts/lib/ncurses.sh"

unflab_build() {
  # This recipe used to pass --disable-unicode, because macOS ships no
  # libncursesw and htop's unicode support needs one. That was the right
  # trade while a static ncurses was hypothetical; it isn't any more.
  # scripts/lib/ncurses.sh builds one for nano, and the same library
  # serves here -- so htop gets its box-drawing characters back and
  # loses a dependency at the same time, since the system libncurses it
  # used to link is no longer needed either.
  #
  # What unicode actually changes is the tree view (│ ├ └ ┌ ─) and the
  # sort indicator (△ ▽), which are ASCII +, -, | without it. The CPU
  # and memory meters are drawn with | either way.
  unflab_static_ncurses

  local deps="$BUILD_DIR/../deps"

  # htop looks for curses through pkg-config first, trying ncursesw6,
  # ncursesw5 and ncursesw before falling back to plain ncurses. Ours
  # answers to `ncursesw`, and PKG_CONFIG_PATH is what points it at our
  # prefix rather than at a Homebrew copy that may be installed on the
  # build machine.
  #
  # Without this, configure finds macOS's narrow libncurses, and htop
  # 3.5.3 does not fail on that -- it quietly builds the ASCII variant,
  # exactly what this change is undoing. The stage checks for the
  # unicode symbol rather than trusting configure's summary.
  export PKG_CONFIG_PATH="$deps/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  ./configure >/dev/null
  make
}

unflab_stage() {
  # Unicode is the point of the static ncurses, and losing it is silent:
  # if pkg-config ever failed to find our library, configure would fall
  # back to macOS's narrow libncurses and build a working ASCII htop
  # that passes every other check here. config.h is what the compiler
  # actually saw, so it is what gets checked.
  grep -q '^#define HAVE_LIBNCURSESW 1' config.h || {
    echo "htop: built without libncursesw -- did pkg-config miss our ncurses?" >&2
    return 1
  }

  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 htop "$STAGE_DIR/bin/htop"
  install -m 644 htop.1 "$STAGE_DIR/share/man/man1/htop.1"
  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
