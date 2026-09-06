# subversion -- Apache Subversion version control system
#
# Class 1 (dependency escape), and the largest chain in the collection.
# `brew install subversion` pulls apache-serf, apr, apr-util, lz4,
# utf8proc and gettext -- six formulae for a version control client.
# This builds the ones that matter from source and links them
# statically, so what gets installed depends on nothing but libraries
# macOS already ships.
#
# macOS does carry APR in /usr/lib, but not apr-1-config, which both
# serf and subversion's configure use to find it -- and those .tbd
# stubs are deprecated Apple libraries that may not survive a future
# release. Building APR here costs about a minute and removes the
# question entirely.

UNFLAB_NAME=subversion
UNFLAB_VERSION=1.14.5
UNFLAB_HOMEPAGE=https://subversion.apache.org/
UNFLAB_LICENSE=Apache-2.0
UNFLAB_SOURCE=https://archive.apache.org/dist/subversion/subversion-1.14.5.tar.bz2
UNFLAB_SHA256=e78a29e7766b8b7b354497d08f71a55641abc53675ce1875584781aae35644a1
UNFLAB_ATTEST='gnupg:https://downloads.apache.org/subversion/KEYS'
# Apache signs with .asc, not the .sig that build.sh derives by default.
UNFLAB_SIG_URL="$UNFLAB_SOURCE.asc"
UNFLAB_TOOLCHAIN="c c++ autotools make python3"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=subversion

# shellcheck source=../../scripts/lib/openssl.sh
source "$ROOT_DIR/scripts/lib/openssl.sh"

# Pinned like the primary source, and for the same reason: these are
# fetched at build time and their checksums are the only thing standing
# between a compromised mirror and a shipped binary. All three verified
# against the SHA-256 files Apache publishes beside them.
UNFLAB_APR_VERSION=1.7.6
UNFLAB_APR_SHA256=49030d92d2575da735791b496dc322f3ce5cff9494779ba8cc28c7f46c5deb32
UNFLAB_APU_VERSION=1.6.5
UNFLAB_APU_SHA256=96de1dd6f6a0476d2d2e7964926d8c1ddc3bb0e210e1b1812d3ba5a454a392e2
UNFLAB_SERF_VERSION=1.3.10
UNFLAB_SERF_SHA256=be81ef08baa2516ecda76a77adf7def7bc3227eeb578b9a33b45f7b41dc064e6

# Fetch a pinned dependency tarball and unpack it, refusing on a
# checksum mismatch. Same contract as build.sh applies to the primary
# source -- a dependency is no less part of the shipped binary.
_svn_fetch() {
  local name="$1" url="$2" want="$3" dest="$4"
  local tarball="$dest/$name.tar.bz2"

  [ -d "$dest/$name" ] && return 0
  mkdir -p "$dest"

  echo "==> Fetching $name"
  curl -fsSL --connect-timeout 15 --max-time 300 --retry 2 \
    -o "$tarball" "$url"

  local got
  got="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  if [ "$got" != "$want" ]; then
    echo "subversion recipe: checksum mismatch for $name" >&2
    echo "  expected: $want" >&2
    echo "  actual:   $got" >&2
    exit 1
  fi

  tar xjf "$tarball" -C "$dest"
}

