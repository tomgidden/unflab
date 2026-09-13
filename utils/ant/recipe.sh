# ant -- the CLI for the Claude API
#
# Class 3 (convenience): anthropic-cli has no Homebrew dependencies --
# upstream publishes prebuilt macOS binaries and an official tap -- so
# nothing is being escaped here. It is packaged for the same reason
# doggo and shfmt are: it belongs in the same one-line shape as
# everything else, and a CGO_ENABLED=0 Go binary makes the point of
# this project about as plainly as it can be made.
#
# The binary is `ant`, not `anthropic-cli`; the repo is named for the
# project and the tool for the command, so the package follows the
# command.
#
# Ships askclaude, a zsh function wrapping `ant messages create` for
# one-shot questions from the command line. It is not upstream's -- see
# the comment in unflab_stage -- and it needs jq, which this collection
# also ships.

UNFLAB_NAME=ant
UNFLAB_VERSION=1.32.0
UNFLAB_HOMEPAGE=https://github.com/anthropics/anthropic-cli
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/anthropics/anthropic-cli/archive/refs/tags/v1.32.0.tar.gz
UNFLAB_CHECK=github:anthropics/anthropic-cli
UNFLAB_SHA256=a665acc56ab301229e409f1c1d0c394e8508f628a339938048e7ba5e22df45f4
UNFLAB_ATTEST='none:upstream publishes a checksums.txt, but it covers the prebuilt release binaries only -- not the GitHub tag archive this builds from'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=ant

# The tarball unpacks to anthropic-cli-<version>: the repo is
# anthropic-cli, the binary it produces is ant.
UNFLAB_SRC_DIR="$BUILD_ROOT/anthropic-cli-$UNFLAB_VERSION"

unflab_build() {
  # CGO_ENABLED=0 is the whole trick: it makes Go use its pure-Go
  # standard library rather than linking the system's C libraries,
  # producing a binary that depends on nothing outside libSystem.
  # Upstream's own .goreleaser.yml sets it for every target, so this
  # matches what their released macOS binaries do.
  #
  # -trimpath keeps build machine paths out of the binary; -s -w drop
  # the symbol table and DWARF, which upstream's release build also
  # does and roughly halves the size.
  #
  # The -X flags are upstream's, copied from .goreleaser.yml: main.
  # version and main.commit are package-level vars, so `ant --version`
  # reports "ant version 1.32.0" rather than a bare "dev". There is no
  # commit to name when building from a tarball, so it says unflab.
  #
  # This needs network access to fetch modules: anthropic-cli doesn't
  # vendor its dependencies. go.sum pins every one of them by hash, so
  # the download is verified even though it isn't offline.
  CGO_ENABLED=0 go build \
    -trimpath \
    -buildvcs=false \
    -ldflags "-s -w -X main.version=${UNFLAB_VERSION} -X main.commit=unflab" \
    -o ant \
    ./cmd/ant

  # Upstream generates its man page from the command tree rather than
  # committing one, via a hidden @manpages command -- the same call
  # their .goreleaser.yml makes before packaging. One page covers the
  # whole tool; the subcommands are documented inside it.
  ./ant @manpages -o manpages
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1" \
             "$STAGE_DIR/functions"
  install -m 755 ant "$STAGE_DIR/bin/ant"

  # @manpages writes ant.1.gz. macOS's man reads gzipped pages, but
  # every other recipe here stages an uncompressed one and the litmus
  # test resolves pages by name, so decompress rather than make this
  # package the exception.
  [ -f manpages/man1/ant.1.gz ] || {
    echo "ant: no man page in manpages/man1 -- did @manpages change?" >&2
    return 1
  }
  gunzip -c manpages/man1/ant.1.gz > "$STAGE_DIR/share/man/man1/ant.1"
  chmod 644 "$STAGE_DIR/share/man/man1/ant.1"

  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # askclaude is ours, not upstream's: a small function wrapping `ant
  # messages create` for one-shot questions, so you can ask something
  # without composing the JSON by hand. Shipped here rather than as its
  # own package because it is useless without ant.
  #
  # One per shell rather than one file sourced by all three: the zsh
  # version uses `emulate -L zsh`, and fish is not POSIX at all, so a
  # shared file would be a lowest common denominator none of them wants.
  #
  # The zsh copy loses its extension on the way in. zsh autoload finds a
  # function by FILENAME, so the file in site-functions has to be called
  # exactly `askclaude` -- an askclaude.zsh there would never be found.
  # The .zsh suffix exists only in the recipe directory, for symmetry
  # with its siblings.
  #
  # All three need jq to build the request and read the reply back. jq
  # is in this collection but is NOT installed by this package, so the
  # notes mention it rather than leaving a confusing failure.
  install -m 644 "$RECIPE_DIR/askclaude.zsh"  "$STAGE_DIR/functions/askclaude"
  install -m 644 "$RECIPE_DIR/askclaude.bash" "$STAGE_DIR/functions/askclaude.bash"
  install -m 644 "$RECIPE_DIR/askclaude.fish" "$STAGE_DIR/functions/askclaude.fish"

  install -m 644 "$RECIPE_DIR/post-install.txt" "$STAGE_DIR/.unflab/post-install.txt"
}
