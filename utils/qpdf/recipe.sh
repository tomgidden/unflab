# qpdf -- structural, content-preserving PDF transformation
#
# Class 1 (dependency escape). `brew install qpdf` pulls jpeg-turbo and
# openssl@3 (which in turn wants ca-certificates), and keeps an OpenSSL
# on your machine that then needs updating for its own sake.
#
# Neither is necessary. qpdf ships a native crypto provider covering
# everything the PDF encryption formats need -- RC4, AES and SHA-2 --
# so the OpenSSL dependency is a build-time default rather than a
# requirement. Selecting the native provider removes it outright.
# libjpeg is genuinely needed and is linked statically.
#
# What ships is three binaries depending on nothing beyond what macOS
# already has.

UNFLAB_NAME=qpdf
UNFLAB_VERSION=12.4.1
UNFLAB_HOMEPAGE=https://qpdf.sourceforge.io/
UNFLAB_LICENSE=Apache-2.0
UNFLAB_SOURCE=https://github.com/qpdf/qpdf/releases/download/v12.4.1/qpdf-12.4.1.tar.gz
UNFLAB_CHECK=github:qpdf/qpdf
UNFLAB_SHA256=f045aa277be2356ff53a89a8622945958291177d2483afc20ede7c8a8cd3873c
UNFLAB_ATTEST='sha256:https://github.com/qpdf/qpdf/releases/download/v$V/qpdf-$V.sha256'
UNFLAB_TOOLCHAIN="c c++ cmake make"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=qpdf

# Upstream publishes both a detached OpenPGP signature and a checksum
# file. The checksum is used here because it covers every release
# artifact in one fetch and needs no keyring pinned; the signature is
# the stronger evidence and is the natural upgrade if this recipe ever
# warrants it.

# shellcheck source=../../scripts/lib/libjpeg.sh
source "$ROOT_DIR/scripts/lib/libjpeg.sh"

unflab_build() {
  unflab_static_libjpeg

  # USE_IMPLICIT_CRYPTO=OFF stops cmake linking whatever crypto library
  # it happens to find -- on a runner with Homebrew present that would
  # silently be openssl@3, which is exactly the dependency this recipe
  # exists to remove. REQUIRE_CRYPTO_NATIVE=ON then makes the choice
  # explicit and fails the build rather than falling back, so a future
  # upstream change can't quietly reintroduce OpenSSL.
  #
  # BUILD_SHARED_LIBS=OFF links libqpdf into the executables instead of
  # leaving them needing a .dylib from the build tree.
  #
  # zlib is not built here: macOS ships it in the SDK as a real system
  # library, so linking it leaves a /usr/lib path the gate accepts.
  #
  # INSTALL_EXAMPLES/PKGCONFIG/CMAKE_PACKAGE are all developer-facing
  # files for building *against* libqpdf. This packages the tool, not
  # the library.

  # qpdf finds zlib and libjpeg via pkg_check_modules BEFORE falling back
  # to find_library, and pkg-config consults PKG_CONFIG_PATH -- not
  # CMAKE_PREFIX_PATH. On a runner with Homebrew's jpeg-turbo installed
  # that would find Homebrew's .pc file and link its dylib, quietly
  # undoing the static build. Putting our own prefix first is what makes
  # the statically-built libjpeg the one that gets used.
  #
  # zlib is deliberately left to the system: macOS has no zlib.pc, so
  # pkg-config misses it and the find_library fallback picks up the SDK's
  # libz -- which is what's wanted.
  export PKG_CONFIG_PATH="$UNFLAB_JPEG_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$BUILD_DIR/../install" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DUSE_IMPLICIT_CRYPTO=OFF \
    -DREQUIRE_CRYPTO_NATIVE=ON \
    -DBUILD_DOC=OFF \
    -DINSTALL_EXAMPLES=OFF \
    -DINSTALL_PKGCONFIG=OFF \
    -DINSTALL_CMAKE_PACKAGE=OFF \
    -DCMAKE_PREFIX_PATH="$UNFLAB_JPEG_PREFIX" \
    -DCMAKE_INCLUDE_PATH="$UNFLAB_JPEG_PREFIX/include" \
    -DCMAKE_LIBRARY_PATH="$UNFLAB_JPEG_PREFIX/lib" \
    >/dev/null
  cmake --build build -j "$(sysctl -n hw.ncpu)"

  # Install to a staging prefix rather than staging from the build tree.
  # cmake relinks on install; taking the binaries straight out of build/
  # is how a package ends up shipping something that still refers to the
  # build directory.
  cmake --install build >/dev/null
}

unflab_stage() {
  local pfx="$BUILD_DIR/../install"

  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"

  # Three binaries, all from one build and all documented by their own
  # man page. fix-qdf and zlib-flate are small helpers that exist to
  # support qpdf's QDF workflow -- fix-qdf repairs a QDF file after
  # hand-editing, zlib-flate does the raw compression qpdf's streams
  # use. They belong with qpdf rather than as separate packages.
  install -m 755 "$pfx/bin/qpdf"        "$STAGE_DIR/bin/qpdf"
  install -m 755 "$pfx/bin/fix-qdf"     "$STAGE_DIR/bin/fix-qdf"
  install -m 755 "$pfx/bin/zlib-flate"  "$STAGE_DIR/bin/zlib-flate"

  install -m 644 "$pfx/share/man/man1/qpdf.1"       "$STAGE_DIR/share/man/man1/qpdf.1"
  install -m 644 "$pfx/share/man/man1/fix-qdf.1"    "$STAGE_DIR/share/man/man1/fix-qdf.1"
  install -m 644 "$pfx/share/man/man1/zlib-flate.1" "$STAGE_DIR/share/man/man1/zlib-flate.1"

  install -m 644 LICENSE.txt "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
