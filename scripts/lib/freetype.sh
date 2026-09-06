# unflab_static_freetype -- build FreeType as a static library.
#
# macOS ships no FreeType to link against: there is no libfreetype in
# the SDK and no headers, so a consumer has to bring its own.
#
# Sets, on return:
#
#   UNFLAB_FREETYPE_PREFIX   directory holding include/ and lib/libfreetype.a
#                            (and lib/pkgconfig for consumers that look
#                            for freetype2.pc)
#
# Cached per recipe, like the other dependency helpers.

UNFLAB_FREETYPE_VERSION=2.14.3
UNFLAB_FREETYPE_SOURCE="https://downloads.sourceforge.net/project/freetype/freetype2/2.14.3/freetype-2.14.3.tar.xz"
UNFLAB_FREETYPE_SHA256=36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f

unflab_static_freetype() {
  local deps="$BUILD_DIR/../deps"
  local src="$BUILD_DIR/../freetype-$UNFLAB_FREETYPE_VERSION"
  UNFLAB_FREETYPE_PREFIX="$deps"

  [ -f "$deps/lib/libfreetype.a" ] && return 0

  echo "==> Building FreeType $UNFLAB_FREETYPE_VERSION (static)"
  mkdir -p "$deps"

  local tarball="$BUILD_DIR/../freetype.tar.xz"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$UNFLAB_FREETYPE_SOURCE"

  local actual
  actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$actual" != "$UNFLAB_FREETYPE_SHA256" ]; then
    echo "freetype.sh: checksum mismatch" >&2
    echo "  expected: $UNFLAB_FREETYPE_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi

  rm -rf "$src"
  tar xf "$tarball" -C "$BUILD_DIR/.."

  # FreeType's optional dependencies are all about *rendering*: libpng
  # for embedded bitmap glyphs, harfbuzz for complex-script shaping,
  # brotli and bzip2 for compressed font tables. Disabling them keeps
  # the dependency count at zero. A consumer that needs any of them
  # should build its own FreeType rather than have this helper grow
  # options nothing here uses.
  #
  # BUILD_SHARED_LIBS=OFF is the point: no dylib is produced, so
  # nothing can become a runtime dependency.
  cmake -S "$src" -B "$src/build" \
    -DCMAKE_INSTALL_PREFIX="$deps" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_PNG=TRUE \
    -DFT_DISABLE_HARFBUZZ=TRUE \
    -DFT_DISABLE_BROTLI=TRUE \
    -DFT_DISABLE_BZIP2=TRUE \
    >/dev/null
  cmake --build "$src/build" -j "$(sysctl -n hw.ncpu)" >/dev/null
  cmake --install "$src/build" >/dev/null
}
