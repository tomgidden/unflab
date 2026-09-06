# tmux (unflab build)

tmux is a terminal multiplexer: it keeps shells running inside a server
process, so sessions survive a closed terminal or a dropped SSH
connection, and lets one terminal show several of them at once.

```sh
# Start a named session
tmux new -s work

# Detach with C-b d, then later, from anywhere:
tmux attach -t work

# List what's running
tmux ls

# Run something detached and come back to it
tmux new -d -s build 'make -j8'

# Split the current window
#   C-b %   vertical split
#   C-b "   horizontal split
#   C-b o   move between panes
#   C-b [   scrollback (q to leave)
```

The prefix key is `C-b` by default. `man tmux` is long but complete; the
first thing most people change is the prefix, in `~/.config/tmux/tmux.conf`
or `~/.tmux.conf`:

```
set -g prefix C-a
unbind C-b
bind C-a send-prefix
```

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install tmux` pulls in **libevent**, **ncurses**, **utf8proc** and
**jemalloc**. This package installs one binary and needs none of them.

Three are compiled from source and linked statically — libevent 2.1.13,
utf8proc 2.11.3 and jemalloc 5.3.1. The fourth, ncurses, macOS already
provides: `/usr/lib/libncurses.5.4.dylib`, which despite the version in
its filename reports itself as ncurses 6.0.

`otool -L` on the shipped binary shows only `libncurses`, `libSystem` and
`libresolv` — all from `/usr/lib`.

**jemalloc is not a performance tweak here.** tmux 3.7c's own configure
refuses to build on macOS without an explicit decision about it, because
macOS `calloc(3)` does not reliably zero allocations (tmux issue 5385);
"build with jemalloc on macOS" is the first entry in the 3.7c changelog.
This build enables it, so tmux gets the allocator upstream now expects on
this platform. It is linked statically and registers itself as a malloc
zone, which is how jemalloc is designed to work on macOS.

**utf8proc** supplies Unicode character widths independently of the C
library's locale-sensitive `wcwidth(3)` — this is what upstream does by
default on macOS, and it is what keeps wide characters (CJK, emoji) from
misaligning a status line.

Nothing is given up for any of this: it is the same tmux, with the same
features, built the way upstream recommends for this platform.
