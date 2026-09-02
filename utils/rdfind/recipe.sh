# rdfind -- find duplicate files and optionally link or delete them
#
# Class 1 (dependency escape): `brew install rdfind` brings nettle, which
# brings gmp -- three formulae for one small deduplication tool. Here
# nettle is built with public-key support disabled and linked statically,
# which removes both: rdfind only ever uses nettle's hash functions, and
# gmp is needed solely by hogweed, the public-key half.

UNFLAB_NAME=rdfind
UNFLAB_VERSION=1.8.0
UNFLAB_HOMEPAGE=https://rdfind.pauldreik.se/
UNFLAB_LICENSE=GPL-2.0-or-later
UNFLAB_SOURCE=https://rdfind.pauldreik.se/rdfind-1.8.0.tar.gz
UNFLAB_CHECK=html:https://rdfind.pauldreik.se/:rdfind
UNFLAB_SHA256=0a2d0d32002cc2dc0134ee7b649bcc811ecfb2f8d9f672aa476a851152e7af35
UNFLAB_TOOLCHAIN="c autotools make"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=rdfind

UNFLAB_NETTLE_VERSION=3.10.2
UNFLAB_NETTLE_SOURCE="https://ftp.gnu.org/gnu/nettle/nettle-3.10.2.tar.gz"
UNFLAB_NETTLE_SHA256=fe9ff51cb1f2abb5e65a6b8c10a92da0ab5ab6eaf26e7fc2b675c45f1fb519b5

unflab_build() {
  local deps="$BUILD_DIR/../deps"
  local nettle_src="$BUILD_DIR/../nettle-$UNFLAB_NETTLE_VERSION"
  mkdir -p "$deps"

  # --- static nettle --------------------------------------------------
  if [ ! -f "$deps/lib/libnettle.a" ]; then
    echo "==> Building nettle $UNFLAB_NETTLE_VERSION (static, hashes only)"
    local tarball="$BUILD_DIR/../nettle.tar.gz"
    local src="$UNFLAB_NETTLE_SOURCE"
    curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 -o "$tarball" "$src" \
      || curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 -o "$tarball" \
           "https://ftpmirror.gnu.org/gnu/nettle/nettle-$UNFLAB_NETTLE_VERSION.tar.gz"

    local actual
    actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
    if [ "$actual" != "$UNFLAB_NETTLE_SHA256" ]; then
      echo "rdfind recipe: nettle checksum mismatch" >&2
      echo "  expected: $UNFLAB_NETTLE_SHA256" >&2
      echo "  actual:   $actual" >&2
      exit 1
    fi

    rm -rf "$nettle_src"
    tar xzf "$tarball" -C "$BUILD_DIR/.."

    # --disable-public-key is what removes the gmp dependency: it stops
    # libhogweed being built at all, and hogweed is the only part of
    # nettle that needs gmp. rdfind uses hashes (md5/sha1/sha256), which
    # live in libnettle proper. Verified: no libhogweed is produced, and
    # the resulting rdfind links nothing outside /usr/lib.
    ( cd "$nettle_src" && \
      ./configure --prefix="$deps" \
        --disable-shared --enable-static \
        --disable-documentation --disable-public-key >/dev/null && \
      make -j"$(sysctl -n hw.ncpu)" >/dev/null && \
      make install >/dev/null )
  fi

  # --- rdfind ---------------------------------------------------------
  # -std=c++17 is required, not a preference: rdfind.cc has a static
  # assertion demanding C++17, and configure's default (C++14 here)
  # fails it with "this code requires a C++17 capable compiler".
  #
  # --without-xxhash keeps the optional xxhash dependency out; nettle
  # already provides everything rdfind needs to hash with.
  ./configure \
    --without-xxhash \
    CXXFLAGS="-O2 -std=c++17" \
    CPPFLAGS="-I$deps/include" \
    LDFLAGS="-L$deps/lib" \
    >/dev/null
  make
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 rdfind "$STAGE_DIR/bin/rdfind"
  install -m 644 rdfind.1 "$STAGE_DIR/share/man/man1/rdfind.1"
  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
