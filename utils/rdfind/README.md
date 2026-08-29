# rdfind (unflab build)

`rdfind` finds duplicate files across directories and can replace the
duplicates with hard links or symlinks, or delete them — useful for
reclaiming space without losing anything.

```sh
rdfind -dryrun true ~/Downloads       # report only, change nothing
rdfind -makehardlinks true ~/Photos   # replace duplicates with hard links
rdfind -deleteduplicates true ~/tmp   # delete them outright
```

Always run with `-dryrun true` first — it writes a `results.txt` showing
exactly what it would do.

`man rdfind` has the rest.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install rdfind` brings **nettle**, which in turn brings **gmp** —
three formulae for one small deduplication tool.

This package has neither. nettle is built from source with public-key
support disabled and linked statically. That's what removes gmp: gmp is
needed only by `libhogweed`, nettle's public-key half, and `rdfind` uses
nothing but its hash functions. The binary links only `libc++` and
`libSystem`, both already part of macOS.

## Upstream

- Home: https://rdfind.pauldreik.se/
- Version: 1.8.0
- Licence: GPL-2.0-or-later (see `LICENSE`)

`rdfind` is Paul Dreik's work. unflab only compiles and packages it.