unflab_build() {
  local deps="$BUILD_DIR/../deps"
  local work="$BUILD_DIR/.."
  local jobs; jobs="$(sysctl -n hw.ncpu)"

  unflab_static_openssl

  # --- APR ------------------------------------------------------------
  if [ ! -f "$deps/lib/libapr-1.a" ]; then
    _svn_fetch "apr-$UNFLAB_APR_VERSION" \
      "https://archive.apache.org/dist/apr/apr-$UNFLAB_APR_VERSION.tar.bz2" \
      "$UNFLAB_APR_SHA256" "$work"
    ( cd "$work/apr-$UNFLAB_APR_VERSION" && \
      ./configure --prefix="$deps" --enable-static --disable-shared >/dev/null && \
      make -j"$jobs" >/dev/null && make install >/dev/null )
  fi

  # --- apr-util -------------------------------------------------------
  #
  # --with-expat pointed at the SDK: apr-util's own bundled expat build
  # is broken in 1.6.5 (it references a builtin/lib directory it never
  # creates), and macOS ships expat in /usr/lib regardless.
  #
  # The database and LDAP backends are all disabled. Subversion doesn't
  # use them, and each one enabled is another library that would have to
  # come from somewhere.
  if [ ! -f "$deps/lib/libaprutil-1.a" ]; then
    _svn_fetch "apr-util-$UNFLAB_APU_VERSION" \
      "https://archive.apache.org/dist/apr/apr-util-$UNFLAB_APU_VERSION.tar.bz2" \
      "$UNFLAB_APU_SHA256" "$work"
    ( cd "$work/apr-util-$UNFLAB_APU_VERSION" && \
      ./configure --prefix="$deps" --with-apr="$deps" \
        --with-expat="$(xcrun --show-sdk-path)/usr" \
        --without-crypto --with-dbm=sdbm \
        --without-sqlite3 --without-pgsql --without-mysql \
        --without-odbc --without-ldap >/dev/null && \
      make -j"$jobs" >/dev/null && make install >/dev/null )
  fi

  # --- serf -----------------------------------------------------------
  #
  # serf is what gives subversion http:// and https:// access. Without
  # it svn builds fine and can only reach file:// and svn:// -- which
  # would be a package that looks complete and can't talk to any
  # repository anyone actually hosts.
  #
  # It builds with SCons, which no other recipe needs and which isn't
  # on a stock macOS. Rather than make that a system dependency, it
  # goes in a throwaway venv inside the build tree: SCons is a pure
  # Python wheel, so this installs nothing outside build/ and leaves
  # nothing behind.
  if [ ! -f "$deps/lib/libserf-1.a" ]; then
    _svn_fetch "serf-$UNFLAB_SERF_VERSION" \
      "https://archive.apache.org/dist/serf/serf-$UNFLAB_SERF_VERSION.tar.bz2" \
      "$UNFLAB_SERF_SHA256" "$work"

    if [ ! -x "$work/sconsenv/bin/scons" ]; then
      echo "==> Installing SCons (build-local)"
      python3 -m venv "$work/sconsenv" >/dev/null
      "$work/sconsenv/bin/pip" install --quiet scons >/dev/null
    fi

    ( cd "$work/serf-$UNFLAB_SERF_VERSION" && \
      "$work/sconsenv/bin/scons" install \
        PREFIX="$deps" \
        APR="$deps/bin/apr-1-config" \
        APU="$deps/bin/apu-1-config" \
        OPENSSL="$UNFLAB_SSL_PREFIX" >/dev/null )

    # serf builds both a static archive and a dylib, and libtool
    # prefers the dylib -- which would put a build-tree path into every
    # shipped binary and fail the gate. Removing the dylibs is what
    # makes the static archive the only option.
    rm -f "$deps"/lib/libserf-1*.dylib
  fi

  # --- subversion -----------------------------------------------------
  #
  # lz4 and utf8proc are bundled by upstream, so `internal` drops two of
  # Homebrew's six dependencies outright. --disable-nls drops gettext.
  # The bindings (swig, ctypesgen, apxs) are all build-time toolchains
  # for language bindings this package doesn't ship.
  ./configure \
    --prefix="$deps" \
    --with-apr="$deps/bin/apr-1-config" \
    --with-apr-util="$deps/bin/apu-1-config" \
    --with-serf="$deps" \
    --with-lz4=internal \
    --with-utf8proc=internal \
    --without-apxs \
    --without-swig \
    --without-ctypesgen \
    --without-jdk \
    --disable-nls \
    --disable-shared \
    --enable-static \
    >/dev/null

  # LIBS carries OpenSSL explicitly. Subversion's configure records
  # serf's own prefix but not what serf was linked against, so a static
  # serf leaves every OpenSSL symbol undefined at the final link.
  make -j"$jobs" LIBS="-L$UNFLAB_SSL_PREFIX/lib -lssl -lcrypto"

  # --disable-shared above is what keeps subversion's own dozen
  # libraries (libsvn_client, libsvn_wc, ...) inside the executables.
  # Built shared, `make install` links the binaries against dylibs in
  # the build tree, which the gate correctly refuses.
  #
  # install, not just build. libtool leaves a shell wrapper named
  # `svn` in the build tree with the real Mach-O binary hidden in
  # .libs/, and staging the wrapper would ship eleven scripts that
  # reference build-tree paths. `make install` is what makes libtool
  # relink and place the real executables.
  #
  # It also lands the man pages in one predictable place instead of
  # scattered beside their sources.
  make install >/dev/null
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1" \
    "$STAGE_DIR/share/man/man5" "$STAGE_DIR/share/man/man8"

  # Every binary upstream builds. They share one library set, so none
  # of them adds a dependency the others didn't already bring --
  # including svnserve, which is a daemon but not a service: it runs in
  # the foreground, needs no privileges, and is how you serve a
  # repository over svn:// without a web server.
  local prefix="$BUILD_DIR/../deps"
  local b
  for b in svn svnadmin svnbench svndumpfilter svnfsfs svnlook \
           svnmucc svnrdump svnserve svnsync svnversion; do
    install -m 755 "$prefix/bin/$b" "$STAGE_DIR/bin/$b"
  done

  # Not every binary ships a man page upstream (svnbench and svnfsfs
  # don't), so install what exists rather than asserting a fixed list.
  for b in svn svnadmin svndumpfilter svnlook svnmucc svnrdump \
           svnsync svnversion; do
    [ -f "$prefix/share/man/man1/$b.1" ] && \
      install -m 644 "$prefix/share/man/man1/$b.1" \
        "$STAGE_DIR/share/man/man1/$b.1"
  done

  # svnserve is a daemon, so its page is section 8 and its config
  # file's is section 5 -- `man svnserve` only finds them there.
  install -m 644 subversion/svnserve/svnserve.8 \
    "$STAGE_DIR/share/man/man8/svnserve.8"
  install -m 644 subversion/svnserve/svnserve.conf.5 \
    "$STAGE_DIR/share/man/man5/svnserve.conf.5"

  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 NOTICE "$STAGE_DIR/NOTICE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
