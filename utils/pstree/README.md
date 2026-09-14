# pstree (unflab build)

`pstree` shows the process listing (`ps`) as a tree (as the name implies...)

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

- Home: https://github.com/FredHucht/pstree
- Source: https://github.com/FredHucht/pstree
- Version: 2.40
- Licence: GPL-3.0 (see `LICENSE`)

`pstree` is Fred Hucht's work, not this project's. unflab only compiles
and packages it. The exact source tarball and its checksum are recorded
in the recipe this package was built from.
