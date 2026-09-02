# inetutils -- GNU ftp and telnet clients
#
# Class 2 (suite extraction), and the clearest case in the project.
# macOS removed /usr/bin/ftp and /usr/bin/telnet in High Sierra, so
# people genuinely need these. `brew install inetutils` supplies them by
# installing about 23 executables -- ping, ping6, traceroute, ifconfig,
# hostname, logger, rcp, rexec, rlogin, rsh, talk, tftp, whois and the
# rest -- several of which shadow tools macOS already provides.
#
# This builds the same source configured for exactly two clients, and
# ships them as two independent packages: `ftp` and `telnet`, separately
# installable. Nothing else is compiled at all.
#
# Deliberately NOT packaged: ping and traceroute need raw sockets, so
# they'd want a setuid install this project has no business performing;
# ifconfig and hostname would shadow working macOS equivalents.

UNFLAB_NAME=inetutils
UNFLAB_VERSION=2.8
UNFLAB_HOMEPAGE=https://www.gnu.org/software/inetutils/
UNFLAB_LICENSE=GPL-3.0-or-later
UNFLAB_SOURCE=https://ftp.gnu.org/gnu/inetutils/inetutils-2.8.tar.gz
UNFLAB_CHECK=gnu:inetutils
UNFLAB_SHA256=57b3cf4f77555992881e5ba2a09a63b05aa2c56342a60ed4305b5f45938390b5
UNFLAB_ATTEST=gnupg:https://ftp.gnu.org/gnu/gnu-keyring.gpg
UNFLAB_TOOLCHAIN="c autotools make"
UNFLAB_CLASS=2
UNFLAB_PACKAGES="ftp telnet"

unflab_build() {
  # --without-idn is what removes the dependency Homebrew carries:
  # libidn2, which itself pulls libunistring and gettext. An FTP client
  # doesn't need internationalised domain names badly enough to justify
  # three libraries; without it, ftp links only libedit and libSystem,
  # both already in /usr/lib.
  #
  # --disable-nls drops the translation catalogues, same trade as pv.
  #
  # Everything else is switched off one flag at a time rather than with
  # --disable-clients, because that would take ftp and telnet with it.
  # The result compiles two binaries out of a suite of twenty-odd.
  ./configure \
    --disable-servers \
    --without-idn \
    --disable-nls \
    --disable-dnsdomainname \
    --disable-hostname \
    --disable-ping \
    --disable-ping6 \
    --disable-rcp \
    --disable-rexec \
    --disable-rlogin \
    --disable-rsh \
    --disable-logger \
    --disable-talk \
    --disable-tftp \
    --disable-whois \
    --disable-ifconfig \
    --disable-traceroute \
    >/dev/null
  make
}

unflab_stage() {
  # Runs once per entry in UNFLAB_PACKAGES, with $PKG set to ftp or
  # telnet. Both come from the one configured tree built above.
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 "$PKG/$PKG" "$STAGE_DIR/bin/$PKG"

  # Man pages ship pre-generated in the release tarball, so help2man
  # isn't needed at build time.
  install -m 644 "man/$PKG.1" "$STAGE_DIR/share/man/man1/$PKG.1"
  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README-$PKG.md" "$STAGE_DIR/README.md"
}
