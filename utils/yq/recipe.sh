# yq -- query and edit YAML, JSON, XML, TOML and CSV from the shell
#
# Class 3 (convenience): yq has no Homebrew dependencies and upstream
# publishes prebuilt macOS binaries, so nothing is being escaped here.
# It's packaged because it sits alongside jq and xq: jq is the stronger
# language for JSON, yq is the one that reads everything else -- and
# edits YAML in place without losing its comments.
#
# This is mikefarah/yq, the Go implementation Homebrew calls `yq`. The
# other yq (kislyuk/yq, the Python jq wrapper that also provides an
# `xq`) is not shipped; utils/NOT-SHIPPED.md records why.

UNFLAB_NAME=yq
UNFLAB_VERSION=4.53.6
UNFLAB_HOMEPAGE=https://mikefarah.gitbook.io/yq/
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/mikefarah/yq/archive/refs/tags/v4.53.6.tar.gz
UNFLAB_CHECK=github:mikefarah/yq
UNFLAB_SHA256=132a28a669526f99dba52486ac80de3bdafdf9a1a52a0c6bd6045301aca0cd25
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream checksums cover its release binaries, not this'
UNFLAB_TOOLCHAIN="go pandoc"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=yq

unflab_build() {
  # CGO_ENABLED=0 gives a binary linked against nothing but libSystem.
  # -trimpath keeps build machine paths out; -s -w drop the symbol table
  # and DWARF, as upstream's own release build does.
  #
  # No build tags: upstream's scripts/build-small-yq.sh shows the
  # yq_no* tags that strip formats out, and the full set is the point.
  #
  # The version is a literal in cmd/version.go, so `yq --version` is
  # right from a tarball with no -X needed. Modules are fetched over
  # the network and verified against go.sum.
  CGO_ENABLED=0 go build \
    -trimpath \
    -buildvcs=false \
    -ldflags "-s -w" \
    -o yq \
    .
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/completion"
  install -m 755 yq "$STAGE_DIR/bin/yq"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # Completions come from the binary just built, so they can't drift
  # from the flags it accepts. zsh wants `_yq` with its `#compdef` line.
  ./yq completion zsh  > "$STAGE_DIR/completion/_yq"
  ./yq completion bash > "$STAGE_DIR/completion/yq.bash"
  ./yq completion fish > "$STAGE_DIR/completion/yq.fish"

  # An empty completion would install fine and do nothing.
  for f in "$STAGE_DIR/completion/_yq" \
           "$STAGE_DIR/completion/yq.bash" \
           "$STAGE_DIR/completion/yq.fish"; do
    [ -s "$f" ] || {
      echo "yq: $f is empty -- did \`yq completion\` change?" >&2
      return 1
    }
  done

  install -m 644 "$RECIPE_DIR/post-install.txt" "$STAGE_DIR/.unflab/post-install.txt"

  # The man page is assembled from the operator docs in pkg/yqlib/doc
  # and converted with pandoc, the way upstream's release does it.
  # Build time only -- the shipped page is plain roff.
  bash scripts/generate-man-page-md.sh
  MAN_HEADER="yq $UNFLAB_VERSION" bash scripts/generate-man-page.sh
  install -d "$STAGE_DIR/share/man/man1"
  install -m 644 yq.1 "$STAGE_DIR/share/man/man1/yq.1"
}
