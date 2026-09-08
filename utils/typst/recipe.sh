# typst -- a markup-based typesetting system

# Class 3 (convenience): typst has no Homebrew dependencies -- the
# formula's only requirements are pkgconf and rust, both build-time --
# and upstream publishes prebuilt macOS binaries. So nothing is being
# rescued from a dependency tree here.
#
# It's packaged for the same reason doggo and shfmt are: it belongs in
# the same one-line shape as everything else. What makes it worth having
# is the comparison it invites -- the traditional way to typeset a
# document from the command line is a TeX distribution, which is a
# multi-gigabyte install of thousands of files. typst is one binary with
# its fonts compiled into it.
#
# It is also the first Rust recipe in the collection. Rust's default
# linkage on macOS turns out to give exactly what this project wants
# without any coaxing: the standard library is static, and the only
# dylibs are macOS's own. The two crates that could have spoiled that
# don't:
#
#   - TLS, for downloading packages from Typst Universe, goes through
#     native-tls, which on macOS means Security.framework. typst-kit
#     depends on OpenSSL only under cfg(not(any(windows, macos, ...))),
#     so the vendor-openssl feature is a Linux concern and irrelevant
#     here.
#
#   - System font discovery uses fontdb's "fontconfig" feature, which
#     sounds like it would link libfontconfig and drag in freetype and
#     harfbuzz behind it. It doesn't: the feature pulls
#     fontconfig-parser, a pure-Rust reader for fontconfig's XML config
#     files. Nothing links against Homebrew's fontconfig.
#
# The gate proves both of those rather than taking them on trust.

UNFLAB_NAME=typst
UNFLAB_VERSION=0.15.1
UNFLAB_HOMEPAGE=https://typst.app/
UNFLAB_LICENSE=Apache-2.0
UNFLAB_SOURCE=https://github.com/typst/typst/archive/refs/tags/v0.15.1.tar.gz
UNFLAB_CHECK=github:typst/typst
UNFLAB_SHA256=c07909e01a2a6941e52c9b616e48c209c755eed416d62bcf5583c37a4aca01a3
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream release publishes prebuilt binaries but no checksum for the source'
UNFLAB_TOOLCHAIN="rust cargo"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=typst

unflab_build() {
  # Where build.rs is asked to write the man pages and completions. It
  # only generates them when GEN_ARTIFACTS is set, so this is both the
  # switch and the destination.
  export GEN_ARTIFACTS="$BUILD_DIR/artifacts"

  # `typst update` is enabled deliberately, and it is worth being clear
  # about what that means, because it is the one thing in this package
  # that can replace a gated binary with an ungated one.
  #
  # unflab installs packages; it does not manage them. Nothing here
  # checks for updates, so a tool that can update itself when its user
  # asks it to is filling a real gap rather than fighting the project.
  # `typst update` is never automatic: it runs only when typed, keeps a
  # backup, and refuses to downgrade without --force.
  #
  # What it does is download upstream's own prebuilt release asset from
  # GitHub and self-replace with it. That binary is not an unflab build:
  # it has not been through verify.sh, and typst publishes no checksum
  # for it, so the download is trusted on HTTPS alone. Afterwards the
  # installed manifest describes a file that is no longer there, which
  # `install.sh --uninstall` handles (it removes what is at the path)
  # but no longer accurately describes. The README says all of this so
  # the choice is the user's too.
  #
  # The feature costs nothing at run time. xz2 is declared with
  # features = ["static"], so lzma-sys compiles liblzma from vendored C
  # and links it in rather than finding a system copy; zip is
  # default-features = false with pure-Rust deflate (zlib-rs, not
  # libz-sys). Both end up inside the binary. The gate confirms it.
  #
  # That "static" is also why UNFLAB_TOOLCHAIN doesn't ask for
  # pkg-config, though Homebrew's formula lists pkgconf as a build
  # dependency. lzma-sys only probes pkg-config for a system liblzma
  # when a static link ISN'T wanted; with the feature on it skips
  # straight to compiling the bundled sources. Nothing else in the
  # tree reaches for pkg-config on macOS -- openssl-sys, the only
  # other user, isn't built for Apple targets. Which is just as well,
  # since build.sh deliberately points pkg-config at nothing to keep
  # Homebrew out of the search path.
  #
  # --locked builds against the committed Cargo.lock rather than
  # re-resolving. That keeps the build reproducible and means every
  # crate is pinned by the hash upstream tested, which matters because
  # this fetches from crates.io over the network -- the same bargain
  # doggo's go.sum makes.
  cargo build \
    --release \
    --locked \
    --package typst-cli \
    --features self-update

  # cargo puts the binary at the workspace root's target/, not under
  # the crate directory.
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 target/release/typst "$STAGE_DIR/bin/typst"

  # Apache-2.0 requires the NOTICE file to travel with the
  # distribution, so it ships alongside the licence rather than being
  # folded into it.
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 NOTICE "$STAGE_DIR/NOTICE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # build.rs renders a page for typst itself and one per subcommand
  # (typst-compile.1, typst-watch.1, ...). All of them ship: they are
  # what `man typst-compile` needs to resolve, and they are small.
  install -m 644 "$GEN_ARTIFACTS"/typst*.1 "$STAGE_DIR/share/man/man1/"

  # Shell completions are generated too, but not staged. The installer
  # has a `completion` kind that only knows bash's directory, and
  # nothing in the collection exercises it yet; shipping four shells'
  # worth of completions through a path this project has never tested
  # would be inventing an install layout on typst's behalf. `typst
  # completions <shell>` prints them on demand, which is upstream's own
  # answer, and the README points at it.

  # The manifest is generated rather than committed because the man
  # pages are: build.rs emits one per subcommand, so a release that
  # adds or removes one changes the list. A committed manifest naming a
  # page that no longer exists would not fail here -- it would fail on
  # the user's machine, because install.sh treats a file missing from
  # the package as fatal. Listing what was actually staged keeps the
  # two in step.
  {
    printf 'bin\t755\tbin/typst\ttypst\t-\n'
    for page in "$STAGE_DIR/share/man/man1"/*.1; do
      [ -f "$page" ] || continue
      name="$(basename "$page")"
      printf 'man1\t644\tshare/man/man1/%s\t%s\t-\n' "$name" "$name"
    done
    printf 'doc\t644\tREADME.md\tREADME.md\t-\n'
    printf 'doc\t644\tLICENSE\tLICENSE\t-\n'
    printf 'doc\t644\tNOTICE\tNOTICE\t-\n'
  } > "$STAGE_DIR/.unflab/manifest.tsv"
}
