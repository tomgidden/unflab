# fzf (unflab build)

`fzf` is a general-purpose fuzzy finder. It reads lines on stdin, lets
you narrow them down interactively, and prints what you picked — which
makes it a filter you can put in the middle of anything.

```sh
vim "$(fzf)"                    # pick a file, open it
kill -9 "$(ps -ef | fzf | awk '{print $2}')"
git switch "$(git branch | fzf | tr -d ' *')"
```

`man fzf` is thorough and worth reading; `fzf --help` covers the flags.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Shell integration

The part most people mean by "fzf" — `Ctrl-R` to search shell history,
`Ctrl-T` to insert a file path, `**<TAB>` to complete one — is not in
the binary. It lives in shell scripts, and this package installs them
to `~/.local/share/fzf/` without enabling them.

That is deliberate: they rebind `Ctrl-R` and `Ctrl-T` in your shell, and
a package that silently took over two keybindings because you installed
it would be overstepping. Homebrew declines to auto-enable them for the
same reason. Switch them on by adding to your rc file:

```sh
# ~/.zshrc
source ~/.local/share/fzf/key-bindings.zsh
source ~/.local/share/fzf/completion.zsh

# ~/.bashrc
source ~/.local/share/fzf/key-bindings.bash
source ~/.local/share/fzf/completion.bash

# ~/.config/fish/config.fish
source ~/.local/share/fzf/key-bindings.fish
```

Installed under a different `--prefix`? The files are in
`<prefix>/../share/fzf/`.

For vim, `plugin/fzf.vim` ships as `~/.local/share/fzf/fzf.vim` and does
nothing until you add `set rtp+=~/.local/share/fzf` to your `.vimrc`.

## What else is in the package

- `fzf-tmux` — opens fzf in a tmux split rather than in place. A shell
  script, not a binary; needs `tmux` on your `PATH`.
- `fzf-preview.sh` — the preview helper upstream's examples and man page
  refer to by name.

Not shipped: upstream's `install`/`uninstall` scripts, which exist to
wire up a git-clone install and would fight this one, and the nushell
integration.

## About this build

Compiled with `CGO_ENABLED=0`, so it's a single self-contained binary
that links against nothing but macOS's own `libSystem` and `libresolv` —
no package manager, no runtime dependencies. Homebrew builds fzf with
cgo against the system ncurses; upstream's own release binaries don't,
and neither do we.

Upstream also publishes prebuilt macOS binaries; this package exists so
`fzf` installs the same way as everything else here, not because it was
hard to get.

## Upstream

- Home: https://junegunn.github.io/fzf/
- Source: https://github.com/junegunn/fzf
- Version: 0.74.4
- Licence: MIT
