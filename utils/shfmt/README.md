# shfmt (unflab build)

`shfmt` formats shell scripts — a `gofmt` for `sh`, `bash` and `mksh`.
It parses rather than pattern-matches, so it reformats reliably and
fails loudly on a syntax error instead of mangling the file.

```sh
shfmt -w script.sh              # format in place
shfmt -d script.sh              # show a diff instead
shfmt -i 2 -ci -w script.sh     # 2-space indent, indent switch cases
shfmt -l .                      # list files that need formatting
```

`shfmt --help` lists the formatting options; `-ln` picks the dialect
(`bash`, `posix`, `mksh`) when the shebang doesn't settle it.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

A single static binary built with `CGO_ENABLED=0`, so it links against
nothing but `libSystem`.

`shfmt --version` reports `(unknown)` in this build. It reads Go's build
info rather than a version string compiled in, and that's only populated
when building from a git tag or via `go install`. Building from a release
tarball leaves it unset, and no linker flag can fill it in. The version
you have is 3.14.0, recorded here and in the package metadata.

Upstream publishes prebuilt macOS binaries too — this package exists so
`shfmt` installs the same way as everything else here, not because it
was hard to get.

Only `shfmt` is packaged. The repository also contains `gosh`, which its
own source calls "a proof of concept shell"; that isn't something to
hand anyone as a tool.

## Upstream

- Home: https://github.com/mvdan/sh
- Version: 3.14.0
- Licence: BSD-3-Clause (see `LICENSE`)

`shfmt` is Daniel Martí's work. unflab only compiles and packages it.
