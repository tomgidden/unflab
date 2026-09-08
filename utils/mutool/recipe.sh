# mutool -- inspect, convert and manipulate PDF files
#
# Class 1 (dependency escape). `brew install mupdf` pulls brotli,
# freetype, gumbo-parser, harfbuzz, jbig2dec, jpeg-turbo, leptonica,
# openjpeg, openssl@3, tesseract, libarchive and a whole Python --
# plus llvm, pkgconf and swig to build it.
#
# Almost none of that is mupdf's doing. Upstream vendors every one of
# those libraries in thirdparty/ and builds against them by default;
# Homebrew deliberately deletes the bundled copies and sets
# USE_SYSTEM_LIBS=yes, because a distro packager has to share libraries
# rather than duplicate them. That is the right call for Homebrew and
# the wrong one here, so this recipe simply lets mupdf build the way it
# ships: the default target uses the vendored sources and links against
# nothing but libSystem.
#
# Python is Homebrew's too, for the pymupdf bindings. Nothing here
# builds them.
#
# Two packages come out of one source tree, because the built-in
# fallback fonts dominate the binary:
#
#   mutool       ~41 MB, every fallback font upstream ships
#   mutool-lite  ~21 MB, without the per-language CJK fonts
#
# See unflab_build for what that trade actually costs.

UNFLAB_NAME=mutool
UNFLAB_VERSION=1.28.3
UNFLAB_HOMEPAGE=https://mupdf.com/
UNFLAB_LICENSE=AGPL-3.0-or-later
UNFLAB_SOURCE=https://mupdf.com/downloads/archive/mupdf-1.28.3-source.tar.gz
UNFLAB_CHECK=html:https://mupdf.com/releases/:mupdf
UNFLAB_SHA256=37c3209dc0e06fa4f3781ed44839ad933a9e6143eb4731f99e069204715bcef2
UNFLAB_ATTEST='none:upstream download page publishes no checksum or signature'
UNFLAB_TOOLCHAIN="c c++ make"
UNFLAB_CLASS=1
UNFLAB_PACKAGES="mutool mutool-lite"

# The tarball unpacks to mupdf-<version>-source, not mupdf-<version>.
UNFLAB_SRC_DIR="$BUILD_ROOT/mupdf-$UNFLAB_VERSION-source"

# Flags shared by both variants.
#
# HAVE_X11 and HAVE_GLUT are off because nothing here ships a viewer --
# only mutool, which is a command-line tool. GLUT matters especially:
# on Darwin, Makerules sets HAVE_GLUT := yes unconditionally rather
# than probing for it, so leaving it alone would build mupdf-gl against
# the GLUT and OpenGL frameworks for no reason.
#
# HAVE_LIBCRYPTO is off deliberately, and it is the one real
# limitation. mupdf uses libcrypto for exactly one thing --
# source/helpers/pkcs7/pkcs7-openssl.c, which VERIFIES PDF digital
# signatures. Enabling it would mean linking OpenSSL, which the gate
# forbids and which would need building from source for one subcommand
# most people never reach. `mutool sign` still lists and clears
# signature fields; it cannot verify them. The READMEs say so.
#
# Left alone deliberately: tesseract (OCR) and barcode (zxing-cpp) are
# opt-in upstream -- `ifeq ($(tesseract),yes)` -- so they stay off
# without being named here.
UNFLAB_MUPDF_FLAGS="build=release HAVE_X11=no HAVE_GLUT=no HAVE_LIBCRYPTO=no"

# What mutool-lite drops. These are fallback fonts: a PDF normally
# carries its own, and these are what mupdf substitutes when it does
# not -- so they only matter for documents with unembedded text.
#
#   TOFU_CJK_LANG   Source Han Serif, the per-language CJK faces. 24 MB
#                   on its own, and the whole reason for the split.
#                   CJK still renders, via DroidSansFallback, which is
#                   kept -- what is lost is correct per-language glyph
#                   forms, where the same character is drawn one way in
#                   Japanese and another in Chinese.
#   TOFU_HISTORIC   ancient and historic scripts.
#   TOFU_SYMBOL     the symbol font.
#
# Base14 (the PDF standard faces), DroidSansFallback (general CJK) and
# Charis SIL (EPUB/HTML) are kept in both: upstream flags dropping
# Base14 as making PDF "unusable" and dropping SIL as making EPUB
# "ugly".
UNFLAB_LITE_FLAGS="-DTOFU_CJK_LANG -DTOFU_HISTORIC -DTOFU_SYMBOL"

unflab_build() {
  # Both variants come out of this one tree. The second build reuses
  # every object file that isn't a font, so it costs about 20 seconds
  # on top of the first rather than a second full compile.
  #
  # OUT is what keeps them apart: mupdf writes objects and binaries
  # under it, so two OUT directories are two independent builds of the
  # same checked-out source.
  #
  # Only the mutool target is named. `make` with no target would build
  # the viewers and the extra tools as well.

  # shellcheck disable=SC2086
  make -j"$(sysctl -n hw.ncpu)" $UNFLAB_MUPDF_FLAGS \
    OUT=build/full build/full/mutool

  # shellcheck disable=SC2086
  make -j"$(sysctl -n hw.ncpu)" $UNFLAB_MUPDF_FLAGS \
    XCFLAGS="$UNFLAB_LITE_FLAGS" \
    OUT=build/lite build/lite/mutool
}

unflab_stage() {
  # Runs once per entry in UNFLAB_PACKAGES, with $PKG set to mutool or
  # mutool-lite.
  #
  # Neither package installs a bare `mutool` binary. Both install under
  # a distinguishing name -- mutool-cjk or mutool-lite -- and offer
  # `mutool` as the alias in the manifest, the same shape coreutils
  # uses for gtimeout/timeout. install.sh decides on the user's own
  # machine whether to claim the plain name.
  #
  # The two are alternatives, not companions; installing both is
  # unusual. If someone does, the second install takes over the
  # `mutool` link, and uninstalling whichever owns it removes the link
  # rather than handing it to the other. Reinstalling the one they want
  # is the fix, and is simpler than any adoption rule would be.
  case "$PKG" in
    mutool)      out=build/full; binary=mutool-cjk  ;;
    mutool-lite) out=build/lite; binary=mutool-lite ;;
    *) echo "mutool: unknown package $PKG" >&2; return 1 ;;
  esac

  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 "$out/mutool" "$STAGE_DIR/bin/$binary"

  # One man page upstream, named mutool.1. It ships under the binary's
  # name so `man mutool-cjk` resolves, with `mutool.1` as the alias --
  # install.sh only creates that alias if the same package also claimed
  # the plain `mutool` command, so the page and the command it
  # documents always agree.
  install -m 644 docs/man/mutool.1 "$STAGE_DIR/share/man/man1/$binary.1"

  # AGPL-3.0: the licence has to travel with the binary. build.sh also
  # records the source URL and its SHA-256 in .unflab/provenance, which
  # is what points at the corresponding source.
  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README-$PKG.md" "$STAGE_DIR/README.md"
}
