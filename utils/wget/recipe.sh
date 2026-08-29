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

# Built and linked statically, never shipped as a library. macOS provides
# no OpenSSL to link against -- the SDK has only libboringssl, which is
# Apple-private -- and wget supports only GnuTLS or OpenSSL, with no
# Secure Transport backend. So a TLS-capable wget has to bring its own.
UNFLAB_OPENSSL_VERSION=3.5.4
UNFLAB_OPENSSL_SOURCE="https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz"
UNFLAB_OPENSSL_SHA256=967311f84955316969bdb1d8d4b983718ef42338639c621ec4c34fddef355e99

unflab_build() {
  local deps="$BUILD_DIR/../deps"
  local ossl_src="$BUILD_DIR/../openssl-$UNFLAB_OPENSSL_VERSION"
  mkdir -p "$deps"

  # --- static OpenSSL -------------------------------------------------
  if [ ! -f "$deps/lib/libssl.a" ]; then
    echo "==> Building OpenSSL $UNFLAB_OPENSSL_VERSION (static)"
    local tarball="$BUILD_DIR/../openssl.tar.gz"
    curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
      -o "$tarball" "$UNFLAB_OPENSSL_SOURCE"

    local actual
    actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
    if [ "$actual" != "$UNFLAB_OPENSSL_SHA256" ]; then
      echo "wget recipe: OpenSSL checksum mismatch" >&2
      echo "  expected: $UNFLAB_OPENSSL_SHA256" >&2
      echo "  actual:   $actual" >&2
      exit 1
    fi

    rm -rf "$ossl_src"
    tar xzf "$tarball" -C "$BUILD_DIR/.."

    local target
    case "$(uname -m)" in
      arm64)  target=darwin64-arm64-cc ;;
      x86_64) target=darwin64-x86_64-cc ;;
      *) echo "wget recipe: unsupported arch $(uname -m)" >&2; exit 1 ;;
    esac

    # no-shared is the point: only .a files, so nothing can end up as a
    # runtime dependency. no-apps/no-docs/no-tests cut the build from
    # minutes to seconds -- we need the libraries, not the toolkit.
    #
    # --openssldir=/private/etc/ssl matters more than it looks: it's
    # compiled into the binary as where to find CA certificates, and
    # macOS ships a real bundle at /private/etc/ssl/cert.pem. Point it
    # anywhere else and HTTPS fails on the user's machine with a
    # certificate error.
    ( cd "$ossl_src" && \
      ./Configure "$target" no-shared no-tests no-docs no-apps \
        --prefix="$deps" --openssldir=/private/etc/ssl >/dev/null && \
      make -j"$(sysctl -n hw.ncpu)" >/dev/null && \
      make install_sw >/dev/null )
  fi

  # --- wget -----------------------------------------------------------
  # --without-libpsl drops libpsl (public-suffix cookie checks);
  # --disable-iri drops libidn2 and libunistring; --disable-nls drops
  # gettext. Between them and the static OpenSSL, all five of Homebrew's
  # dependencies are gone.
  ./configure \
    --with-ssl=openssl \
    --with-libssl-prefix="$deps" \
    --without-libpsl \
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
