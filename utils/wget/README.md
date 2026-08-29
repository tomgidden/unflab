# wget (unflab build)

GNU Wget retrieves files over HTTP, HTTPS and FTP — the workhorse for
scripted downloads, recursive mirroring, and resuming interrupted
transfers.

```sh
wget https://example.com/file.tar.gz
wget -c https://example.com/big.iso        # resume a partial download
wget -r -np -k https://example.com/docs/   # mirror a subtree
```

`man wget` has the rest.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install wget` pulls in **openssl@3, libidn2, libunistring, libpsl
and gettext** — five formulae to keep updated for one download tool.

This package has none of them. OpenSSL is compiled from source and linked
statically into the binary, and the other four features are configured
out. The result depends only on `libiconv`, `libz` and `libSystem`, all
of which macOS already provides.

HTTPS works out of the box: the bundled OpenSSL is configured to read CA
certificates from `/private/etc/ssl/cert.pem`, which is macOS's own
system bundle.

What's given up for that: no internationalised domain names (`--iri`), no
public-suffix cookie checking, and no translated messages. If you need
those, Homebrew's build has them.

Because OpenSSL is statically linked, security updates to it arrive by
updating this package rather than through your system — worth knowing if
you use `wget` against untrusted hosts.

## Upstream

- Home: https://www.gnu.org/software/wget/
- Version: 1.25.0
- Licence: GPL-3.0-or-later (see `LICENSE`)

GNU Wget is the Free Software Foundation's work. unflab only compiles and
packages it.
