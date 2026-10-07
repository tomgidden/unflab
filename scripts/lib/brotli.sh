# unflab_static_brotli -- build Brotli's decoder as a static library.
#
# macOS ships no libbrotli, and a PDF may compress a stream with Brotli
# (the BrotliDecode filter), so a reader that can't decode it fails on
# a conformant file.
#
# Sets, on return:
#
#   UNFLAB_BROTLI_PREFIX   directory holding include/, lib/libbrotlidec.a
#                          and lib/libbrotlicommon.a, and lib/pkgconfig
#                          for consumers that look for libbrotlidec.pc
#
# Cached per recipe, like the other dependency helpers.

UNFLAB_BROTLI_VERSION=1.2.0
UNFLAB_BROTLI_SOURCE="https://github.com/google/brotli/archive/refs/tags/v1.2.0.tar.gz"
UNFLAB_BROTLI_SHA256=816c96e8e8f193b40151dad7e8ff37b1221d019dbcb9c35cd3fadbfe6477dfec

unflab_static_brotli() {
  local deps="$BUILD_DIR/../deps"
  local src="$BUILD_DIR/../brotli-$UNFLAB_BROTLI_VERSION"
  UNFLAB_BROTLI_PREFIX="$deps"

  [ -f "$deps/lib/libbrotlidec.a" ] && return 0

  echo "==> Building Brotli $UNFLAB_BROTLI_VERSION (static)"
  mkdir -p "$deps"

  local tarball="$BUILD_DIR/../brotli.tar.gz"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$UNFLAB_BROTLI_SOURCE"

  local actual
  actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$actual" != "$UNFLAB_BROTLI_SHA256" ]; then
    echo "brotli.sh: checksum mismatch" >&2
    echo "  expected: $UNFLAB_BROTLI_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi

  rm -rf "$src"
  tar xf "$tarball" -C "$BUILD_DIR/.."

  # BUILD_SHARED_LIBS=OFF is the point: no dylib is produced, so
  # nothing can become a runtime dependency. The CLI tool and tests
  # are of no use to a consumer.
  cmake -S "$src" -B "$src/build" \
    -DCMAKE_INSTALL_PREFIX="$deps" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBROTLI_BUILD_TOOLS=OFF \
    -DBUILD_TESTING=OFF \
    >/dev/null
  cmake --build "$src/build" -j "$(sysctl -n hw.ncpu)" >/dev/null
  cmake --install "$src/build" >/dev/null

  # libbrotlidec.pc names libbrotlicommon only in Requires.private,
  # which pkg-config reports only when asked for --static -- and
  # CMake's pkg_check_modules doesn't ask. Against static archives
  # that leaves brotlicommon's symbols undefined at link time.
  sed -i '' 's/^Libs: \(.*-lbrotlidec\)$/Libs: \1 -lbrotlicommon/' \
    "$deps/lib/pkgconfig/libbrotlidec.pc"
  grep -q '^Libs:.*-lbrotlicommon' "$deps/lib/pkgconfig/libbrotlidec.pc" || {
    echo "brotli.sh: couldn't add -lbrotlicommon to libbrotlidec.pc" >&2
    exit 1
  }
}
