## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Names

The binary installs as `g`-prefixed — matching the convention Homebrew's
`coreutils` established, so `gls` and `gtimeout` mean the same thing
wherever you are.

The plain, unprefixed name is *also* linked, but only if nothing on your
machine already provides it. That's checked on your machine at install
time, not assumed when the package was built. In practice:

- `ls`, `cp`, `date`, `chmod` and most others: macOS already has these,
  so you get `gls`, `gcp` and so on, and nothing is shadowed.
- `timeout`, `shuf`, `nproc`, `factor`, `tac`, `b2sum` and a dozen more:
  macOS has no equivalent, so you get both the plain name *and* the `g`
  name.

Pass `--no-plain` if you only ever want the `g` name.

## About this build

One binary, its man page, and nothing else — built from the GNU coreutils
release tarball and linked only against libraries macOS itself provides.
`brew install coreutils` gives you all 105 as a single unit; this is
whichever one you actually wanted.

Built `--disable-nls`: coreutils' translation catalogues are
whole-project rather than per-utility, so shipping translated messages
would mean bundling every language's catalogue for the entire suite
inside each individual package.

## Upstream

- Home: https://www.gnu.org/software/coreutils/
- Version: 9.11
- Licence: GPL-3.0-or-later (see `LICENSE`)

GNU coreutils is the Free Software Foundation's work. unflab only
compiles and packages it.
