# btop (unflab build)

`btop` is a resource monitor — processes, CPU, memory, disks and network
in a full-colour terminal interface, with mouse support and a process
tree you can sort, filter and kill from.

```sh
btop                  # just run it
btop --preset 1       # start on a saved layout
btop --tty_on         # force TTY mode on a plain terminal
```

Press `Esc` or `F2` for the options menu, `h` for help, `q` to quit.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

The one package here that isn't a single file: btop ships 41 colour
themes, installed alongside the binary under `share/btop/themes`.

That works under any prefix because btop looks for its themes relative
to its own binary — `../share/btop/themes` — before falling back to
`/usr/local` and `/usr`. So an install into `~/.local/bin` finds them
with no environment variable and no compiled-in path. Themes you write
yourself go in `~/.config/btop/themes`, which is searched separately and
is untouched by `--uninstall`.

Built from the upstream Makefile with Xcode's `clang++`. It links
against nothing outside `/usr/lib` and `/System/`.

No man page: upstream writes it in Markdown and converts it with
`lowdown` at build time. Pulling in a Markdown-to-roff converter to ship
one page is the kind of thing this project exists to avoid — `btop
--help` covers the flags, and the interface documents itself.

## Upstream

- Home: https://github.com/aristocratos/btop
- Version: 1.4.7
- Licence: Apache-2.0 (see `LICENSE`)

`btop` is Jakob P. Liljenberg's work. unflab only compiles and packages
it.
