# fzf -- command-line fuzzy finder
#
# Class 3 (convenience): fzf has no Homebrew dependencies worth escaping
# -- brew's formula pulls in nothing but Go at build time -- and
# upstream publishes prebuilt macOS binaries. It's here because it
# belongs in the same one-line shape as everything else, and because a
# CGO_ENABLED=0 Go binary makes this project's promise plainly.
#
# Homebrew builds this one with CGO_ENABLED=1 on macOS (and 0
# everywhere else) against the system ncurses. That would pass the gate
# -- ncurses is in /usr/lib -- but it pins the binary to the SDK it was
# built against for no benefit we can name, and upstream's own release
# builds are CGO_ENABLED=0. So we follow upstream, not brew.
#
# The shell integration is the part people actually mean by "fzf": the
# Ctrl-R history search and Ctrl-T file widget live in shell/*.zsh and
# friends, not in the binary. Those are shipped as data and sourced by
# the user -- see the caveats file for why they aren't wired up
# automatically.
#
# Not shipped: upstream's own `install`/`uninstall` scripts, which exist
# to wire up a git-clone install and would fight ours; and the nushell
# (.nu) integration, for a shell nothing else here supports.

UNFLAB_NAME=fzf
UNFLAB_VERSION=0.74.4
UNFLAB_HOMEPAGE=https://junegunn.github.io/fzf/
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/junegunn/fzf/archive/refs/tags/v0.74.4.tar.gz
UNFLAB_CHECK=github:junegunn/fzf
UNFLAB_SHA256=1046857c337f5bd05f6fa482446b5a42a011615105743efbe4efee0970b24bb7
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes no checksum for it'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=fzf

unflab_build() {
  # CGO_ENABLED=0 is the whole trick: it makes Go use its pure-Go
  # standard library rather than linking the system's C libraries,
  # producing a binary that depends on nothing outside libSystem.
  #
  # -trimpath keeps build machine paths out of the binary; -s -w drop
  # the symbol table and DWARF, roughly halving the size.
  #
  # Unlike shfmt, the -X flags here do bind: fzf declares `version` and
  # `revision` as package-level vars in main.go, so `fzf --version`
  # reports "0.74.4 (unflab)" rather than the built-in "0.74 (devel)".
  #
  # This needs network access to fetch modules: fzf doesn't vendor its
  # dependencies. go.sum pins every one by hash, so the download is
  # verified even though it isn't offline.
  CGO_ENABLED=0 go build \
    -trimpath \
    -buildvcs=false \
    -ldflags "-s -w -X main.version=${UNFLAB_VERSION} -X main.revision=unflab" \
    -o fzf \
    .
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1" "$STAGE_DIR/shell"
  install -m 755 fzf "$STAGE_DIR/bin/fzf"

  # Two shell scripts, not binaries. Homebrew ships both in bin/ too:
  # fzf-tmux opens fzf in a tmux split, and fzf-preview.sh is the
  # preview helper its own man page and examples reference by name.
  install -m 755 bin/fzf-tmux "$STAGE_DIR/bin/fzf-tmux"
  install -m 755 bin/fzf-preview.sh "$STAGE_DIR/bin/fzf-preview.sh"

  install -m 644 man/man1/fzf.1 "$STAGE_DIR/share/man/man1/fzf.1"
  install -m 644 man/man1/fzf-tmux.1 "$STAGE_DIR/share/man/man1/fzf-tmux.1"

  # Staged under shell/ for legibility; the manifest flattens them into
  # <prefix>/share/fzf/ on install, where the names stay unambiguous.
  for f in key-bindings.bash key-bindings.zsh key-bindings.fish \
           completion.bash completion.zsh; do
    install -m 644 "shell/$f" "$STAGE_DIR/shell/$f"
  done
  # No completion.fish: fish's own completions cover fzf, and upstream's
  # file is examples rather than something to source.

  # Inert unless the user adds this directory to vim's runtimepath,
  # which is exactly how Homebrew ships it.
  install -m 644 plugin/fzf.vim "$STAGE_DIR/shell/fzf.vim"

  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # Shell integration does nothing until sourced, so the install would
  # otherwise look successful while Ctrl-R was silently missing.
  install -m 644 "$RECIPE_DIR/caveats.txt" "$STAGE_DIR/.unflab/caveats.txt"
}
