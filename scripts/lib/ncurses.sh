# unflab_static_ncurses -- build ncurses (widechar) as a static library.
#
# macOS does ship an ncurses in /usr/lib, and a recipe that only needs
# plain curses should just use it -- htop does, and links against
# /usr/lib/libncurses.5.4.dylib quite happily.
#
# What the system copy cannot do is wide characters. There is no
# libncursesw among the SDK's stubs, and while the dylib does export
# some wide symbols, the SDK's curses.h doesn't declare them: a
# configure script probing for wget_wch finds nothing and quietly
# settles for a non-UTF-8 build. That is why htop ships
# --disable-unicode.
#
# This builds ncurses 6.6 with --enable-widec and links it in, so a
# consumer gets modern, wide-character curses with no shared library
# anywhere -- the binary ends up depending on libSystem alone.
#
# Sets, on return:
#
#   UNFLAB_NCURSES_PREFIX   directory holding include/ncursesw and
#                           lib/libncursesw.a (and lib/pkgconfig, which
#                           consumers using pkg-config will need on
#                           PKG_CONFIG_PATH)
#
# Cached per recipe, like the other dependency helpers.

UNFLAB_NCURSES_VERSION=6.6
UNFLAB_NCURSES_SOURCE="https://ftp.gnu.org/gnu/ncurses/ncurses-6.6.tar.gz"
UNFLAB_NCURSES_SHA256=355b4cbbed880b0381a04c46617b7656e362585d52e9cf84a67e2009b749ff11

unflab_static_ncurses() {
  local deps="$BUILD_DIR/../deps"
  local src="$BUILD_DIR/../ncurses-$UNFLAB_NCURSES_VERSION"
  UNFLAB_NCURSES_PREFIX="$deps"

  [ -f "$deps/lib/libncursesw.a" ] && return 0

  echo "==> Building ncurses $UNFLAB_NCURSES_VERSION (static, widechar)"
  mkdir -p "$deps"

  local tarball="$BUILD_DIR/../ncurses.tar.gz"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$UNFLAB_NCURSES_SOURCE"

  local actual
  actual="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$actual" != "$UNFLAB_NCURSES_SHA256" ]; then
    echo "ncurses.sh: checksum mismatch" >&2
    echo "  expected: $UNFLAB_NCURSES_SHA256" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi

  rm -rf "$src"
  tar xzf "$tarball" -C "$BUILD_DIR/.."

  # The terminal descriptions come from macOS, not from us.
  #
  # --with-default-terminfo-dir is the setting that matters most here,
  # and getting it wrong is silent: it bakes a path into the library,
  # and if that path is the build tree then every terminal fails at run
  # time with "Error opening terminal" on the user's machine. macOS
  # ships a full terminfo database at /usr/share/terminfo (~2000
  # entries), which is a system path in the same category as /usr/lib,
  # so pointing at it is both correct and consistent with the gate.
  #
  # --disable-db-install then means we install no database of our own.
  # Compiling one would need `tic`, which is a problem all by itself
  # (see below), and shipping ~4000 files to duplicate what the OS
  # already has would defeat the point of a single binary.
  #
  # --without-shared is what makes this safe to link: no dylib is
  # produced at all, so there is nothing a consumer's linker could
  # prefer over the archive and nothing that could become a runtime
  # dependency. --with-normal asks for the plain static libraries.
  #
  # The --without-* flags drop parts nothing here uses: Ada and C++
  # bindings, the tools (tic, infocmp, ...), the test programs and the
  # man pages. --enable-pc-files generates ncursesw.pc so consumers can
  # find this through pkg-config, which is how nano's configure locates
  # it -- and finding it that way is what makes nano detect wide
  # character support properly rather than falling back.
  ( cd "$src" && \
    ./configure --prefix="$deps" \
      --with-default-terminfo-dir=/usr/share/terminfo \
      --with-terminfo-dirs=/usr/share/terminfo:/usr/lib/terminfo \
      --disable-db-install \
      --enable-widec \
      --with-normal \
      --without-shared \
      --without-debug \
      --without-ada \
      --without-cxx-binding \
      --without-manpages \
      --without-progs \
      --without-tests \
      --enable-pc-files \
      --with-pkg-config-libdir="$deps/lib/pkgconfig" \
      --with-fallbacks=xterm,xterm-256color,vt100,ansi,screen,tmux-256color \
      >/dev/null

    # Generate fallback.c ourselves, because the build's own rule for it
    # cannot work on macOS.
    #
    # Fallbacks are terminal descriptions compiled into the library, used
    # when the terminfo database can't be read. They are not optional
    # here: with an empty fallback list the build still produces an
    # archive, but linking it fails with an undefined _nc_fallback2.
    #
    # The normal rule builds them by running `tic` over upstream's
    # terminfo.src, and that fails on macOS for two separate reasons:
    #
    #   1. /usr/bin/tic is ncurses 6.0, from 2015. Modern terminfo.src
    #      uses capabilities it doesn't understand (setal, kitty+setal),
    #      and it gives up partway through -- leaving a zero-byte entry
    #      rather than an obvious error.
    #
    #   2. A stock Mac's filesystem is case-insensitive, so a handful of
    #      entries collide with their uppercase variants. (Only three,
    #      all 1970s HP terminals, so this is the lesser problem -- but
    #      it means even a current tic can't compile the file here
    #      without a case-sensitive volume to write to.)
    #
    # Neither matters, because we don't want a compiled database anyway:
    # we want six descriptions read out of the one macOS already has.
    # MKfallback.sh will do exactly that if it is pointed at
    # /usr/share/terminfo and stopped from trying to build its own --
    # `infocmp` is a system tool and is all that is then needed.
    #
    # The patch is written against what the script does rather than
    # against exact line text, since 6.5 and 6.6 word these differently.
    sed -E \
      -e 's|^([[:space:]]*)tmp_info=`pwd`/tmp_info|\1tmp_info=/usr/share/terminfo|' \
      -e 's|^([[:space:]]*)TERMINFO=`pwd`/\$tmp_info|\1TERMINFO=/usr/share/terminfo|' \
      -e 's|^([[:space:]]*)rm -rf "\$tmp_info"|\1:|' \
      -e 's|^([[:space:]]*)mkdir -p "\$tmp_info"|\1:|' \
      -e 's|^([[:space:]]*)"\$tic_path".*-x "\$terminfo_src" >&2|\1:|' \
      ncurses/tinfo/MKfallback.sh > ncurses/MKfallback-unflab.sh

    ( cd ncurses && TERMINFO_DIRS=/usr/share/terminfo \
      sh -e ./MKfallback-unflab.sh /usr/share/terminfo "" tic infocmp \
        xterm xterm-256color vt100 ansi screen tmux-256color \
        > fallback.c 2>/dev/null )

    # An empty or entry-less fallback.c links to a confusing error much
    # later, so fail here where the cause is obvious.
    if ! grep -q '_nc_fallback2' "ncurses/fallback.c"; then
      echo "ncurses.sh: fallback.c has no entries -- did MKfallback.sh change?" >&2
      exit 1
    fi

    make -j"$(sysctl -n hw.ncpu)" >/dev/null && \
    make install >/dev/null )
}
