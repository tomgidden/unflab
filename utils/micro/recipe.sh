# micro -- a modern and intuitive terminal-based text editor
#
# Class 3 (convenience): micro's Homebrew formula has no runtime
# dependencies -- only Go at build time -- and upstream publishes
# prebuilt macOS binaries. So nothing is being rescued from a dependency
# tree here.
#
# It's packaged for the same reason doggo and shfmt are: it belongs in
# the same one-line shape as everything else. What makes it worth having
# alongside nano is that it is the other kind of terminal editor -- it
# uses the shortcuts everyone already knows (Ctrl-S, Ctrl-C, Ctrl-V,
# Ctrl-Z) rather than the Pico lineage's Ctrl-O/Ctrl-X, and it needs no
# configuration to be useful.
#
# Everything it needs at run time is compiled in. The runtime tree --
# 39 syntax definitions, colour schemes, help files and the built-in
# plugins -- is embedded via go:embed (see runtime/runtime.go), so there
# is no share/micro to install and no way for the binary to end up
# looking for files that aren't there. Verified by running it with an
# empty HOME: the built-in plugins still load.

UNFLAB_NAME=micro
UNFLAB_VERSION=2.0.15
UNFLAB_HOMEPAGE=https://micro-editor.github.io/
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/zyedidia/micro/archive/refs/tags/v2.0.15.tar.gz
UNFLAB_CHECK=github:zyedidia/micro
UNFLAB_SHA256=612c775321c268c8f9e1767505ff378bca9b9ab66f5c41b69ecb2464ecf15084
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes prebuilt binaries but no checksum for the source'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=micro

unflab_build() {
  # Upstream's Makefile is deliberately not used, for two reasons that
  # both come down to it expecting a git checkout rather than a tarball:
  #
  #   1. It derives VERSION and DATE by running `go run tools/*.go`,
  #      which shell out to `git describe`, and HASH from `git
  #      rev-parse`. In an unpacked tarball there is no git tree, so
  #      those come out empty and `micro -version` reports nothing.
  #
  #   2. On darwin it forces CGO_ENABLED=1 and injects linker flags from
  #      tools/info-plist.go, to embed an Info.plist. That is for a
  #      .app-style bundle and buys a command-line binary nothing, but it
  #      does mean linking the system's C libraries.
  #
  # Building ./cmd/micro directly with CGO_ENABLED=0 sidesteps both:
  # pure-Go standard library, nothing outside libSystem, and the version
  # strings set explicitly from the metadata above so `micro -version`
  # reports what was actually built.
  #
  # CommitHash is set to the tag rather than a commit SHA. The tarball
  # doesn't carry one, and an honest tag beats either a blank field or a
  # SHA invented here.
  #
  # -trimpath keeps build machine paths out of the binary; -s -w drop
  # the symbol table and DWARF, which upstream's own release build also
  # does. -buildvcs=false stops the build looking for the git tree it
  # won't find.
  #
  # This needs network access to fetch modules: micro doesn't vendor its
  # dependencies. go.sum pins every one of them by hash, so the download
  # is verified even though it isn't offline.
  local util="github.com/zyedidia/micro/v2/internal/util"

  CGO_ENABLED=0 go build \
    -trimpath \
    -buildvcs=false \
    -ldflags "-s -w
      -X ${util}.Version=${UNFLAB_VERSION}
      -X ${util}.CommitHash=v${UNFLAB_VERSION}
      -X ${util}.CompileDate=unflab" \
    -o micro \
    ./cmd/micro
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 micro "$STAGE_DIR/bin/micro"
  install -m 644 assets/packaging/micro.1 "$STAGE_DIR/share/man/man1/micro.1"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # micro statically links its Go dependencies, so their licences travel
  # inside the binary whether or not this file ships. Upstream collects
  # them in one place; shipping it is what makes that attribution
  # visible to whoever ends up with the package.
  install -m 644 LICENSE-THIRD-PARTY "$STAGE_DIR/LICENSE-THIRD-PARTY"

  # No completions upstream: micro ships none for any shell, and its
  # flags are few enough that `micro -help` covers them.

  # No post-install note. Unlike nano, micro claims a name nothing else
  # answers to, and it needs no configuration or shell wiring to work.
}
