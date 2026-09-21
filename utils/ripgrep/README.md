# ripgrep (unflab build)

_ripgrep_ (`rg`) is a line-oriented search tool that recursively searches the
current directory for a regex pattern. By default, ripgrep will respect gitignore
rules and automatically skip hidden files/directories and binary files. (To
disable all automatic filtering by default, use `rg -uuu`.) ripgrep has first
class support on Windows, macOS and Linux, with binary downloads available for
every release. ripgrep is similar to other popular search tools like The Silver
Searcher, ack and grep.

`man rg` is the full reference; `rg --help` covers the flags.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Shell completions

Completions for zsh, bash and fish are installed to each shell's
conventional directory. Nothing is sourced and no rc file is edited,
so whether they take effect depends on your shell already looking
there:

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

  The order is the part people get wrong: `compinit` only reads
  directories that were in `fpath` when it ran, so appending
  afterwards silently does nothing. `compinit` does notice a newly
  populated directory and rebuilds its cache on its own, so there is
  no need to delete `~/.zcompdump`.

Installed under a different `--prefix`? Substitute `<prefix>/../share`
for `~/.local/share` throughout.

That setup is per-shell, not per-package: once zsh is looking in
`site-functions`, every unflab package that ships a completion works.

## About this build

Pure Rust, statically linked apart from macOS's own system libraries —
no package manager, no runtime dependencies. Upstream disables
jemalloc on macOS, so unlike some Rust builds there is no allocator
library to link against.

Built with PCRE2 support (`rg --pcre2` / `-P`), statically linked the
same way as everything else here — matching upstream's own release
binaries. This enables PCRE-specific regex syntax such as
backreferences and lookaround that ripgrep's default Rust-regex engine
doesn't support.

Upstream also publishes prebuilt macOS binaries; this package exists so
`rg` installs the same way as everything else here, not because it was
hard to get.

## Upstream

- Home: https://github.com/BurntSushi/ripgrep
- Source: https://github.com/BurntSushi/ripgrep
- Version: 15.2.0
- Licence: MIT OR UNLICENSE (your choice; both ship)
