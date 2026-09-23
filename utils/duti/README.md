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

## dutis, included

[`dutis`](https://github.com/tsonglew/dutis) is installed alongside
`duti`. It's a separate, actively developed Rust tool built on top of
it: an interactive picker, a declarative config with
`plan`/`diff`/`apply`, snapshots and rollback, and drift detection.

```sh
dutis                      # interactive mode
dutis get txt              # what opens .txt files?
dutis doctor               # check it can find duti
dutis plan dutis.toml      # what a config would change
```

It reads Launch Services directly, but it makes every change by
running `duti`, which is why both come in one package here rather than
dutis needing a separate install first. `dutis --help` and each
command's `--help` are its documentation; there's no man page.

`dutis-event-http`, an optional helper that forwards dutis's events to
an HTTPS endpoint, is included too, as it is in upstream's own
packaging.

One limitation belongs to dutis itself: `dutis launch-agent` sets up a
background watcher under launchd, and launchd's `PATH` doesn't include
`~/.local/bin`. A watcher that only *reports* drift is fine, but one
that tries to *fix* it won't find `duti`. The same is true of
Homebrew's `/opt/homebrew/bin`.

## Upstream

- duti: https://github.com/moretension/duti/, version 1.5.4, public
  domain (see `LICENSE`)
- dutis: https://github.com/tsonglew/dutis, version 2.24.0, MIT (see
  `LICENSE-dutis`)

duti is Andrew Mortensen's work, released into the public domain. dutis
is Tsonglew's. unflab only compiles and packages them.
