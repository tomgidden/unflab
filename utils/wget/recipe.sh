# wget -- retrieve files over HTTP, HTTPS and FTP
#
# Class 1 (dependency escape), and the flagship case. `brew install wget`
# pulls openssl@3, libidn2, libunistring, libpsl and gettext -- five
# formulae, all of which then need keeping updated -- to get one download
# tool. This builds OpenSSL from source and links it statically, and
# drops the rest, so what you install is a single binary depending on
# nothing but libraries macOS already has.

UNFLAB_NAME=wget
UNFLAB_VERSION=1.25.0
UNFLAB_HOMEPAGE=https://www.gnu.org/software/wget/
UNFLAB_LICENSE=GPL-3.0-or-later
UNFLAB_SOURCE=https://ftp.gnu.org/gnu/wget/wget-1.25.0.tar.gz
UNFLAB_SHA256=766e48423e79359ea31e41db9e5c289675947a7fcf2efdcedb726ac9d0da3784
UNFLAB_TOOLCHAIN="c autotools make perl"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=wget

# OpenSSL is built and linked statically by the shared helper, never
# shipped as a library. macOS provides no OpenSSL to link against -- the
# SDK has only libboringssl, which is Apple-private -- and wget supports
# only GnuTLS or OpenSSL, with no Secure Transport backend. So a
# TLS-capable wget has to bring its own.
# shellcheck source=../../scripts/lib/openssl.sh
source "$ROOT_DIR/scripts/lib/openssl.sh"

unflab_build() {
  unflab_static_openssl
  local deps="$UNFLAB_SSL_PREFIX"

  # --- wget -----------------------------------------------------------
  # --without-libpsl drops libpsl (public-suffix cookie checks);
  # --disable-iri drops libidn2 and libunistring; --disable-nls drops
  # gettext. Between them and the static OpenSSL, all five of Homebrew's
  # dependencies are gone.
  #
  # --disable-pcre2/--disable-pcre are not optional tidying: wget's
  # configure opportunistically detects PCRE for --regex-type=pcre, and
  # on a machine that happens to have Homebrew's pcre2 (every macOS CI
  # runner does) it links /opt/homebrew/opt/pcre2/lib/libpcre2-8.0.dylib
  # straight into the binary. That path exists on no user's Mac. The
  # otool gate caught exactly this. --without-metalink and --without-cares
  # are the same class of hazard, disabled pre-emptively rather than
  # relying on the build machine being clean.
  ./configure \
    --with-ssl=openssl \
    --with-libssl-prefix="$deps" \
    --without-libpsl \
    --disable-pcre2 \
    --disable-pcre \
    --without-metalink \
    --without-cares \
    --with-included-libunistring \
    --without-libunistring-prefix \
    --disable-iri \
    --disable-nls \
    CPPFLAGS="-I$deps/include" \
    LDFLAGS="-L$deps/lib" \
    >/dev/null
  make
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 src/wget "$STAGE_DIR/bin/wget"
  install -m 644 doc/wget.1 "$STAGE_DIR/share/man/man1/wget.1"
  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
