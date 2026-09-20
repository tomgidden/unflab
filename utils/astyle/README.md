# astyle (unflab build)

Artistic Style: reformats C, C++, C#, Java and Objective-C source.

```sh
# In place, with a backup of each original as .orig
astyle --style=allman src/*.c

# To stdout, no files touched
astyle --style=kr < input.c

# No backups, recursive
astyle --style=google --suffix=none --recursive 'src/*.cpp'
```

Styles are named on the command line — `allman`, `kr`, `stroustrup`,
`gnu`, `linux`, `google`, `mozilla`, `webkit`, `ratliff`, `horstmann`,
`pico`, `lisp` and more — with no config file needed. Individual
switches (`--indent=tab`, `--pad-oper`, `--break-blocks`,
`--align-pointer=name`) layer on top, and a set of them can live in a
file passed with `--options=`.

`man astyle` has the full list, which is long.

**It rewrites files in place by default**, leaving `.orig` copies
beside them. `--suffix=none` drops the backups; `--dry-run` shows what
would change without writing.

Completions for bash, zsh and fish are installed. If your shell already
reads the standard completion directories they work straight away; zsh
needs `fpath` set before `compinit` runs.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

There is no dependency story — Homebrew's `astyle` has no runtime
dependencies either. This is packaged so it installs the same way as
everything else. The binary links `libc++` and `libSystem`, both part
of macOS.

It's also worth being straight about the overlap, because it's real.
macOS already has two formatters. `/usr/bin/indent` is a BSD C
formatter, narrow enough not to matter much — it's C only, and it
mangles a C++ class body. `clang-format` is the serious one: it ships
with the Command Line Tools, so it's on any machine that has `cc`,
though not on `PATH`:

```sh
/Library/Developer/CommandLineTools/usr/bin/clang-format --style=GNU
```

It handles C, C++, Java and C#, and takes named styles without a config
file. If that suits you, you don't need this.

The case for astyle is preference rather than capability: a different
set of brace styles, finer-grained control over padding and one-liners,
and twenty years of scripts and habits built around its flags. Worth
having if it's the formatter you want; not something missing from the
machine without it.

## Upstream

- Home: https://astyle.sourceforge.net/
- Version: 3.6.18
- Licence: MIT (see `LICENSE`)

Artistic Style is Jim Pattee, Tal Davidson and contributors' work.
unflab only compiles and packages it.
