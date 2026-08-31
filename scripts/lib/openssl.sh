# unflab_static_openssl -- build OpenSSL as static libraries only.
#
# Sourced by any recipe whose upstream needs TLS. macOS ships no OpenSSL
# to link against: the SDK carries only libboringssl, which is Apple-
# private with no headers, so a TLS-capable binary has to bring its own.
# Linking it statically is what keeps the otool gate satisfied -- the
# library ends up inside the executable rather than as a dependency on a
# path that exists on no user's machine.
#
# Sets, on return, for the caller to pass to its own configure:
#
#   UNFLAB_SSL_PREFIX   directory holding include/ and lib/lib{ssl,crypto}.a
#
# The build is cached per recipe: a rebuild that hasn't been cleaned
# reuses the libraries rather than spending the minute again.

UNFLAB_OPENSSL_VERSION=3.5.4
UNFLAB_OPENSSL_SOURCE="https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz"
UNFLAB_OPENSSL_SHA256=967311f84955316969bdb1d8d4b983718ef42338639c621ec4c34fddef355e99

unflab_static_openssl() {
  local deps="$BUILD_DIR/../deps"
  local src="$BUILD_DIR/../openssl-$UNFLAB_OPENSSL_VERSION"
  UNFLAB_SSL_PREFIX="$deps"

  [ -f "$deps/lib/libssl.a" ] && return 0

  echo "==> Building OpenSSL $UNFLAB_OPENSSL_VERSION (static)"
  mkdir -p "$deps"

  local tarball="$BUILD_DIR/../openssl.tar.gz"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$UNFLAB_OPENSSL_SOURCE"

  # The pin is the integrity gate. OpenSSL publishes no signature this
  # build checks, so a matching SHA-256 is the whole of the guarantee.
  local actual
  actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$actual" != "$UNFLAB_OPENSSL_SHA256" ]; then
    echo "openssl.sh: checksum mismatch" >&2
    echo "  expected: $UNFLAB_OPENSSL_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi

  rm -rf "$src"
  tar xzf "$tarball" -C "$BUILD_DIR/.."

  local target
  case "$(uname -m)" in
    arm64)  target=darwin64-arm64-cc ;;
    x86_64) target=darwin64-x86_64-cc ;;
    *) echo "openssl.sh: unsupported arch $(uname -m)" >&2; exit 1 ;;
  esac

  # no-shared is the point: only .a files, so nothing can become a
  # runtime dependency. no-apps/no-docs/no-tests cut the build from
  # minutes to seconds -- the libraries are what's wanted, not the
  # toolkit.
  #
  # --openssldir=/private/etc/ssl matters more than it looks: it is
  # compiled into the binary as where to find CA certificates, and macOS
  # ships a real bundle at /private/etc/ssl/cert.pem. Point it anywhere
  # else and certificate verification fails on the user's machine.
  ( cd "$src" && \
    ./Configure "$target" no-shared no-tests no-docs no-apps \
      --prefix="$deps" --openssldir=/private/etc/ssl >/dev/null && \
    make -j"$(sysctl -n hw.ncpu)" >/dev/null && \
    make install_sw >/dev/null )
}
