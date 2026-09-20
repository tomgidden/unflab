# duti (unflab build)

Sets the default application for a file type or URL scheme on macOS.

macOS gives you Finder's Get Info dialog and nothing else: one file type
at a time, by hand, with no way to script it or check it into a
dotfiles repo. `duti` is the command-line equivalent.

```sh
# What opens .txt files at the moment?
duti -x txt

# What handles this UTI?
duti -d public.html

# Set a default: bundle id, UTI, role
duti -s com.microsoft.VSCode public.plain-text all

# A URL scheme takes two arguments and no role
duti -s com.google.Chrome https

# Or apply a whole file of them
duti ~/.duti
```

The settings file is one `bundle-id  uti-or-extension  role` per line,
which is the reason most people install this — a machine's file
associations become something you can keep in version control and
re-apply after a rebuild.

Roles are `viewer`, `editor`, `shell` or `all`. `man duti` has the full
set, including `-l` to list handlers for a UTI.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

There is no dependency story here — Homebrew's `duti` has no runtime
dependencies either. This is packaged so it installs the same way as
everything else, and because macOS ships nothing equivalent.

What it does do better is newer macOS. Upstream stopped in 2018, and
its `configure` carries a hardcoded list of Darwin versions that
refuses to build on anything past macOS 10.13. Homebrew carries five
backported patches, each one appending another version to that list,
plus a further edit at install time because the patches keep falling
behind. This build takes the version check out instead and passes the
SDK explicitly, so it isn't waiting on anyone to patch it for the next
macOS.

Two small things upstream's release process would have filled in, which
a build straight from the git tag misses: `duti -V` reports the real
`1.5.4` here rather than `INTERNAL`, and the man page header shows the
release date rather than a literal `_DUTI_BUILD_DATE`.

The binary links `ApplicationServices`, `CoreFoundation` and
`CoreServices`, all part of macOS, so there is nothing else to install.

## See also: dutis

[`dutis`](https://github.com/tsonglew/dutis) is a separate, actively
developed Rust tool that wraps this one: an interactive picker, a
declarative config with `plan`/`diff`/`apply`, snapshots and rollback.
It shells out to `duti` for every change it makes, so `duti` has to be
installed first — with it missing, `dutis doctor` reports
`Changes ready: false` and only its read-only commands work.

It isn't packaged here, but it publishes a universal macOS binary with
each release, so it's a download away once `duti` is in place.

## Upstream

- Home: https://github.com/moretension/duti/
- Version: 1.5.4
- Licence: public domain (see `LICENSE`)

duti is Andrew Mortensen's work, released into the public domain.
unflab only compiles and packages it.
