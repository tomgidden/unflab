# deno -- JavaScript and TypeScript runtime
#
# Delegate. Deno's installer takes an install root (DENO_INSTALL; the
# binary goes in its bin/), and `deno upgrade` keeps it current.
#
# It then runs a second-stage shell setup, fetched from jsr.io, that
# offers to edit rc files. That runs whenever stdout is a terminal and
# CI is unset -- `-y` runs it too, accepting its defaults -- so the
# command sets CI=1 to skip it. --no-modify-path is kept in case the
# installer's own logic changes.

UNFLAB_NAME=deno
UNFLAB_KIND=delegate
UNFLAB_HOMEPAGE=https://deno.com/
UNFLAB_INSTALL='curl -fsSL https://deno.land/install.sh | env DENO_INSTALL="$BASE" CI=1 sh -s -- --no-modify-path'
UNFLAB_REMOVE='rm "$BASE/bin/deno"'
