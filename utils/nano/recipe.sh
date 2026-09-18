# nano -- a small and friendly text editor
#
# Class 1 (dependency escape), and a class of its own besides.
#
# `brew install nano` pulls ncurses and gettext. Both drop out here:
# gettext because --disable-nls removes the need for it, and ncurses
# because it is compiled from source and linked statically, leaving a
# binary that depends on libSystem alone.
#
# The other reason this is worth packaging is what macOS calls nano.
# /usr/bin/nano is a symlink to /usr/bin/pico -- UW PICO 5.09, the
# editor nano was written to replace. It is not GNU nano, it does not
# read a nanorc, and it does not understand UTF-8. Anyone who types
# `nano` on a stock Mac gets it without being told.
#
# So this package deliberately shadows that name. See the manifest:
# the binary installs as `gnunano` and the plain `nano` is a forced
# alias, claimed even though something already answers to it. `gnunano`
# follows macOS's own `gnumake` rather than inventing a prefix -- no
# distribution ships a `gnano` or `gnunano`, so there was no existing
# convention to borrow, and matching the one Apple already uses beats
# coining a new one.
#
# UTF-8 is the reason for the static ncurses rather than the system's.
# macOS ships no libncursesw and its curses.h doesn't declare the
# wide-character functions, so nano's configure finds no wide support
# and silently builds a nano that mangles any non-ASCII character. That
# is the same wall htop hit (see utils/htop, --disable-unicode), but an
# editor that corrupts text on save is not worth shipping, so here the
# dependency is built instead. scripts/lib/ncurses.sh explains what
# that involves on macOS.

UNFLAB_NAME=nano
UNFLAB_VERSION=9.2
UNFLAB_HOMEPAGE=https://www.nano-editor.org/
UNFLAB_LICENSE=GPL-3.0-or-later
UNFLAB_SOURCE=https://www.nano-editor.org/dist/v9/nano-9.2.tar.xz
# Checked against ftp.gnu.org rather than nano's own dist/ directory,
# which is split by major version (dist/v9/). A v9 URL would report 9.2
# as current forever once nano 10 shipped -- reporting "up to date"
# rather than failing, which is the worst way to be wrong. The GNU
# mirror is one flat directory covering every release.
UNFLAB_CHECK=gnu:nano
UNFLAB_SHA256=05ecb99247b782e8a5b3a25ed4101dd034b0236902f7449bc9795b717642f7e9
UNFLAB_ATTEST=gnupg:https://ftp.gnu.org/gnu/gnu-keyring.gpg
UNFLAB_TOOLCHAIN="c make pkg-config"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=nano

# Upstream signs with .asc rather than the .sig the attest helper
# assumes. The signing key (168E6F4297BFD7A79AFD4496514BBE2EB8E1961F)
# is in the GNU keyring, so the standard anchor verifies it.
UNFLAB_SIG_URL="$UNFLAB_SOURCE.asc"

# shellcheck source=../../scripts/lib/ncurses.sh
source "$ROOT_DIR/scripts/lib/ncurses.sh"

