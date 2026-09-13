# fd (unflab build)

`fd` is a friendlier `find`. It searches by regex against the filename
rather than by predicate against the whole path, skips hidden files and
anything your `.gitignore` excludes unless told otherwise, and walks
directories in parallel.

```sh
fd report                  # anything with "report" in the name
fd -e pdf                  # by extension
fd -H -I secret            # include hidden and ignored files
fd -x wc -l                # run a command per result
```

`man fd` is the full reference; `fd --help` covers the flags.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

macOS ships `find`, and this does not replace or shadow it — `find`
keeps working exactly as before.

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

Upstream also publishes prebuilt macOS binaries; this package exists so
`fd` installs the same way as everything else here, not because it was
hard to get.

## Upstream

- Home: https://github.com/sharkdp/fd
- Source: https://github.com/sharkdp/fd
- Version: 10.5.0
- Licence: MIT OR Apache-2.0 (your choice; both ship)
