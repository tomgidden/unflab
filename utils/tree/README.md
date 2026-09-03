# tree (unflab build)

`tree` lists the contents of directories as an indented tree.

This is a standalone build for macOS: one binary, its man page, and
nothing else. It depends only on libraries that ship with macOS, so
there is no package manager, no runtime dependency, and nothing else
installed alongside it.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

Run `./install.sh --help` for the full set of options.

If `~/.local/bin` isn't on your `PATH`, the installer says so and offers
to add it — it won't edit your shell config without asking.

## Upstream

- Home: https://oldmanprogrammer.net/source.php?dir=projects/tree
- Source: https://gitlab.com/OldManProgrammer/unix-tree
- Version: 2.3.2
- Licence: GPL-2.0-or-later (see `LICENSE`)

`tree` is Steve Baker's work, not this project's. unflab only compiles
and packages it. The exact source tarball and its checksum are recorded
in the recipe this package was built from.

# Upstream is at 1.11.0 as of 2026-09-03.
