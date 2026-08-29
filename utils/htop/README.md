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

`brew install htop` brings its own ncurses. macOS already ships one in
`/usr/lib`, so this build uses that and depends on nothing extra — the
binary links only `libncurses` and `libSystem`, plus the IOKit and
CoreFoundation frameworks macOS provides.

The trade: macOS's ncurses is version 5.4 and has no wide-character
library, so this is built `--disable-unicode`. htop draws its meters with
ASCII rather than unicode box characters, and is otherwise identical.
Enabling unicode would mean statically linking a modern ncurses 6.x —
several megabytes of dependency for prettier bar charts.

## Upstream

- Home: https://htop.dev/
- Source: https://github.com/htop-dev/htop
- Version: 3.5.3
- Licence: GPL-2.0-or-later (see `LICENSE`)

htop is Hisham Muhammad's work, now maintained by the htop team. unflab
only compiles and packages it.
