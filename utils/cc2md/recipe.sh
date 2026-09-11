# cc2md -- convert Claude Code session logs to readable markdown
#
# Class 3 (convenience): a CGO_ENABLED=0 Go binary with no Homebrew
# dependencies, packaged so it installs the same way as everything
# else here. Upstream already ships prebuilt binaries and a Homebrew
# tap; nothing here escapes a dependency tree.

UNFLAB_NAME=cc2md
UNFLAB_VERSION=0.1.0
UNFLAB_HOMEPAGE=https://github.com/magarcia/cc2md
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/magarcia/cc2md/archive/refs/tags/v0.1.0.tar.gz
UNFLAB_CHECK=github:magarcia/cc2md
UNFLAB_SHA256=c497b0326d0d17af1c1e02a8fc42063be28cde4619ef9935e7b87b5fdafc7438
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes no checksum for it'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=cc2md

unflab_build() {
  # Same trick as every other Go recipe here: CGO_ENABLED=0 forces the
  # pure-Go standard library, so the binary links against nothing
  # outside libSystem.
  #
  # Upstream's .goreleaser.yml sets these same ldflags via -X
  # main.version etc; main.go's version/commit/date vars are package
  # main, not cmd, so main.<var> is the right symbol path from a plain
  # `go build .` (goreleaser builds the same way).
  CGO_ENABLED=0 go build \
    -trimpath \
    -buildvcs=false \
    -ldflags "-s -w -X main.version=$UNFLAB_VERSION" \
    -o cc2md \
    .
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  install -m 755 cc2md "$STAGE_DIR/bin/cc2md"

  # No LICENSE file upstream (magarcia/cc2md as of v0.1.0) -- the MIT
  # grant is stated only in README.md's "License" section. We write it
  # out here rather than ship nothing, since AGENTS.md requires the
  # licence travel with the package.
  cat > "$STAGE_DIR/LICENSE" <<'EOF'
MIT License

Copyright (c) Miguel A. Garcia (magarcia)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EOF

  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # No man page upstream -- `cc2md --help` is the documentation.
}
