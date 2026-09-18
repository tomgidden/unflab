# nano (unflab build)

GNU nano, the small modeless editor that tells you its keys along the
bottom of the screen. `Ctrl-O` writes, `Ctrl-X` exits, `Ctrl-W`
searches, `Ctrl-K`/`Ctrl-U` cut and paste.

```sh
gnunano file.txt                # edit a file
gnunano +42 file.txt            # open at line 42
gnunano -Y sh script.sh         # force a syntax
```

## The name

macOS has a `nano` already, and it isn't this one: `/usr/bin/nano` is a
symlink to `/usr/bin/pico`, the UW PICO editor that GNU nano was
written as a free replacement for. It doesn't read a nanorc, doesn't
highlight syntax, and doesn't handle UTF-8.

So this installs as **`gnunano`**, following the convention macOS
itself uses for `gnumake`, and also symlinks `nano` to it in the same
directory. Which one wins when you type `nano` depends on PATH order —
the post-install notes explain how to check, and setting `$EDITOR` and
`$VISUAL` to `gnunano` sidesteps the question entirely.

`./install.sh --no-plain` skips the `nano` symlink and installs only
`gnunano`.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Syntax highlighting

39 syntax definitions are installed to `share/nano/`, but nano doesn't
read them until a nanorc says so. The shipped `sample.nanorc` is
upstream's fully-commented example:

```sh
cp ~/.local/share/nano/sample.nanorc ~/.local/share/nano/nanorc
ln -s ~/.local/share/nano/nanorc ~/.nanorc
```

Then uncomment the `include .../*.nanorc` line near the bottom.
`man nanorc` documents every option.

## About this build

One binary depending on nothing but `libSystem` — not even the system's
curses.

That last part is the interesting bit. macOS ships ncurses, but only
the narrow build: there is no `libncursesw`, and the SDK's `curses.h`
doesn't declare the wide-character functions. A nano configured against
it builds fine and then mangles every non-ASCII character. Rather than
ship that, this build compiles ncurses 6.6 from source with
`--enable-widec` and links it statically, so UTF-8 works and there is
still no shared library to conflict with anything.

Terminal descriptions come from macOS's own database at
`/usr/share/terminfo`, with six common terminals compiled in as
fallbacks. Nothing is installed to duplicate what the OS already has.

Built with `--disable-nls` (drops the gettext dependency; the interface
is English) and `--disable-libmagic` (syntax is matched on filename and
first line, which is what the shipped syntaxes use anyway).

`rnano`, the restricted mode for giving someone an editor and nothing
else, isn't packaged — it's a multi-user-server tool.

## Upstream

- Home: https://www.nano-editor.org/
- Version: 9.2
- Licence: GPL-3.0-or-later (see `LICENSE`)

The source tarball is verified against upstream's OpenPGP signature,
whose key is in the GNU keyring.

`nano` is the work of the GNU nano contributors. unflab only compiles
and packages it.
