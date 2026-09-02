# btop -- a resource monitor with a full-colour terminal interface
#
# Class 3 (convenience): btop has one Homebrew dependency (lowdown, for
# the man page) and no runtime tree to escape, so this isn't a rescue.
# It's here because it's a good tool, and because it's the one package
# that isn't a single file -- btop ships 41 colour themes, which is what
# the manifest's `data` kind exists for.
#
# btop finds those themes relative to its own binary, at
# ../share/btop/themes (src/btop.cpp:932), falling back to /usr/local
# and /usr. That first path is exactly the layout install.sh produces
# under any prefix, so a ~/.local/bin install finds its themes with no
# compiled-in path and no environment variable. Worth knowing before
# changing where `data` files land.
#
# Built with the upstream Makefile rather than CMake: it wants CMake
# 3.25+, and pinning a CMake version for one recipe is a cost this
# doesn't need to pay -- the Makefile needs nothing but clang++.

UNFLAB_NAME=btop
UNFLAB_VERSION=1.4.7
UNFLAB_HOMEPAGE=https://github.com/aristocratos/btop
UNFLAB_LICENSE=Apache-2.0
UNFLAB_SOURCE=https://github.com/aristocratos/btop/archive/refs/tags/v1.4.7.tar.gz
UNFLAB_CHECK=github:aristocratos/btop
UNFLAB_SHA256=933de2e4d1b2211a638be463eb6e8616891bfba73aef5d38060bd8319baeefc6
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes no checksum for it'
UNFLAB_TOOLCHAIN="c++ make"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=btop

unflab_build() {
  # btop is C++23 and wants a recent libc++; Xcode's clang++ provides
  # both. The Makefile detects platform and arch from `uname` and
  # `clang++ -dumpmachine` on its own, and GPU support is gated to
  # Linux, so macOS needs no extra flags.
  #
  # VERBOSE=true makes the compile lines visible in CI logs, which is
  # worth having when a C++23 build breaks on a toolchain bump.
  make VERBOSE=true
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/themes"
  install -m 755 bin/btop "$STAGE_DIR/bin/btop"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # The themes btop reads at run time. Not config: the user doesn't edit
  # these, and a --purge shouldn't be needed to remove them.
  for t in themes/*.theme; do
    install -m 644 "$t" "$STAGE_DIR/themes/$(basename "$t")"
  done

  # No man page: upstream ships manpage.md and generates the roff with
  # lowdown at build time. Pulling in a Markdown-to-roff converter for
  # one page would be exactly the dependency bloat this project exists
  # to avoid, and `btop --help` covers the flags.

  # 41 theme rows would be a lot to hand-maintain and keep in step with
  # upstream, so the manifest is generated from what was just staged.
  {
    printf 'bin\t755\tbin/btop\tbtop\t-\n'
    for t in "$STAGE_DIR"/themes/*.theme; do
      n="$(basename "$t")"
      printf 'data\t644\tthemes/%s\tthemes/%s\t-\n' "$n" "$n"
    done
    printf 'doc\t644\tREADME.md\tREADME.md\t-\n'
    printf 'doc\t644\tLICENSE\tLICENSE\t-\n'
  } > "$STAGE_DIR/.unflab/manifest.tsv"
}
