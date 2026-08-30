# unflab

Small, self-contained macOS command-line tools. One download each, no
package manager, and nothing installed that the tool doesn't actually
need.

```sh
curl -fsSL https://unflab.app/get | sh -s -- tree
```

That installs `tree` into `~/.local/bin`. Several at once works too:

```sh
curl -fsSL https://unflab.app/get | sh -s -- wget jq tree
```

No Homebrew. No Xcode. No runtime dependencies. All packages need to
work on a modern, freshly-installed Mac.

## Why

Wanting one small tool and getting a dependency tree is the normal
experience:

- `brew install poppler`, to extract text from a PDF, brings **cairo,
  glib, nss, nspr, gpgme, fontconfig, freetype, libtiff, openjpeg,
  little-cms2** and 13 binaries.
- `brew install gnuplot` brings **the entire Qt stack** — qtbase,
  qt5compat, qtsvg — plus cairo, pango, glib, lua and harfbuzz.
- `brew install bloaty`, a tool for measuring binary size, brings
  **abseil, protobuf, capstone and re2** and requires the whole **cmake**
  build toolchain.
- `brew install inetutils`, because macOS removed `ftp` and `telnet`,
  installs about 23 executables.

None of that is Homebrew's fault — a formula has to serve every build of
a package. But when you want one tool, for one job, it's a lot of
machinery to acquire and keep updated.

Currently built for **Apple Silicon** only; as Intel support is deprecated
the build platforms have started to diverge, meaning that they're becoming
different targets.

## What about _webi_?

[webinstall.dev](https://webinstall.dev) covers a lot of the same
ground: `curl … | sh`, installs into `~/.local`, no package manager, no
root. If you already use it, keep using it — this isn't an argument that
you picked wrong.  _webi_ is _great_.

The differences are real, though, and they're mostly about scope:

- **webi downloads, _unflab_ compiles.**

- **webi is multi-platform, _unflab_ is macOS-only.**

- **Different rosters.** webi leans towards web-dev tooling; unflab
  leans towards Unix plumbing.

- **unflab checks what it ships.** _unflab_ puts every binary through the
  `otool -L` gate in CI, whereas _webi_ uses the official binaries.

The upshot is that _unflab_ can provide a specific utility from a larger
package.  In fact, that's the reason for all this: I needed `timeout` (a.k.a
`gtimeout`) from _GNU coreutils_, but didn't want to install the whole thing.

None of that makes them mutually exclusive, and I'd recommend using _webi_
for most packages, especially larger ones where you actually want the larger
suite. So it's packaged here too:

```sh
curl -fsSL https://unflab.app/get | sh -s -- webi
```

...just so you don't have to additionally look up [webinstall.dev](https://webinstall.dev)
for the command.

## What "self-contained" means

macOS has no static libSystem and doesn't support fully-static
executables, so nothing here claims to be statically linked. What every
binary *is* checked for, in CI, before release:

> it links against nothing outside `/usr/lib` and `/System/`.

That's `scripts/verify.sh`, and a failure fails the build. Homebrew may
be used on the build machine to get a static library or a tool; the gate
is what proves none of it survived into what you download.

## The `unflab` command

Installing anything also drops a small `unflab` script beside it, so you
don't have to find that curl line again:

```sh
unflab jq mlr                 # install more
unflab --uninstall ftp        # remove one
unflab --purge doggo          # remove it and its config files
unflab --list                 # see what there is
```

It is not a package manager and doesn't want to become one. It keeps no
database, records no state, and updates nothing behind your back — it
re-runs the same one-liner you started with, so you don't have to retype
it. 

Delete it if its presence offends you; nothing depends on it, and

```sh
curl -fsSL https://unflab.app/get | sh -s -- <utility>
```

does everything it does.

---

## Installing manually

Each package ships its own `install.sh`. The `curl | sh` line above runs
it for you; a manual download runs the same script, the same way:

```sh
tar xzf unflab-tree-2.3.2-arm64-apple-darwin.tar.gz
./install.sh                        # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall            # remove it
./install.sh --purge                # and its config files
```

It won't touch your shell config without asking, it won't overwrite a
command you already have, and it won't remove a file it didn't install.

## Building it yourself

The intention is that you just download the GitHub CI binaries. After
all, keeping your Mac clean of all that build nonsense is one of the
primary goals... GitHub's CI runners have all the tools necessary to
build these utilities so you don't have to.

However, if you want to use this repo for your own builds; add to it (yes
please); or are just suspicious (fair enough), then:

```sh
make                  # list the recipes
make packages         # list every installable package
make wget             # what you can do with one
make wget.prereqs     # what building it needs
make wget.build       # fetch, verify, build, gate
make wget.install     # install what you just built
make wget.package     # make a release archive
```

Targets take either a package name or a recipe name, which matters where
one recipe builds several packages:

```sh
make ftp.install         # just ftp
make inetutils.install   # everything that recipe builds (ftp, telnet)
make coreutils.install   # the whole suite, if you really want it
make timeout.install     # builds coreutils, installs only timeout
```

Recipes live in `utils/‹name›/`: `recipe.sh` pins the upstream source and
its SHA-256, and `manifest.tsv` says what gets installed where. Building
without a pinned checksum is refused.

`make ‹util›.prereqs` will tell you what's missing, but won't install a
large toolchain behind your back — needing one to build a 50KB binary
would rather defeat the point.

## Licence

This repository's own code — the recipes, the installer, the workflows —
is MIT (see `LICENSE`).

Every utility it builds stays under its own upstream licence, shipped
verbatim inside the package. `unflab` compiles and packages other
people's software; it doesn't relicense it. Each recipe records the exact
source URL, version and checksum it was built from.
