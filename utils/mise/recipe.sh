# mise -- manage versions of language runtimes and dev tools
#
# Delegate. mise's installer puts one binary at MISE_INSTALL_PATH (by
# default ~/.local/bin/mise, the same place unflab uses) and only prints
# how to activate it -- it edits nothing. `mise self-update` keeps it
# current, which a copy built here couldn't.

UNFLAB_NAME=mise
UNFLAB_KIND=delegate
UNFLAB_HOMEPAGE=https://mise.jdx.dev/
UNFLAB_INSTALL='curl -fsSL https://mise.run | env MISE_INSTALL_PATH="$PREFIX/mise" sh'
UNFLAB_REMOVE='mise implode'
