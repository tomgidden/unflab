# mlr / miller (unflab build)

Miller (`mlr`) does for CSV, TSV and JSON what `awk`, `sed`, `cut`,
`join` and `sort` do for plain text — but name-aware, so you work with
columns by name rather than by position.

```sh
mlr --icsv --opprint cat data.csv           # pretty-print a CSV
mlr --icsv --ojson head -n 5 data.csv       # CSV to JSON
mlr --csv filter '$quantity > 10' data.csv
mlr --csv sort -f name then stats1 -a sum,mean -f price -g category data.csv
```

`man mlr` and https://miller.readthedocs.io/ have the full command set.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

A single Go binary built with `CGO_ENABLED=0`, so it links only
`libSystem` — no package manager, no runtime dependencies.

The command is `mlr`, not `miller`; that's upstream's name and predates
the Go rewrite.

Upstream publishes prebuilt macOS binaries too. This package exists so
`mlr` installs the same way as everything else here.

## Upstream

- Home: https://miller.readthedocs.io/
- Source: https://github.com/johnkerl/miller
- Version: 6.15.0
- Licence: BSD-2-Clause (see `LICENSE`)

Miller is John Kerl's work. unflab only compiles and packages it.