unflab_build() {
  unflab_static_ncurses

  local deps="$BUILD_DIR/../deps"

  # nano finds curses through pkg-config first, and that is the path
  # worth taking: it is the only one of its several probes that detects
  # wide-character support correctly here. The fallbacks all end up
  # testing -lncursesw (which doesn't exist on macOS) or -lncurses
  # (which exists but reports no wide support), and the second of those
  # succeeds -- quietly producing a non-UTF-8 nano.
  #
  # pkg-config reads PKG_CONFIG_PATH rather than anything on the command
  # line, so putting our own prefix first is what makes the static
  # library the one that gets found rather than a Homebrew copy that
  # happens to be on the build machine.
  export PKG_CONFIG_PATH="$deps/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  # --disable-nls drops gettext, one of the two Homebrew dependencies.
  # It costs the translated interface; the editor is unaffected, and
  # every message it prints is in English either way on a machine with
  # no message catalogues installed.
  #
  # --disable-libmagic likewise: libmagic is only used to guess a
  # syntax for a file whose name gives nothing away, and it is not a
  # system library on macOS. Without it nano falls back to matching on
  # filename and first line, which is what the 39 shipped syntaxes key
  # off anyway.
  #
  # --enable-utf8 is explicit rather than left to `auto` on purpose: at
  # `auto`, insufficient wide-character support is a warning and the
  # build continues, which is exactly the silent failure this recipe
  # exists to avoid. Asking for it outright turns that into an error.
  #
  # --datadir is where the syntax files land, and it is what configure
  # substitutes into doc/sample.nanorc's `include` lines. The real path
  # is only known on the user's machine (~/.local/share/nano by
  # default, different under --prefix), so a placeholder goes in here
  # and unflab_stage rewrites it.
  #
  # It has to be an absolute path: configure rejects anything else
  # outright. The leading slash is stripped back out in the stage.
  ./configure \
    --disable-nls \
    --disable-libmagic \
    --enable-utf8 \
    --datadir='/@UNFLAB_DATADIR@' \
    >/dev/null

  make
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" \
             "$STAGE_DIR/share/man/man1" \
             "$STAGE_DIR/share/man/man5" \
             "$STAGE_DIR/syntax"

  # Installed as gnunano; the plain `nano` is claimed at install time by
  # the forced alias in the manifest below.
  install -m 755 src/nano "$STAGE_DIR/bin/gnunano"

  # rnano -- restricted nano, which refuses to open any file but the one
  # named on the command line -- is not shipped. It is a wrapper for
  # giving an untrusted user an editor and nothing else, which is a
  # multi-user-server concern rather than a desktop one, and it would
  # need its own name decision here for no one's benefit.

  install -m 644 doc/nano.1   "$STAGE_DIR/share/man/man1/gnunano.1"
  install -m 644 doc/nanorc.5 "$STAGE_DIR/share/man/man5/nanorc.5"

  install -m 644 COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # The 39 syntax definitions. They are inert until a nanorc includes
  # them, which is what the post-install note is for.
  install -m 644 syntax/*.nanorc "$STAGE_DIR/syntax/"

  # sample.nanorc is generated by configure from sample.nanorc.in, with
  # @PKGDATADIR@ replaced by the configured --datadir. That path has to
  # be the one on the user's machine, and at build time we don't know
  # it: the default is ~/.local/share/nano but --prefix changes it.
  #
  # So --datadir was set to a placeholder, and the installer is what
  # resolves it. The substitution happens in the post-install note,
  # which install.sh expands -- so what the note prints is a working
  # `include` line for wherever the package actually landed, rather
  # than the /usr/local path upstream's configure would have baked in.
  #
  # Checked rather than assumed: if configure ever stops templating
  # this file, the placeholder would ship verbatim into a file users
  # copy into their nanorc, and every include in it would be broken.
  grep -q '/@UNFLAB_DATADIR@/nano' doc/sample.nanorc || {
    echo "nano: doc/sample.nanorc has no /@UNFLAB_DATADIR@/nano -- did --datadir stop being templated?" >&2
    return 1
  }

  # Every line the placeholder appears in is a commented-out example, so
  # it is rewritten to say where the files are in prose rather than
  # pretending to be a path. install.sh substitutes variables when it
  # prints the post-install note but not inside an installed file, and
  # a literal $DATADIR sitting in a nanorc would be read by nano as a
  # directory of that name.
  #
  # Writing this build's own path in would be the worse mistake: it
  # would look correct and be silently wrong for any --prefix. The
  # post-install note prints the real include line, expanded, which is
  # the copy a user actually pastes.
  # configure appends the package name, so the placeholder comes out as
  # /@UNFLAB_DATADIR@/nano -- both parts are replaced together.
  sed 's|/@UNFLAB_DATADIR@/nano|<this package'"'"'s share/nano directory>|g' \
    doc/sample.nanorc > "$STAGE_DIR/syntax/sample.nanorc"
  chmod 644 "$STAGE_DIR/syntax/sample.nanorc"

  # The manifest is generated because the syntax list is upstream's, not
  # ours: a release that adds or removes a language changes it, and a
  # file named here but missing from the package is a fatal error on the
  # user's machine rather than in CI.
  #
  # The `!nano` alias on the binary is the forced one -- claimed even
  # though /usr/bin/nano always exists. The man page is listed as
  # `nano.1` against gnunano.1 for the same reason: someone who types
  # `nano` should get the manual for the nano they are running.
  {
    printf 'bin\t755\tbin/gnunano\tgnunano\t!nano\n'
    printf 'man1\t644\tshare/man/man1/gnunano.1\tgnunano.1\t!nano.1\n'
    printf 'man5\t644\tshare/man/man5/nanorc.5\tnanorc.5\t-\n'
    printf 'doc\t644\tREADME.md\tREADME.md\t-\n'
    printf 'doc\t644\tLICENSE\tLICENSE\t-\n'
    for f in "$STAGE_DIR/syntax"/*.nanorc; do
      [ -f "$f" ] || continue
      printf 'data\t644\tsyntax/%s\t%s\t-\n' "$(basename "$f")" "$(basename "$f")"
    done
  } > "$STAGE_DIR/.unflab/manifest.tsv"

  install -m 644 "$RECIPE_DIR/post-install.txt" "$STAGE_DIR/.unflab/post-install.txt"
}
