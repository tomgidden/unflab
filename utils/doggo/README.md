# doggo (unflab build)

`doggo` is a DNS client for the command line — a friendlier `dig`, with
colour-coded output, JSON for scripting, and support for DoH, DoT, DoQ
and DNSCrypt as well as plain UDP/TCP.

```sh
doggo example.com
doggo MX example.com @1.1.1.1
doggo example.com --json
```

Run `doggo --help` for the full set of options. There's no man page —
upstream doesn't ship one.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Configuration

`doggo` needs no configuration to work. A sample config is included as
`doggo.toml.sample` (installed alongside this README under
`share/doc/doggo/`), but nothing is written to `~/.config` unless you
choose to put it there:

```sh
mkdir -p ~/.config/doggo
cp ~/.local/share/doc/doggo/doggo.toml.sample ~/.config/doggo/doggo.toml
```

## Shell completions

Completions for zsh, bash and fish are installed to each shell's conventional
directory. Nothing is sourced and no rc file is edited, so whether they
take effect depends on your shell already looking there:

- **bash** — `~/.local/share/bash-completion/completions`, found
  automatically by bash-completion 2.x.
- **fish** — `~/.local/share/fish/vendor_completions.d`, found
  automatically.
- **zsh** — `~/.local/share/zsh/site-functions`, which is *not* in the
  default `fpath`. Add it in `~/.zshrc`, above the line that runs
  `compinit`:

  ```sh
  fpath=(~/.local/share/zsh/site-functions $fpath)
  autoload -Uz compinit && compinit
  ```

  Appending to `fpath` after `compinit` has run silently does nothing —
  that is the mistake people actually make.

## About this build

Compiled with `CGO_ENABLED=0`, so it's a single self-contained binary
that links against nothing but macOS's own `libSystem` — no package
manager, no runtime dependencies.

Upstream also publishes prebuilt macOS binaries; this package exists so
`doggo` installs the same way as everything else here, not because it was
hard to get.

## Upstream

- Home: https://doggo.mrkaran.dev/
- Source: https://github.com/mr-karan/doggo
- Version: 1.4.0
- Licence: GPL-3.0-or-later (see `LICENSE`)

`doggo` is Karan Sharma's work. unflab only compiles and packages it.
