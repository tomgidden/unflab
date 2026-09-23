# xq -- pretty-print and query XML and HTML
#
# Class 3 (convenience): xq has no Homebrew dependencies and upstream
# publishes prebuilt macOS binaries, so nothing is being escaped here.
# It overlaps with both xmlstarlet (XPath over XML) and yq (`-p xml`),
# and is shipped anyway for what neither does: HTML, CSS selectors, and
# readable coloured output of a document you just want to look at.
#
# This is sibprogrammer/xq, the one Homebrew calls `xq`. The Python yq
# package (kislyuk/yq) also installs an `xq` -- a jq wrapper for XML,
# and an unrelated program. That one is not shipped; see
# utils/NOT-SHIPPED.md.

UNFLAB_NAME=xq
UNFLAB_VERSION=1.5.1
UNFLAB_HOMEPAGE=https://github.com/sibprogrammer/xq
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/sibprogrammer/xq/archive/refs/tags/v1.5.1.tar.gz
UNFLAB_CHECK=github:sibprogrammer/xq
UNFLAB_SHA256=d57579a6c2009f3bd0f6b6f66f12744eb895575b767e7a02a099003c6bdcda3d
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream checksums.txt covers its release binaries, not this'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=xq

unflab_build() {
  # CGO_ENABLED=0 gives a binary linked against nothing but libSystem,
  # as upstream's .goreleaser.yml also sets. -trimpath keeps build
  # machine paths out; -s -w drop the symbol table and DWARF.
  #
  # The version comes from the `version` file, embedded with go:embed,
  # so `xq --version` is right from a tarball. goreleaser's -X for
  # main.date and main.commit only appends build details, and there's no
  # commit to name here. Modules are fetched and verified against go.sum.
  CGO_ENABLED=0 go build \
    -trimpath \
    -buildvcs=false \
    -ldflags "-s -w" \
    -o xq \
    .
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1" "$STAGE_DIR/completion"
  install -m 755 xq "$STAGE_DIR/bin/xq"
  install -m 644 docs/xq.man "$STAGE_DIR/share/man/man1/xq.1"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # xq doesn't define a completion command; this is the one cobra adds
  # by default. It's generated from the binary, so it can't drift from
  # the flags. zsh wants `_xq` with its `#compdef` line.
  ./xq completion zsh  > "$STAGE_DIR/completion/_xq"
  ./xq completion bash > "$STAGE_DIR/completion/xq.bash"
  ./xq completion fish > "$STAGE_DIR/completion/xq.fish"

  # Cobra's default command can be switched off upstream in one line
  # without anything else noticing, so check the output isn't empty.
  for f in "$STAGE_DIR/completion/_xq" \
           "$STAGE_DIR/completion/xq.bash" \
           "$STAGE_DIR/completion/xq.fish"; do
    [ -s "$f" ] || {
      echo "xq: $f is empty -- did cobra's \`completion\` command go away?" >&2
      return 1
    }
  done

  install -m 644 "$RECIPE_DIR/post-install.txt" "$STAGE_DIR/.unflab/post-install.txt"
}
