# coreutils -- the GNU core utilities, one package each
#
# Class 2 (suite extraction), at the largest scale here: `brew install
# coreutils` builds and installs all 105 as a single unit. This builds
# the same source and emits 105 independent packages, so you can have
# just gtimeout, or just gshuf, without the other 104.

UNFLAB_NAME=coreutils
UNFLAB_VERSION=9.11
UNFLAB_HOMEPAGE=https://www.gnu.org/software/coreutils/
UNFLAB_LICENSE=GPL-3.0-or-later
UNFLAB_SOURCE=https://ftp.gnu.org/gnu/coreutils/coreutils-9.11.tar.xz
UNFLAB_SHA256=394024eda0a5955217ceda9cd1201e65dc8fa3aa29c2951135a49521d57c3cc3
UNFLAB_TOOLCHAIN="c autotools make"
UNFLAB_CLASS=2

# All 105 utilities coreutils 9.11 actually builds on macOS. chcon and
# runcon are excluded because they're gated on SELinux in coreutils' own
# configure.ac -- under --without-selinux `make src/chcon` has no target
# at all, so they aren't a "builds but does nothing" case.
UNFLAB_PACKAGES="$(tr '\n' ' ' < "$RECIPE_DIR/utils.txt")"

unflab_build() {
  # These --without/--disable flags exist to stop configure
  # opportunistically linking whatever happens to be installed on the
  # build machine. A sibling project shipped a cksum that dynamically
  # linked Homebrew's openssl@3 because the Intel runner had it on the
  # default search path and the arm64 one didn't -- the same class of
  # problem as libgmp below, and exactly what the otool gate exists to
  # catch. Forcing them off is more reliable than hoping the builder is
  # clean.
  #
  # --disable-nls: coreutils' .po catalogues are whole-project, not
  # per-utility, so a translated timeout would mean shipping ~45
  # languages' catalogues for the entire suite in every one of 105
  # packages.
  ./configure \
    --disable-nls \
    --disable-year2038 \
    --without-libgmp \
    --without-selinux \
    --disable-libcap \
    --disable-xattr \
    --with-openssl=no \
    >/dev/null

  # `src/<name>` targets don't declare BUILT_SOURCES (configmake.h,
  # version.h and friends) as prerequisites -- only the top-level `all`
  # target does. Building single program targets on a fresh tree fails on
  # a missing configmake.h without generating those first. There's no
  # target literally named $(BUILT_SOURCES), so include the real Makefile
  # into a throwaway one that can print the expanded variable, then pass
  # the result back as targets.
  local print_mk built_sources
  print_mk="$(mktemp)"
  cat > "$print_mk" <<'MAKEFRAG'
include Makefile
print-%:
	@echo '$($*)'
MAKEFRAG
  built_sources="$(make -f "$print_mk" print-BUILT_SOURCES)"
  rm -f "$print_mk"
  make $built_sources

  for u in $UNFLAB_PACKAGES; do
    # coreutils builds `install` as the target `ginstall`, so its own
    # local.mk doesn't collide with make's built-in `install` target.
    # `make src/install` isn't a real rule: it falls through to make's
    # implicit C-compile rule and fails obscurely on config.h.
    local target="$u"
    [ "$u" = "install" ] && target="ginstall"
    make "src/$target"
  done
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1" "$STAGE_DIR/.unflab"

  local target="$PKG"
  [ "$PKG" = "install" ] && target="ginstall"

  # Ship under the g-prefixed name, matching the convention Homebrew's
  # coreutils established: gls, gtimeout and so on mean the same thing
  # everywhere. Whether the *plain* name also gets claimed is decided at
  # install time, on the user's machine -- see the manifest below.
  install -m 755 "src/$target" "$STAGE_DIR/bin/g$PKG"
  [ -f "man/$PKG.1" ] && install -m 644 "man/$PKG.1" "$STAGE_DIR/share/man/man1/g$PKG.1"
  install -m 644 COPYING "$STAGE_DIR/LICENSE"

  # 105 hand-written READMEs would be 105 things to drift, so generate
  # each from the utility's own --help summary.
  {
    echo "# g$PKG (unflab build)"
    echo ""
    echo "GNU coreutils' \`$PKG\`, packaged on its own."
    echo ""
    if [ -x "src/$target" ]; then
      echo '```'
      "./src/$target" --help 2>/dev/null | head -3 || true
      echo '```'
      echo ""
    fi
    cat "$RECIPE_DIR/README-common.md"
  } > "$STAGE_DIR/README.md"

  # Generated per package: the g-name is always installed; the plain
  # name is offered as the alias, and install.sh claims it only if
  # nothing on that machine already answers to it. That check has to
  # happen on the target machine, not here -- which of these names is
  # free differs between Macs, and `timeout`, `shuf`, `nproc` and the
  # like are free on a stock macOS. Shipping only `gtimeout` would
  # recreate the exact problem that motivated this packaging in the
  # first place: tooling calling a bare `timeout` and not finding it.
  {
    printf 'bin\t755\tbin/g%s\tg%s\t%s\n' "$PKG" "$PKG" "$PKG"
    [ -f "man/$PKG.1" ] && printf 'man1\t644\tshare/man/man1/g%s.1\tg%s.1\t%s.1\n' "$PKG" "$PKG" "$PKG"
    printf 'doc\t644\tREADME.md\tREADME.md\t-\n'
    printf 'doc\t644\tLICENSE\tLICENSE\t-\n'
  } > "$STAGE_DIR/.unflab/manifest.tsv"
}
