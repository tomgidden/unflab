# ftp (unflab build)

The GNU FTP client, from GNU inetutils.

macOS shipped `/usr/bin/ftp` until High Sierra removed it. This puts a
working `ftp` back, as a single binary.

```sh
ftp ftp.example.com
ftp -n            # no auto-login; use .netrc or `user` manually
```

`man ftp` has the full command set. Credentials can go in `~/.netrc` as
usual — nothing is installed there for you.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install inetutils` installs about 23 executables to give you this
one, several of which shadow tools macOS already has. This package is
just `ftp`, built from the same GNU source configured to compile nothing
else.

It's also built `--without-idn`, which drops the libidn2 dependency
Homebrew's build carries (and with it libunistring and gettext). What
remains links only `libedit` and `libSystem`, both already in
`/usr/lib` — so there is nothing else to install.

If you also want `telnet`, that's a separate package from the same
source.

## Upstream

- Home: https://www.gnu.org/software/inetutils/
- Version: 2.8
- Licence: GPL-3.0-or-later (see `LICENSE`)

GNU inetutils is the Free Software Foundation's work. unflab only
compiles and packages it.
