# node -- Node.js, installed with a one-off run of n
#
# Delegate. Node has no official install script, and building it here
# would be a multi-hour C++ build of something upstream already ships
# prebuilt. `n` (utils/n) is a single bash script that downloads those
# official builds, and its README documents running it straight from
# GitHub for a one-off install. With N_PREFIX set to the prefix root,
# node, npm and npx land in the same bin directory as everything else.
#
# The removal command uses bash <(curl ...) rather than a pipe because
# `n uninstall` asks for confirmation on stdin.

UNFLAB_NAME=node
UNFLAB_KIND=delegate
UNFLAB_HOMEPAGE=https://nodejs.org/
UNFLAB_INSTALL='curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | env N_PREFIX="$BASE" bash -s lts'
UNFLAB_REMOVE='N_PREFIX="$BASE" bash <(curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n) uninstall && rm -rf "$BASE/n"'
