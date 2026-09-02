# doggo -- a modern DNS client for the command line
#
# Class 3 (convenience): doggo has no Homebrew dependencies and upstream
# publishes prebuilt macOS binaries, so this isn't rescuing anyone from a
# dependency tree. It's here because it belongs in the same one-line
# shape as everything else -- and because a CGO_ENABLED=0 Go binary is
# the cleanest possible demonstration of what this project promises: one
# file, linked against nothing but libSystem.

UNFLAB_NAME=doggo
UNFLAB_VERSION=1.3.0
UNFLAB_HOMEPAGE=https://doggo.mrkaran.dev/
UNFLAB_LICENSE=GPL-3.0-or-later
UNFLAB_SOURCE=https://github.com/mr-karan/doggo/archive/refs/tags/v1.3.0.tar.gz
UNFLAB_CHECK=github:mr-karan/doggo
UNFLAB_SHA256=877f047fe81185d4fbeec870d54233f7ebf7c707a41cb98d023c34e089f9a0c0
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes no checksum for it'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=doggo

unflab_build() {
  # CGO_ENABLED=0 is the whole trick: it makes Go use its pure-Go
  # resolver and standard library rather than linking the system's C
  # libraries, producing a binary that depends on nothing outside
  # libSystem. Without it, net and os/user link against libresolv and
  # friends -- which would still pass the gate, but pins the binary to
  # the SDK it was built against for no benefit.
  #
  # -trimpath keeps build machine paths out of the binary; -s -w drop
  # the symbol table and DWARF, which upstream's own release build also
  # does and roughly halves the size.
  #
  # This needs network access to fetch modules: doggo doesn't vendor its
  # dependencies. go.sum pins every one of them by hash, so the download
  # is verified even though it isn't offline.
  CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags "-s -w -X 'main.buildVersion=${UNFLAB_VERSION}' -X 'main.buildDate=unflab'" \
    -o doggo \
    ./cmd/doggo/
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/config"
  install -m 755 doggo "$STAGE_DIR/bin/doggo"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # Shipped for reference, not installed: doggo runs fine with no config
  # at all, so writing one into ~/.config uninvited would be presumptuous.
  install -m 644 config-cli-sample.toml "$STAGE_DIR/config/doggo.toml.sample"

  # No man page upstream -- `doggo --help` is the documentation.
}
