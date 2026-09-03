# miller -- like awk, sed, cut and join, but for CSV, TSV and JSON
#
# Class 3 (convenience): miller is a Go binary with no Homebrew
# dependencies, and upstream publishes macOS builds. It's here because
# it's genuinely useful and less well known than jq, and because it
# should install the same way as everything else.

UNFLAB_NAME=miller
UNFLAB_VERSION=6.21.0
UNFLAB_HOMEPAGE=https://miller.readthedocs.io/
UNFLAB_LICENSE=BSD-2-Clause
UNFLAB_SOURCE=https://github.com/johnkerl/miller/archive/refs/tags/v6.21.0.tar.gz
UNFLAB_CHECK=github:johnkerl/miller
UNFLAB_SHA256=f92366ed67ffdbc75e8daf99a5087bcaa786c50f7c0eec08a8846e14fe7b2e5d
UNFLAB_ATTEST='none:upstream checksums cover release binaries, not the tag archive we build from'
UNFLAB_TOOLCHAIN="go"
UNFLAB_CLASS=3

# The repo is `miller`; the command has always been `mlr`. Package it
# under the name people actually type.
UNFLAB_PACKAGES=mlr

unflab_build() {
  # Same reasoning as doggo: CGO_ENABLED=0 keeps this to a single binary
  # depending on nothing but libSystem.
  CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags "-s -w" \
    -o mlr \
    ./cmd/mlr
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1"
  install -m 755 mlr "$STAGE_DIR/bin/mlr"
  install -m 644 docs/src/mlr.1 "$STAGE_DIR/share/man/man1/mlr.1"
  install -m 644 LICENSE.txt "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
