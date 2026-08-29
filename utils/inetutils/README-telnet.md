# telnet (unflab build)

The GNU telnet client, from GNU inetutils.

macOS shipped `/usr/bin/telnet` until High Sierra removed it. This puts a
working `telnet` back, as a single binary.

```sh
telnet example.com
telnet example.com 25      # still the quickest way to poke at a service
```

`man telnet` has the full command set.

Note that telnet is unencrypted: fine for probing a port or talking to
something on your own network, not for logging into anything you care
about.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install inetutils` installs about 23 executables to give you this
one, several of which shadow tools macOS already has. This package is
just `telnet`, built from the same GNU source configured to compile
nothing else.

It's also built `--without-idn`, which drops the libidn2 dependency
Homebrew's build carries (and with it libunistring and gettext). What
remains links only `libncurses` and `libSystem`, both already in
`/usr/lib` — so there is nothing else to install.

If you also want `ftp`, that's a separate package from the same source.

## Upstream

- Home: https://www.gnu.org/software/inetutils/
- Version: 2.8
- Licence: GPL-3.0-or-later (see `LICENSE`)

GNU inetutils is the Free Software Foundation's work. unflab only
compiles and packages it.
