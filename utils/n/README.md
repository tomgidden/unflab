# n (unflab build)

`n` installs Node.js and switches between versions of it. It's a single
bash script: no daemon, no shims, nothing added to your shell startup.

```sh
export N_PREFIX="$HOME/.local"   # see below
n lts                            # install and use the current LTS
n latest                         # or the newest release
n 22                             # or the newest 22.x
n                                # pick from the installed versions
n rm 20.11.0                     # remove one
```

`n --help` has the rest.

## Where Node goes

By default `n` installs Node under `/usr/local`, which needs `sudo`.
Setting `N_PREFIX` to the directory above the one unflab installed into
puts it under `~/.local` instead: `node`, `npm` and `npx` in
`~/.local/bin`, and `n`'s cache of downloaded versions in `~/.local/n`.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

Uninstalling `n` leaves any Node it installed. `n uninstall` removes
that first.

## About this build

The script exactly as upstream ships it. Upstream's own one-line install
is `curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n`,
which is what `unflab node` runs as a one-off.

## Upstream

- Source: https://github.com/tj/n
- Version: 10.2.0
- Licence: MIT (see `LICENSE`)

`n` is TJ Holowaychuk's work, maintained by its contributors. unflab
only packages it.
