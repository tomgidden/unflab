# micro (unflab build)

`micro` is a terminal text editor that uses the keys you already know.
`Ctrl-S` saves, `Ctrl-Q` quits, `Ctrl-Z` undoes, `Ctrl-F` finds,
`Ctrl-C`/`Ctrl-V` copy and paste. There is no mode to enter and nothing
to learn before the first edit.

```sh
micro file.txt                  # edit a file
micro +42 file.txt              # open at line 42
micro                           # scratch buffer
```

Syntax highlighting, mouse support, multiple cursors (`Alt-N` spawns one
at the next occurrence) and split panes all work out of the box.
`Ctrl-E` opens a command prompt — `Ctrl-E` then `help defaultkeys` lists
every binding.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

One binary, linked against nothing but `libSystem`, built with
`CGO_ENABLED=0`.

Everything micro needs at run time is compiled into it: 39 syntax
definitions, the colour schemes, the help files and the built-in
plugins are all embedded in the executable. There is no `share/micro`
directory and nothing to install alongside it.

Configuration is optional and lives in `~/.config/micro/` if you want
it — `settings.json` for options, `bindings.json` for keys. micro
creates that directory itself on first run; nothing here writes to it.

This build doesn't use upstream's `Makefile`, which expects a git
checkout: it derives the version from `git describe` and on macOS
forces a CGO build to embed an `Info.plist`. Building `./cmd/micro`
directly gives a pure-Go binary with the version set explicitly, so
`micro -version` reports 2.0.15 as it should.

The `-plugin install` command downloads plugins from upstream's plugin
channel at run time. That is micro's own feature and it works here, but
anything it fetches is not an unflab build and hasn't been through this
project's gate.

Upstream publishes prebuilt macOS binaries too — this package exists so
`micro` installs the same way as everything else here.

## Upstream

- Home: https://micro-editor.github.io/
- Source: https://github.com/zyedidia/micro
- Version: 2.0.15
- Licence: MIT (see `LICENSE`; bundled Go dependencies are listed in
  `LICENSE-THIRD-PARTY`)

`micro` is Zachary Yedidia's work. unflab only compiles and packages it.
