# ripgrep -- recursively searches directories for a regex pattern while respecting your gitignore
#
# Class 3 (convenience): ripgrep's only Homebrew dependency is rust, at build
# time, so there is no dependency tree to escape and upstream publishes
# prebuilt macOS binaries. It's here because it belongs in the same
# one-line shape as everything else.
#
# Dual-licensed MIT OR UNLICENSE. Both licence files ship: upstream
# offers the choice and dropping one would misrepresent the terms.

UNFLAB_NAME=ripgrep
UNFLAB_VERSION=15.2.0
UNFLAB_HOMEPAGE=https://github.com/BurntSushi/ripgrep
UNFLAB_LICENSE="MIT OR UNLICENSE"
UNFLAB_SOURCE=https://github.com/BurntSushi/ripgrep/archive/refs/tags/15.2.0.tar.gz
UNFLAB_CHECK=github:BurntSushi/ripgrep
UNFLAB_SHA256=7605249d3eb0d5f170e3414498e3344e26b1e7a147aec518b57090b80036a562
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes prebuilt binaries but no checksum for the source'
UNFLAB_TOOLCHAIN="rust cargo"
UNFLAB_CLASS=3
UNFLAB_PACKAGES=rg

unflab_build() {
	# --locked builds against the committed Cargo.lock rather than
	# re-resolving, so every crate is pinned by the hash upstream tested
	# -- the same bargain typst and doggo make for a build that fetches
	# over the network.
	cargo build --release --locked
}

unflab_stage() {
	install -d \
		"$STAGE_DIR/bin" \
		"$STAGE_DIR/share/man/man1" \
		"$STAGE_DIR/completion"

	install -m 755 target/release/rg "$STAGE_DIR/bin/rg"

	# Dual-licensed: ship both, since the choice is the user's to make.
	install -m 644 LICENSE-MIT "$STAGE_DIR/LICENSE-MIT"
	install -m 644 UNLICENSE "$STAGE_DIR/UNLICENSE"
	
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

	./target/release/rg --generate man > "$STAGE_DIR/share/man/man1/rg.1"
	./target/release/rg --generate complete-bash > "$STAGE_DIR/completion/rg.bash"
	./target/release/rg --generate complete-fish > "$STAGE_DIR/completion/rg.fish"
	./target/release/rg --generate complete-zsh > "$STAGE_DIR/completion/_rg"

	# A silently empty completion would install fine and do nothing, so
	# check rather than trust.
	for f in \
		"$STAGE_DIR/completion/rg.bash" \
		"$STAGE_DIR/completion/rg.fish" \
		"$STAGE_DIR/completion/_rg"; do
		[ -s "$f" ] || {
			echo "rg: $f is empty -- did the 'completions' feature go away?" >&2
			return 1
		}
	done

	# Shell integration does nothing until the user's shell is looking in
	# these directories, and zsh in particular needs fpath set before
	# compinit runs -- so say so rather than let it look like it failed.
	install -m 644 "$RECIPE_DIR/post-install.txt" "$STAGE_DIR/.unflab/post-install.txt"
}
