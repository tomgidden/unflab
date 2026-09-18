# htop (unflab build)

`htop` is an interactive process viewer — a far friendlier `top`, with
per-core CPU meters, a process tree, searching, and killing processes
without typing PIDs.

```sh
htop
htop -u $USER        # only your processes
htop -t              # start in tree view
```

`man htop` has the rest, and `F1` inside htop lists the keys.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install htop` brings its own ncurses. This build compiles ncurses
6.6 from source and links it statically, so the binary needs no shared
library beyond `libSystem` and the IOKit and CoreFoundation frameworks
macOS provides — not even macOS's own `libncurses`.

That static ncurses is also what makes unicode work. macOS ships only a
narrow ncurses with no `libncursesw`, and htop's unicode support needs
one; earlier versions of this package were built `--disable-unicode` for
that reason. Now the tree view draws with proper box-drawing characters
(`│ ├ └ ─`) and the sort column with `△`/`▽`, rather than `|`, `+` and
`-`. The CPU and memory meters use `|` either way.

Terminal descriptions come from macOS's own database at
`/usr/share/terminfo`; nothing is installed to duplicate it.

## Upstream

- Home: https://htop.dev/
- Source: https://github.com/htop-dev/htop
- Version: 3.5.3
- Licence: GPL-2.0-or-later (see `LICENSE`)

htop is Hisham Muhammad's work, now maintained by the htop team. unflab
only compiles and packages it.
