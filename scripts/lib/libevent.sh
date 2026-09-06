# unflab_static_libevent -- build libevent as a static library.
#
# Sourced by recipes needing an event loop. macOS ships no libevent, so
# a tool built on it has to bring its own; linking it statically is what
# keeps the otool gate satisfied.
#
# Sets, on return:
#
#   UNFLAB_LIBEVENT_PREFIX   directory holding include/ and lib/libevent.a
#                            (and lib/pkgconfig, which consumers using
#                            pkg-config will need on PKG_CONFIG_PATH)
#
# Cached per recipe, like the other dependency helpers.

UNFLAB_LIBEVENT_VERSION=2.1.13-stable
UNFLAB_LIBEVENT_SOURCE="https://github.com/libevent/libevent/releases/download/release-2.1.13-stable/libevent-2.1.13-stable.tar.gz"
UNFLAB_LIBEVENT_SHA256=f7e9383b8c0baa81b687e5b5eecc01beefaf1b19b64151d95ed61647fe7a315c

unflab_static_libevent() {
  local deps="$BUILD_DIR/../deps"
  local src="$BUILD_DIR/../libevent-$UNFLAB_LIBEVENT_VERSION"
  UNFLAB_LIBEVENT_PREFIX="$deps"

  [ -f "$deps/lib/libevent.a" ] && return 0

  echo "==> Building libevent $UNFLAB_LIBEVENT_VERSION (static)"
  mkdir -p "$deps"

  local tarball="$BUILD_DIR/../libevent.tar.gz"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$UNFLAB_LIBEVENT_SOURCE"

  local actual
  actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$actual" != "$UNFLAB_LIBEVENT_SHA256" ]; then
    echo "libevent.sh: checksum mismatch" >&2
    echo "  expected: $UNFLAB_LIBEVENT_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi

  rm -rf "$src"
  tar xzf "$tarball" -C "$BUILD_DIR/.."

  # --disable-openssl is what keeps this from pulling in a TLS stack: the
  # bufferevent_openssl support is the only part of libevent that wants
  # one, and no consumer here uses it. --disable-shared means no dylib is
  # produced, so nothing can become a runtime dependency.
  ( cd "$src" && \
    ./configure --prefix="$deps" --disable-shared --enable-static \
      --disable-openssl --disable-samples --disable-libevent-regress \
      >/dev/null && \
    make -j"$(sysctl -n hw.ncpu)" >/dev/null && \
    make install >/dev/null )
}
