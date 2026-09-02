# socat -- multipurpose relay for bidirectional data transfer
#
# Class 1 (dependency escape). `brew install socat` pulls openssl@3,
# which then wants keeping updated for its own sake. This builds OpenSSL
# from source and links it statically, so what gets installed is one
# binary that depends on nothing macOS doesn't already ship -- while
# keeping the OPENSSL: address types, which are most of the reason to
# reach for socat rather than nc.

UNFLAB_NAME=socat
UNFLAB_VERSION=1.8.1.3
UNFLAB_HOMEPAGE=http://www.dest-unreach.org/socat/
UNFLAB_LICENSE=GPL-2.0-only
UNFLAB_SOURCE=http://www.dest-unreach.org/socat/download/socat-1.8.1.3.tar.gz
UNFLAB_CHECK=html:http://www.dest-unreach.org/socat/download/:socat
UNFLAB_SHA256=06602ffd591e98c75b3dc1d66f0f19136cc666b0b2d95caad987d6ab2cb28097
UNFLAB_ATTEST='none:plain-HTTP download with no published checksum or signature'
UNFLAB_TOOLCHAIN="c autotools make"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=socat

# Upstream distributes over plain HTTP with no TLS and no signature this
# build checks, so the SHA-256 pin is doing real work here rather than
# merely guarding against a corrupted download.

# shellcheck source=../../scripts/lib/openssl.sh
source "$ROOT_DIR/scripts/lib/openssl.sh"

unflab_build() {
  unflab_static_openssl

  # --disable-readline drops the one dependency beyond OpenSSL that
  # configure would otherwise pick up. It only affects the READLINE:
  # address type -- an interactive line-editing wrapper -- and linking
  # a readline for it would undo the point of the exercise. Everything
  # else socat does is unaffected.
  #
  # --disable-libwrap drops tcp_wrappers/hosts.allow support, which
  # macOS has no system library for anyway.
  #
  # The remaining address types are all built: TCP, UDP, UNIX, PTY,
  # EXEC, OPENSSL and the rest.
  ./configure \
    --disable-readline \
    --disable-libwrap \
    CPPFLAGS="-I$UNFLAB_SSL_PREFIX/include" \
    LDFLAGS="-L$UNFLAB_SSL_PREFIX/lib" \
    >/dev/null
  make
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"

  # Upstream builds three binaries. socat is the tool; filan and procan
  # are diagnostic helpers that report on file descriptors and the
  # process environment, and socat's own man page refers to both. They
  # are small and genuinely part of using socat, so they ship together
  # rather than as separate packages -- the zip/unzip shape.
  install -m 755 socat "$STAGE_DIR/bin/socat"
  install -m 755 filan "$STAGE_DIR/bin/filan"
  install -m 755 procan "$STAGE_DIR/bin/procan"

  install -m 644 doc/socat.1 "$STAGE_DIR/share/man/man1/socat.1"
  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
