# pdftotext -- extract text from PDF files
#
# Class 1 (dependency escape), and the clearest case in the collection.
# `brew install poppler` pulls a closure of 50 formulae -- cairo, glib,
# harfbuzz, nss, nspr, gpgme, GnuPG, five X11 libraries, a TLS stack --
# and installs 13 binaries, in order to get text out of a PDF.
#
# Almost none of it is needed. Poppler's Qt, GLib, cairo, crypto and
# image-codec backends are all optional and merely default to ON;
# FONT_CONFIGURATION=generic drops fontconfig and (with it) harfbuzz.
# What remains needs FreeType, which is built here and linked
# statically, plus zlib and iconv, which macOS provides.
#
# The result is a set of binaries depending on nothing beyond what macOS
# already ships.

UNFLAB_NAME=pdftotext
UNFLAB_VERSION=26.09.0
UNFLAB_HOMEPAGE=https://poppler.freedesktop.org/
UNFLAB_LICENSE=GPL-2.0-or-later
UNFLAB_SOURCE=https://poppler.freedesktop.org/poppler-26.09.0.tar.xz
UNFLAB_CHECK=html:https://poppler.freedesktop.org/:poppler
UNFLAB_SHA256=8059eadb6805340768f138c465b57f8164c92b4a0773c37ef031ea6c0d987b2e
UNFLAB_ATTEST='none:upstream publishes no signature or checksum alongside the tarball'
UNFLAB_TOOLCHAIN="c c++ cmake make pkg-config"

# The package is named for the tool, but the tarball is poppler's, so
# the source directory has to be given explicitly rather than inferred
# from UNFLAB_NAME-UNFLAB_VERSION.
UNFLAB_SRC_DIR="$BUILD_ROOT/poppler-26.09.0"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=pdftotext

# shellcheck source=../../scripts/lib/freetype.sh
source "$ROOT_DIR/scripts/lib/freetype.sh"

unflab_build() {
  unflab_static_freetype

  # Poppler finds FreeType through pkg-config before falling back to a
  # library search, and pkg-config reads PKG_CONFIG_PATH rather than
  # CMAKE_PREFIX_PATH. Putting our own prefix first is what makes the
  # statically built FreeType the one that gets used rather than a
  # Homebrew copy on the build machine.
  export PKG_CONFIG_PATH="$UNFLAB_FREETYPE_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  # FONT_CONFIGURATION=generic is the flag that does the most work here.
  # Poppler defaults to the fontconfig backend, which pulls fontconfig
  # and then harfbuzz; "generic" drops both. Poppler disables HarfBuzz
  # itself once the font configuration is not fontconfig.
  #
  # Font *matching* is what fontconfig provides -- finding a system font
  # to substitute for one a PDF does not embed. That matters for
  # rendering; it does not for reading text out, which is what these
  # tools do. Verified against a two-column academic paper with embedded
  # Type 1 subsets: 6152 words extracted, accents, CJK, ligatures and
  # -layout column positioning all correct.
  #
  # The image codecs are off because nothing shipped from this build
  # decodes images -- see unflab_stage. Poppler warns that files "will
  # fail to display properly" without them, which is about rendering:
  # text extraction from a page carrying a 1520x2239 RGB image was
  # verified to work.
  #
  # PNG and Cairo need WITH_*, not ENABLE_*. Poppler looks for both with
  # macro_optional_find_package, which creates a WITH_<name> option and
  # then *sets* ENABLE_LIBPNG/HAVE_CAIRO from whether the package was
  # found -- so -DENABLE_LIBPNG=OFF is silently overwritten. That is not
  # a hypothetical: it let Homebrew's libpng16.dylib into all seven
  # binaries on the CI runner, which the otool gate caught. It passed
  # locally only because this machine has no Homebrew libpng to find.
  # Cairo is written the same way and is disabled here for the same
  # reason, before it finds a version new enough to match.
  #
  # ENABLE_BOOST is off to avoid a large build-time dependency for a
  # Splash-renderer performance optimisation that is never exercised.
  cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$BUILD_DIR/../install" \
    -DCMAKE_PREFIX_PATH="$UNFLAB_FREETYPE_PREFIX" \
    -DBUILD_SHARED_LIBS=OFF \
    -DFONT_CONFIGURATION=generic \
    -DENABLE_QT5=OFF -DENABLE_QT6=OFF \
    -DENABLE_GLIB=OFF -DENABLE_GOBJECT_INTROSPECTION=OFF \
    -DENABLE_CPP=OFF \
    -DENABLE_NSS3=OFF -DENABLE_GPGME=OFF \
    -DENABLE_LIBCURL=OFF \
    -DENABLE_LIBJPEG=OFF \
    -DENABLE_LIBOPENJPEG=OFF -DENABLE_LIBTIFF=OFF \
    -DWITH_PNG=OFF -DWITH_Cairo=OFF \
    -DENABLE_LCMS=OFF \
    -DENABLE_BOOST=OFF \
    -DENABLE_UTILS=ON \
    -DBUILD_GTK_TESTS=OFF -DBUILD_QT5_TESTS=OFF \
    -DBUILD_QT6_TESTS=OFF -DBUILD_CPP_TESTS=OFF \
    -DBUILD_MANUAL_TESTS=OFF \
    >/dev/null
  cmake --build build -j "$(sysctl -n hw.ncpu)"

  # Install to a staging prefix rather than staging from the build tree,
  # so what ships is what `cmake --install` produced.
  cmake --install build >/dev/null
}

unflab_stage() {
  local pfx="$BUILD_DIR/../install"

  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"

  # Poppler builds eleven utilities. Seven ship: the ones that read a
  # PDF's text, structure or metadata, all of which work fully in this
  # configuration.
  #
  # pdfimages, pdftoppm and pdftohtml -c are deliberately NOT shipped.
  # They are raster tools, and without the image codecs this build
  # leaves out they are crippled rather than merely limited -- verified:
  # `pdftoppm -png` silently produces no file at all. Shipping a binary
  # that quietly does nothing would be worse than not shipping it.
  # Anyone wanting those wants a full poppler, and should say so.
  local tools="pdftotext pdfinfo pdffonts pdftops pdfdetach pdfseparate pdfunite"

  local t
  for t in $tools; do
    install -m 755 "$pfx/bin/$t" "$STAGE_DIR/bin/$t"
    install -m 644 "$pfx/share/man/man1/$t.1" "$STAGE_DIR/share/man/man1/$t.1"
  done

  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
