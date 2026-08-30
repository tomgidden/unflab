# webi (unflab build)

`webi` is the [webinstall.dev](https://webinstall.dev) installer — it
fetches developer tools from their official upstream releases, unpacks
them into `~/.local`, and puts them on your `PATH`.

```sh
webi node@lts
webi shfmt rg jq
webi --help
```

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

The odd one out: this package ships no compiled binary. `webi` is a
single POSIX shell script, so there is nothing to build — unflab just
pins a release, verifies its checksum, and packages the one file.

It still passes the same test as everything else here. The only tools it
requires at runtime are `curl`, `tar`, `shasum` and `unzip`, all of which
stock macOS already has; the rest (`git`, `jq`, `zstd`, `pkgutil`) are
probed for and used only if present.

Note that `webi` updates itself: run `webi webi` and it will replace the
copy installed here with whatever webinstall.dev currently serves. That's
by design upstream, and worth knowing if you'd rather the pinned version
stayed pinned.

## Why is this here?

webi solves a neighbouring problem to unflab's, and solves it well.
Where unflab compiles from source for macOS only, webi downloads
upstreams' own prebuilt binaries for several platforms, with a lean
towards web-dev tooling. Neither is a replacement for the other, and for
plenty of tools webi is simply the better answer — so it seemed only
right to make it one `curl … | sh` away, in the same idiom as everything
else. See "Why not webi?" in unflab's README.

## Upstream

- Home: https://webinstall.dev
- Source: https://github.com/webinstall/webi-installers
- Version: 1.3.2 (the script reports its own version, currently v1.2.8)
- Licence: MPL-2.0 (see `LICENSE`)

`webi` is AJ ONeal's work. unflab only packages it.
