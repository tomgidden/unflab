# n -- install and switch between Node.js versions
#
# Class 3 (convenience): n is a single bash script with no dependencies,
# so there's nothing to escape. It's here because it's the smallest way
# to get Node.js onto a Mac without a package manager, and `unflab node`
# uses it too -- as a one-off, without installing it.
#
# n defaults to installing Node under /usr/local, which needs sudo. The
# post-install note says to set N_PREFIX to the prefix unflab installed
# into, which keeps node, npm and n's cache under ~/.local.

UNFLAB_NAME=n
UNFLAB_VERSION=10.2.0
UNFLAB_HOMEPAGE=https://github.com/tj/n
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/tj/n/archive/refs/tags/v10.2.0.tar.gz
UNFLAB_CHECK=github:tj/n
UNFLAB_SHA256=5914f0d5e89aadaaaeb803baa89a7582747b0c57ad30201b3522cd76f504c7d9
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes no checksum for it'
UNFLAB_TOOLCHAIN=""
UNFLAB_CLASS=3
UNFLAB_PACKAGES=n

UNFLAB_SCRIPT_ONLY=1

unflab_build() {
  [ -f bin/n ] || {
    echo "n: bin/n missing from upstream tarball" >&2
    return 1
  }
  bash -n bin/n || {
    echo "n: bin/n is not valid bash" >&2
    return 1
  }
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  install -m 755 bin/n "$STAGE_DIR/bin/n"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
  install -m 644 "$RECIPE_DIR/post-install.txt" "$STAGE_DIR/.unflab/post-install.txt"

  # No man page upstream -- `n --help` is the documentation.
}
