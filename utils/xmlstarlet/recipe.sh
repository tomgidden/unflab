# xmlstarlet -- query and edit XML from the shell
#
# Class 3 (convenience): Homebrew's xmlstarlet has no dependencies
# either, because it links the libxml2/libxslt macOS already ships. What
# this package gives you is the binary without needing a package manager
# to get it -- and a build that still compiles, which the 2014 sources no
# longer do with a modern compiler out of the box (see unflab_build).

UNFLAB_NAME=xmlstarlet
UNFLAB_VERSION=1.6.1
UNFLAB_HOMEPAGE=https://xmlstar.sourceforge.net/
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://downloads.sourceforge.net/project/xmlstar/xmlstarlet/1.6.1/xmlstarlet-1.6.1.tar.gz
UNFLAB_CHECK=html:https://sourceforge.net/projects/xmlstar/rss?path=/xmlstarlet:xmlstarlet
UNFLAB_SHA256=15d838c4f3375332fd95554619179b69e4ec91418a3a5296e7c631b7ed19e7ca
UNFLAB_ATTEST='none:SourceForge release publishes no checksum or signature'
UNFLAB_TOOLCHAIN="c autotools make"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=xmlstarlet

unflab_build() {
  # libxml2, libxslt and libexslt all ship with macOS in /usr/lib, with
  # headers in the SDK, so there is nothing to statically link here --
  # the binary satisfies the gate by using the system's own copies.
  local sdk
  sdk="$(xcrun --show-sdk-path)"

  # xmlstarlet 1.6.1 is from 2014 and upstream has been dormant since.
  # Two flags keep it compiling against a current toolchain:
  #
  # -Wno-incompatible-function-pointer-types: libxml2 later added `const`
  #   to xmlHashScanner's name parameter. xmlstarlet's callback still has
  #   the unqualified signature. Clang 15+ made this mismatch an error
  #   rather than a warning. The qualifier doesn't change the ABI, so
  #   this is safe -- and preferable to patching upstream source we'd
  #   then have to carry.
  #
  # -Wno-implicit-function-declaration: same era, same cause; C99
  #   implicit declarations that newer clang rejects by default.
  ./configure \
    CFLAGS="-O2 -I$sdk/usr/include/libxml2 -Wno-incompatible-function-pointer-types -Wno-implicit-function-declaration" \
    >/dev/null
  make
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"

  # Upstream builds the binary as `xml`. That's a very generic name to
  # put on someone's PATH, so the package installs it as `xmlstarlet`
  # (the name people look for, and what the man page is called) and
  # offers `xml` only as the unprefixed alias, which install.sh will
  # claim solely if nothing else on the machine answers to it.
  install -m 755 xml "$STAGE_DIR/bin/xmlstarlet"
  install -m 644 doc/xmlstarlet.1 "$STAGE_DIR/share/man/man1/xmlstarlet.1"
  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
