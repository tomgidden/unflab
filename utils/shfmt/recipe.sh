# shfmt -- format shell scripts
#
# Class 3 (convenience): shfmt has no Homebrew dependencies and upstream
# publishes prebuilt macOS binaries, so nothing is being escaped here.
# It's packaged for the same reason doggo is -- it belongs in the same
# one-line shape as everything else, and a CGO_ENABLED=0 Go binary makes
# the point of this project about as plainly as it can be made.
#
# The repo also contains cmd/gosh, which upstream's own source describes
# as "a proof of concept shell". Packaging a proof of concept as though
# it were a tool would pad the collection without helping anyone, so
# only shfmt is built. If gosh ever becomes something its author
# presents as usable, adding it is one line in UNFLAB_PACKAGES and a
# second stage function.

UNFLAB_NAME=shfmt
UNFLAB_VERSION=3.14.0
UNFLAB_HOMEPAGE=https://github.com/mvdan/sh
UNFLAB_LICENSE=BSD-3-Clause
UNFLAB_SOURCE=https://github.com/mvdan/sh/archive/refs/tags/v3.14.0.tar.gz
UNFLAB_CHECK=github:mvdan/sh
UNFLAB_SHA256=f193c946e2882c4fa04935cd583f60e2cab60344209bd982a3a5933c4192aad8
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes no checksum for it'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=shfmt

# The tarball unpacks to sh-<version>: the repo is mvdan/sh, and shfmt
# is one command inside it.
UNFLAB_SRC_DIR="$BUILD_ROOT/sh-$UNFLAB_VERSION"

unflab_build() {
  # CGO_ENABLED=0 is the whole trick: it makes Go use its pure-Go
  # standard library rather than linking the system's C libraries,
  # producing a binary that depends on nothing outside libSystem.
  #
  # -trimpath keeps build machine paths out of the binary; -s -w drop
  # the symbol table and DWARF, roughly halving the size.
  #
  # `shfmt --version` reads debug.ReadBuildInfo() rather than a
  # linker-set variable, so -X has nothing to set here -- Go accepts a
  # -X for a symbol that doesn't exist and silently ignores it, which is
  # exactly the sort of thing that looks like it works.
  #
  # From a tarball there's no git tree and no module version, so
  # --version reports "(unknown)". Only `go install …@v3.14.0` or a
  # build from the tagged git repo can set it. The formatter behaves
  # identically; the version shipped is recorded in the package
  # metadata, its README and the docs page.
  #
  # -buildvcs=false stops the build looking for the git tree it won't
  # find.
  CGO_ENABLED=0 go build \
    -trimpath \
    -buildvcs=false \
    -ldflags "-s -w" \
    -o shfmt \
    ./cmd/shfmt
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  install -m 755 shfmt "$STAGE_DIR/bin/shfmt"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # No man page upstream -- `shfmt --help` is the documentation.
}
