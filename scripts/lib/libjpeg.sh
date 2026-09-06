# unflab_static_libjpeg -- build libjpeg-turbo as a static library.
#
# Sourced by any recipe needing JPEG decoding. macOS ships zlib in the
# SDK but no libjpeg: there is no /usr/lib/libjpeg.dylib and no
# jpeglib.h, so a tool that decodes JPEG has to bring its own. Linking
# it statically is what keeps the otool gate satisfied.
#
# Sets, on return, for the caller to pass to its own configure:
#
#   UNFLAB_JPEG_PREFIX   directory holding include/ and lib/libjpeg.a
#
# Cached per recipe, like the OpenSSL helper: a rebuild that hasn't been
# cleaned reuses the library rather than building it again.

UNFLAB_LIBJPEG_VERSION=3.2.0
UNFLAB_LIBJPEG_SOURCE="https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.2.0/libjpeg-turbo-3.2.0.tar.gz"
UNFLAB_LIBJPEG_SHA256=6f30092cef9fb839779646608f4ee14ae3cbac989c47fa05e841b0841f09878e

unflab_static_libjpeg() {
  local deps="$BUILD_DIR/../deps"
  local src="$BUILD_DIR/../libjpeg-turbo-$UNFLAB_LIBJPEG_VERSION"
  UNFLAB_JPEG_PREFIX="$deps"

  [ -f "$deps/lib/libjpeg.a" ] && return 0

  echo "==> Building libjpeg-turbo $UNFLAB_LIBJPEG_VERSION (static)"
  mkdir -p "$deps"

  local tarball="$BUILD_DIR/../libjpeg-turbo.tar.gz"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$UNFLAB_LIBJPEG_SOURCE"

  local actual
  actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$actual" != "$UNFLAB_LIBJPEG_SHA256" ]; then
    echo "libjpeg.sh: checksum mismatch" >&2
    echo "  expected: $UNFLAB_LIBJPEG_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi

  rm -rf "$src"
  tar xzf "$tarball" -C "$BUILD_DIR/.."

  # ENABLE_SHARED=OFF is the point: no .dylib is produced, so nothing
  # can become a runtime dependency even if a consumer's linker would
  # rather have one.
  #
  # WITH_TURBOJPEG=OFF drops the alternative TurboJPEG API and its
  # tjbench tool. Consumers here use the classic libjpeg API; building
  # the second interface would only add compile time.
  cmake -S "$src" -B "$src/build" \
    -DCMAKE_INSTALL_PREFIX="$deps" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=OFF \
    -DENABLE_STATIC=ON \
    -DWITH_TURBOJPEG=OFF \
    >/dev/null
  cmake --build "$src/build" -j "$(sysctl -n hw.ncpu)" >/dev/null
  cmake --install "$src/build" >/dev/null
}

