# uv -- Astral's Python package and project manager
#
# Delegate. uv is Rust and could be built here, but its own installer is
# the better path: it supports installing into a chosen directory
# (UV_INSTALL_DIR) without touching shell config (UV_NO_MODIFY_PATH),
# and a uv installed that way can update itself with `uv self update`. A
# uv built by unflab would be stuck at whatever version the last release
# carried.
#
# It is also where unflab points for Python tools generally: a Python
# CLI needs an interpreter, which unflab bundles only for a tool that
# earns it (see pyinstaller in AGENTS.md), and `uv tool install` / `uvx`
# manage exactly that.

UNFLAB_NAME=uv
UNFLAB_KIND=delegate
UNFLAB_HOMEPAGE=https://docs.astral.sh/uv/
UNFLAB_INSTALL='curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$PREFIX" UV_NO_MODIFY_PATH=1 sh'
UNFLAB_REMOVE='uv cache clean && rm -rf "$(uv python dir)" "$(uv tool dir)" && rm "$PREFIX/uv" "$PREFIX/uvx"'
