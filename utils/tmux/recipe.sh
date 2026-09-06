# tmux -- terminal multiplexer
#
# Class 1 (dependency escape). `brew install tmux` pulls libevent,
# ncurses, utf8proc and jemalloc. Three of those are genuinely needed
# and are compiled from source and linked statically here; the fourth,
# ncurses, macOS already provides.
#
# What ships is one binary depending on nothing beyond what macOS has.

UNFLAB_NAME=tmux
UNFLAB_VERSION=3.7c
UNFLAB_HOMEPAGE=https://tmux.github.io/
UNFLAB_LICENSE=ISC
UNFLAB_SOURCE=https://github.com/tmux/tmux/releases/download/3.7c/tmux-3.7c.tar.gz
UNFLAB_CHECK=github:tmux/tmux
UNFLAB_SHA256=7c60cae9a0e25288e2e24750aafc9e8800fc7fd4555e447e1b29ee4201cfb3bf
UNFLAB_ATTEST='none:upstream publishes no signature or checksum file with its releases'
UNFLAB_TOOLCHAIN="c make pkg-config"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=tmux

# pkg-config is a real build requirement, not a nicety: tmux locates
# jemalloc through PKG_CHECK_MODULES with no AC_SEARCH_LIBS fallback, so
# without it the jemalloc detection fails outright. ncurses and utf8proc
# do have fallbacks; jemalloc does not.

# shellcheck source=../../scripts/lib/libevent.sh
source "$ROOT_DIR/scripts/lib/libevent.sh"
# shellcheck source=../../scripts/lib/utf8proc.sh
source "$ROOT_DIR/scripts/lib/utf8proc.sh"
# shellcheck source=../../scripts/lib/jemalloc.sh
source "$ROOT_DIR/scripts/lib/jemalloc.sh"

unflab_build() {
  unflab_static_libevent
  unflab_static_utf8proc
  unflab_static_jemalloc

  local deps="$BUILD_DIR/../deps"

  # tmux resolves ncurses, utf8proc and jemalloc through pkg-config
  # before falling back to a library search, and pkg-config reads
  # PKG_CONFIG_PATH rather than anything passed on the command line.
  # Putting our own prefix first is what makes the statically built
  # libraries the ones that get used rather than a Homebrew copy that
  # happens to be installed on the build machine.
  export PKG_CONFIG_PATH="$deps/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  # --enable-jemalloc is not optional on macOS. tmux 3.7c's configure
  # refuses to proceed on darwin without an explicit choice, because
  # macOS calloc(3) does not reliably zero allocations (tmux issue 5385);
  # building with jemalloc is the headline fix in the 3.7c changelog.
  # Declining it would ship a knowingly-buggy tmux.
  #
  # -DJEMALLOC_MANGLE is needed with it: our jemalloc keeps its public
  # API under the je_ prefix (see scripts/lib/jemalloc.sh for why that
  # is the only workable arrangement on macOS), while tmux calls
  # mallctl() unprefixed. The macro maps one onto the other at compile
  # time.
  #
  # --enable-utf8proc matches what upstream does by default on darwin:
  # character widths come from utf8proc rather than the C library's
  # locale-sensitive wcwidth(3).
  #
  # ncurses comes from macOS itself -- /usr/lib/libncurses.5.4.dylib,
  # which despite the name reports itself as ncurses 6.0 -- so it needs
  # no --with flag and leaves a /usr/lib path the gate accepts.
  ./configure \
    --prefix="$BUILD_DIR/../install" \
    --enable-utf8proc \
    --enable-jemalloc \
    CPPFLAGS="-I$deps/include -DJEMALLOC_MANGLE" \
    LDFLAGS="-L$deps/lib" \
    >/dev/null
  make -j"$(sysctl -n hw.ncpu)"

  # Install to a staging prefix rather than staging from the build tree,
  # so what ships is what `make install` produced.
  make install >/dev/null
}

unflab_stage() {
  local pfx="$BUILD_DIR/../install"

  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"

  install -m 755 "$pfx/bin/tmux" "$STAGE_DIR/bin/tmux"
  install -m 644 "$pfx/share/man/man1/tmux.1" "$STAGE_DIR/share/man/man1/tmux.1"

  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
