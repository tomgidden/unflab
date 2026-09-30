# unflab -- install and remove unflab utilities by name
#
# Class 3 (convenience): the helper `get` drops beside the first thing
# it installs -- a wrapper that re-runs the same `curl … | sh` line, so
# nobody has to remember it. It has no dependencies to escape.
#
# It is a package like any other so that it installs, uninstalls, has
# a page and shows up in --list the same way everything else does, and
# so that a change to it reaches users through a release rather than
# a push. Its source is unflab.sh beside this file.
#
# Bump UNFLAB_VERSION when unflab.sh changes: nothing else will, since
# there is no upstream to move it.

UNFLAB_NAME=unflab
UNFLAB_VERSION=1.0.0
UNFLAB_HOMEPAGE=https://unflab.app/
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE=local
UNFLAB_ATTEST='none:the source is this repository'
UNFLAB_TOOLCHAIN=""
UNFLAB_CLASS=3
UNFLAB_PACKAGES=unflab
UNFLAB_SCRIPT_ONLY=1
UNFLAB_VERSION_FLAG=-

unflab_build() {
  sh -n unflab.sh
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  sed "s|{{BASE_URL}}|${UNFLAB_BASE_URL:-https://unflab.app}|g" unflab.sh \
    > "$STAGE_DIR/bin/unflab"
  chmod 755 "$STAGE_DIR/bin/unflab"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
  install -m 644 "$ROOT_DIR/LICENSE" "$STAGE_DIR/LICENSE"
}
