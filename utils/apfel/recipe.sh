# apfel -- Apple's on-device language model from the command line
#
# Class 3 (convenience). Homebrew's formula has no dependencies at all;
# apfel is here so it installs the same way as everything else.
#
# It does not compile its binary, for the same reason ffmpeg doesn't:
# upstream already publishes one that meets the rule. The release
# tarball's `apfel` is thin arm64, signed with the author's Developer ID
# (team 7D2YX5DQ6M) and notarised, and links only the base system --
# FoundationModels, Vision and PDFKit among the frameworks, and the OS's
# own Swift runtime. Building it here would mean a Swift toolchain on
# the macOS 26.4 SDK, and SwiftPM resolving some 25 packages at build
# time, for an artefact no better than upstream's.
#
# So the package ships the man page, completions, licence and README,
# and its install.sh downloads the binary on the user's machine, keeping
# it only if it matches the SHA-256 in fetch.tsv and carries a valid
# signature from that team.
#
# UNFLAB_SOURCE is the tag archive rather than the release tarball: the
# release tarball has no LICENSE. For 1.12.0 its completions and its
# man page (once @VERSION@ is filled in) are byte-identical to the ones
# in the release tarball, and its SHA-256 is the one Homebrew pins.
#
# Not shipped: the release tarball's demo/ scripts. `apfel demos <dir>`
# writes the same scripts out from the binary itself.
#
# Needs Apple Silicon, macOS 26 or later, and Apple Intelligence
# switched on. The binary installs and runs without the last, but has
# no model to answer prompts with.

UNFLAB_NAME=apfel
UNFLAB_VERSION=1.12.0
UNFLAB_HOMEPAGE=https://apfel.franzai.com
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=https://github.com/Arthur-Ficial/apfel/archive/refs/tags/v1.12.0.tar.gz
UNFLAB_SHA256=baae1ab8e1a7121e3a998e36090343e1dbdde283639fe84f5a625f8bae25038c
UNFLAB_ATTEST='none:GitHub auto-generated tag archive; upstream publishes prebuilt binaries but no checksum for the source'
UNFLAB_CHECK=github:Arthur-Ficial/apfel
UNFLAB_TOOLCHAIN=""
UNFLAB_CLASS=3
UNFLAB_PACKAGES=apfel
UNFLAB_VERSION_FLAG=--version

unflab_build() {
  # The same substitution upstream's `make generate-man-page` does.
  sed "s/@VERSION@/$UNFLAB_VERSION/g" man/apfel.1.in > apfel.1
  ! grep -q '@[A-Z_]*@' apfel.1 || {
    echo "apfel: man/apfel.1.in has a placeholder other than @VERSION@" >&2
    return 1
  }
}

unflab_stage() {
  install -d "$STAGE_DIR/share/man/man1" "$STAGE_DIR/completion"
  install -m 644 apfel.1 "$STAGE_DIR/share/man/man1/apfel.1"

  install -m 644 completions/apfel.bash "$STAGE_DIR/completion/apfel.bash"
  install -m 644 completions/apfel.zsh "$STAGE_DIR/completion/_apfel"
  install -m 644 completions/apfel.fish "$STAGE_DIR/completion/apfel.fish"

  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"

  # Installing is not the same as working: every prompt fails until
  # Apple Intelligence is on, and zsh needs fpath set before compinit.
  install -m 644 "$RECIPE_DIR/post-install.txt" "$STAGE_DIR/.unflab/post-install.txt"
}
