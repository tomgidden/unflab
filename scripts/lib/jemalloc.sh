# unflab_static_jemalloc -- build jemalloc as a static library.
#
# Sets, on return:
#
#   UNFLAB_JEMALLOC_PREFIX   directory holding include/ and lib/libjemalloc.a
#
# IMPORTANT, and the reason this helper passes no --with-jemalloc-prefix:
#
# On macOS, jemalloc does NOT replace the malloc/calloc/free symbols. It
# registers itself as a malloc *zone* and lets the system dispatch
# through that, keeping its own public API under a "je_" prefix. This is
# the default and it is the only arrangement that works here.
#
# Configuring --with-jemalloc-prefix= (an empty prefix, which is what
# Homebrew does for its *shared* build) makes jemalloc export the plain
# symbols instead. In a statically linked binary that is fatal: the
# executable's free() becomes jemalloc's, while memory that libSystem
# allocated before main -- the environment, notably -- was not allocated
# by jemalloc. Freeing it segfaults inside jemalloc's rtree lookup on
# the first call. Verified: tmux built that way dies on `tmux -V`.
#
# A consumer that calls the public API by its unprefixed name (mallctl,
# say) should compile with -DJEMALLOC_MANGLE, which maps the plain names
# onto the je_ ones via the installed header. That is a compile-time
# alias only and does not disturb the zone arrangement.

UNFLAB_JEMALLOC_VERSION=5.3.1
UNFLAB_JEMALLOC_SOURCE="https://github.com/jemalloc/jemalloc/releases/download/5.3.1/jemalloc-5.3.1.tar.bz2"
UNFLAB_JEMALLOC_SHA256=3826bc80232f22ed5c4662f3034f799ca316e819103bdc7bb99018a421706f92

unflab_static_jemalloc() {
  local deps="$BUILD_DIR/../deps"
  local src="$BUILD_DIR/../jemalloc-$UNFLAB_JEMALLOC_VERSION"
  UNFLAB_JEMALLOC_PREFIX="$deps"

  [ -f "$deps/lib/libjemalloc.a" ] && return 0

  echo "==> Building jemalloc $UNFLAB_JEMALLOC_VERSION (static)"
  mkdir -p "$deps"

  local tarball="$BUILD_DIR/../jemalloc.tar.bz2"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$UNFLAB_JEMALLOC_SOURCE"

  local actual
  actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$actual" != "$UNFLAB_JEMALLOC_SHA256" ]; then
    echo "jemalloc.sh: checksum mismatch" >&2
    echo "  expected: $UNFLAB_JEMALLOC_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi

  rm -rf "$src"
  tar xjf "$tarball" -C "$BUILD_DIR/.."

  ( cd "$src" && \
    ./configure --prefix="$deps" --disable-shared --enable-static \
      --disable-debug >/dev/null && \
    make -j"$(sysctl -n hw.ncpu)" >/dev/null && \
    make install >/dev/null )
}
