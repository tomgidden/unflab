# glow -- render markdown on the command line
#
# Class 3 (convenience): glow has no Homebrew dependencies and upstream
# publishes prebuilt macOS binaries, so nothing is being escaped here.
# It's here so it installs the same way as everything else, and because
# `unflab --info` reads better through it.

UNFLAB_NAME=glow
UNFLAB_VERSION=3.0.0
UNFLAB_HOMEPAGE=https://github.com/charmbracelet/glow
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/charmbracelet/glow/releases/download/v3.0.0/glow-3.0.0.tar.gz
UNFLAB_CHECK=github:charmbracelet/glow
UNFLAB_SHA256=d16dcb89c50f85180ffb25f74a9ad7aa146380dffbc344e4f3344fcf729bbfd3
UNFLAB_ATTEST='sha256:https://github.com/charmbracelet/glow/releases/download/v$V/checksums.txt'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=glow

# goreleaser's source archive has no top-level directory: it unpacks
# straight into the build root.
UNFLAB_SRC_DIR="$BUILD_ROOT"

unflab_build() {
  # CGO_ENABLED=0 so the binary links nothing but libSystem. -X sets the
  # version goreleaser would; without it `glow --version` reports
  # "unknown (built from source)". No git tree here, hence
  # -buildvcs=false.
  CGO_ENABLED=0 go build \
    -trimpath \
    -buildvcs=false \
    -ldflags "-s -w -X main.Version=${UNFLAB_VERSION}" \
    -o glow \
    .
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1" \
             "$STAGE_DIR/completion"
  install -m 755 glow "$STAGE_DIR/bin/glow"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # The man page and completions come from the binary just built
  # (`glow man` is hidden, `completion` is cobra's), so they can't
  # drift from the flags it accepts. HOME points into the build tree:
  # glow reads its config on start-up and has no business with the
  # builder's.
  HOME="$BUILD_DIR/.home" ./glow man > "$STAGE_DIR/share/man/man1/glow.1"
  HOME="$BUILD_DIR/.home" ./glow completion zsh  > "$STAGE_DIR/completion/_glow"
  HOME="$BUILD_DIR/.home" ./glow completion bash > "$STAGE_DIR/completion/glow.bash"
  HOME="$BUILD_DIR/.home" ./glow completion fish > "$STAGE_DIR/completion/glow.fish"

  # An empty file would install fine and do nothing.
  for f in "$STAGE_DIR/share/man/man1/glow.1" \
           "$STAGE_DIR/completion/_glow" \
           "$STAGE_DIR/completion/glow.bash" \
           "$STAGE_DIR/completion/glow.fish"; do
    [ -s "$f" ] || { echo "glow: $f is empty" >&2; return 1; }
  done

  install -m 644 "$RECIPE_DIR/post-install.txt" "$STAGE_DIR/.unflab/post-install.txt"
}
