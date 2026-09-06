# unflab_static_utf8proc -- build utf8proc as a static library.
#
# utf8proc provides Unicode character-width and case handling that does
# not depend on the C library's locale-sensitive wcwidth(3). macOS ships
# no utf8proc, so a consumer has to bring its own.
#
# Sets, on return:
#
#   UNFLAB_UTF8PROC_PREFIX   directory holding include/ and lib/libutf8proc.a
#
# Cached per recipe, like the other dependency helpers.

UNFLAB_UTF8PROC_VERSION=2.11.3
UNFLAB_UTF8PROC_SOURCE="https://github.com/JuliaStrings/utf8proc/releases/download/v2.11.3/utf8proc-2.11.3.tar.gz"
UNFLAB_UTF8PROC_SHA256=415189fd2c85cd6ee5ff26af500fa387de9ada1e3e316e93f7338551481d557d

unflab_static_utf8proc() {
  local deps="$BUILD_DIR/../deps"
  local src="$BUILD_DIR/../utf8proc-$UNFLAB_UTF8PROC_VERSION"
  UNFLAB_UTF8PROC_PREFIX="$deps"

  [ -f "$deps/lib/libutf8proc.a" ] && return 0

  echo "==> Building utf8proc $UNFLAB_UTF8PROC_VERSION (static)"
  mkdir -p "$deps/lib/pkgconfig" "$deps/include"

  local tarball="$BUILD_DIR/../utf8proc.tar.gz"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$UNFLAB_UTF8PROC_SOURCE"

  local actual
  actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$actual" != "$UNFLAB_UTF8PROC_SHA256" ]; then
    echo "utf8proc.sh: checksum mismatch" >&2
    echo "  expected: $UNFLAB_UTF8PROC_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi

  rm -rf "$src"
  tar xzf "$tarball" -C "$BUILD_DIR/.."

  # Build and place the archive by hand rather than using the install
  # target: upstream's `make install` builds and installs the dylib as
  # well, and a dylib sitting in the deps prefix is exactly what a
  # consumer's linker would rather link against. Building only
  # libutf8proc.a means there is nothing else to pick up.
  ( cd "$src" && make libutf8proc.a >/dev/null )
  install -m 644 "$src/libutf8proc.a" "$deps/lib/libutf8proc.a"
  install -m 644 "$src/utf8proc.h"    "$deps/include/utf8proc.h"

  # Consumers find utf8proc through pkg-config, so generate the .pc from
  # upstream's own template rather than hand-writing one -- it keeps the
  # Cflags (notably -DUTF8PROC_EXPORTS) correct if upstream changes them.
  sed -e "s|PREFIX|$deps|" -e "s|LIBDIR|lib|" -e "s|INCLUDEDIR|include|" \
      -e "s|VERSION|$UNFLAB_UTF8PROC_VERSION|" \
      "$src/libutf8proc.pc.in" > "$deps/lib/pkgconfig/libutf8proc.pc"
}
