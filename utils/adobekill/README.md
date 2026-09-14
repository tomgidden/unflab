# adobekill (unflab build)

`adobekill` kills off all Adobe Creative Cloud jobs

This is a standalone build for macOS: one script, no dependencies (except,
perhaps Adobe Creative Cloud...), not even a repo.

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

- Home: https://gist.github.com/tomgidden/6a9f083988f7d4505d4e38674d416c04
- Source: https://gist.github.com/tomgidden/6a9f083988f7d4505d4e38674d416c04
- Version: 1
- Licence: MIT (see `LICENSE`)
