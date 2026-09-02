# pv -- monitor the progress of data through a pipe
#
# Class 1 (dependency escape), mildly: Homebrew's pv depends on gettext
# for translated messages. --disable-nls drops that entirely, and pv's
# only remaining dependency is ncurses, which macOS itself provides in
# /usr/lib. The result needs nothing that isn't already on the machine.

UNFLAB_NAME=pv
UNFLAB_VERSION=1.9.31
UNFLAB_HOMEPAGE=https://www.ivarch.com/programs/pv.shtml
UNFLAB_LICENSE=GPL-3.0-or-later
UNFLAB_SOURCE=https://www.ivarch.com/programs/sources/pv-1.9.31.tar.gz
UNFLAB_CHECK=html:https://www.ivarch.com/programs/pv.shtml:pv
UNFLAB_SHA256=a35e92ec4ac0e8f380e8e840088167ae01014bfa008a3a9d6506b848079daedf
UNFLAB_ATTEST='none:upstream download page publishes no checksum or signature'
UNFLAB_TOOLCHAIN="c autotools make"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=pv

unflab_build() {
  # --disable-nls: pv's translation catalogues are the only reason it
  # needs gettext, and shipping ~20 languages' .mo files with a pipe
  # progress meter isn't the trade this project is making. Same reasoning
  # (and the same flag) as the coreutils builds.
  #
  # ncurses is left alone deliberately: pv links macOS's own
  # /usr/lib/libncurses, which satisfies the gate for free. There's
  # nothing to statically link.
  ./configure --disable-nls >/dev/null
  make
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 pv "$STAGE_DIR/bin/pv"
  install -m 644 docs/pv.1 "$STAGE_DIR/share/man/man1/pv.1"
  install -m 644 docs/COPYING "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
