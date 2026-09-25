# glow (unflab build)

`glow` renders markdown in the terminal: headings, tables, code blocks
and links, styled to fit a dark or light background. Give it a file, a
directory to browse, a URL, or `-` for standard input.

```sh
glow README.md
glow -p README.md          # through a pager
curl -fsSL https://example.com/notes.md | glow -
glow                       # browse the markdown in this directory
```

Run `glow --help` or `man glow` for the full set of options.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Configuration

Nothing is written at install. `glow config` creates and opens a config
file under `~/.config/glow/` if you want one.

## Shell completions

Completions for zsh, bash and fish are installed to each shell's
conventional directory. Nothing is sourced and no rc file is edited:

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

  Appending to `fpath` after `compinit` has run silently does nothing.

## About this build

Compiled with `CGO_ENABLED=0` from upstream's source release, whose
checksum is verified against the `checksums.txt` upstream publishes
beside it. A single binary linking nothing but macOS's own `libSystem`.
The man page and completions are generated from that binary.

Upstream also publishes prebuilt macOS binaries; this package exists so
`glow` installs the same way as everything else here.

## Upstream

- Source: https://github.com/charmbracelet/glow
- Version: 3.0.0
- Licence: MIT (see `LICENSE`)

`glow` is Charm's work. unflab only compiles and packages it.
