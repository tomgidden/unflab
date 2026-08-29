# jq -- command-line JSON processor
#
# Class 3 (convenience): jq's only Homebrew dependency is oniguruma, and
# upstream publishes prebuilt macOS binaries, so this isn't rescuing
# anyone. It's here because jq belongs in any collection of command-line
# tools, and because it should install the same way as everything else.

UNFLAB_NAME=jq
UNFLAB_VERSION=1.8.1
UNFLAB_HOMEPAGE=https://jqlang.github.io/jq/
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-1.8.1.tar.gz
UNFLAB_SHA256=2be64e7129cecb11d5906290eba10af694fb9e3e7f9fc208a311dc33ca837eb0
UNFLAB_TOOLCHAIN="c autotools make"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=jq

unflab_build() {
  # --disable-shared is doing real work here, not tidying. Without it
  # libtool builds libjq and libonig as dylibs, links the binary against
  # them by their *install* paths, and leaves ./jq as a wrapper script
  # that sets a library path before exec'ing .libs/jq. The real binary
  # then carries /usr/local/lib/libjq.1.dylib and libonig.5.dylib --
  # paths that won't exist on anyone's machine. The gate catches it, but
  # the fix is to link statically in the first place.
  #
  # --with-oniguruma=builtin uses the copy vendored in jq's own tree, so
  # regex support is kept without depending on Homebrew's oniguruma.
  ./configure \
    --with-oniguruma=builtin \
    --disable-shared \
    --enable-static \
    --disable-maintainer-mode \
    >/dev/null
  make
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 jq "$STAGE_DIR/bin/jq"

  # jq.1 is generated from jq.1.prebuilt when the doc toolchain is
  # absent; either way one of them is present in a release tarball.
  if [ -f jq.1 ]; then
    install -m 644 jq.1 "$STAGE_DIR/share/man/man1/jq.1"
  else
    install -m 644 jq.1.prebuilt "$STAGE_DIR/share/man/man1/jq.1"
  fi

  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
