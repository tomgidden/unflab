# expunge_googleupdate (unflab build)

`expunge_googleupdate` kills off pernicious Google Software Update (a.k.a. "keystone") jobs and agents

This is a standalone build for macOS: one script, no dependencies (except,
perhaps Google Chrome or similar...), not even a repo.

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

- Home: https://gist.github.com/tomgidden/6cfc0e2a3faa0300edd86e36c35a18f7
- Source: https://gist.github.com/tomgidden/6cfc0e2a3faa0300edd86e36c35a18f7
- Version: 1
- Licence: MIT (see `LICENSE`)
