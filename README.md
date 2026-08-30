# unflab

Small, self-contained macOS command-line tools. One download each, no
package manager, and nothing installed that the tool doesn't actually
need.

```sh
curl -fsSL https://tomgidden.github.io/unflab/get | sh -s -- tree
```

That installs `tree` into `~/.local/bin`. Several at once works too:

```sh
curl -fsSL https://tomgidden.github.io/unflab/get | sh -s -- wget jq tree
```

## The test this project has to pass

> On a freshly-installed Mac, open Terminal, run one `curl … | sh` line,
> and end up with a working tool — with nothing on the machine beyond
> what landed in `~/.local/bin`.

No Homebrew. No Xcode. No runtime dependencies. If a package can't do
that, it isn't finished.

## Why

Wanting one small tool and getting a dependency tree is the normal
experience:

- `brew install poppler`, to extract text from a PDF, brings **cairo,
  glib, nss, nspr, gpgme, fontconfig, freetype, libtiff, openjpeg,
  little-cms2** and 13 binaries.
- `brew install gnuplot` brings **the entire Qt stack** — qtbase,
  qt5compat, qtsvg — plus cairo, pango, glib, lua and harfbuzz.
- `brew install bloaty`, a tool for measuring binary size, brings
  **abseil, protobuf, capstone and re2**.
- `brew install inetutils`, because macOS removed `ftp` and `telnet`,
  installs about 23 executables.

None of that is Homebrew's fault — a formula has to serve every build of
a package. But when you want one tool, for one job, it's a lot of
machinery to acquire and keep updated.

## What's here

| | |
|---|---|
| **Escaping a dependency tree** | `wget` (drops openssl@3, libidn2, libunistring, libpsl, gettext), `bloaty` (drops abseil, protobuf, capstone, re2), `rdfind` (drops nettle and gmp), `htop`, `pv` |
| **One binary from a suite** | `ftp` and `telnet` (brew installs ~23 executables for these two), and the GNU **coreutils** individually — `gtimeout` on its own |
| **Just convenient** | `jq`, `tree`, `doggo`, `mlr`, `xmlstarlet`, `webi` |

`curl … | sh -s -- <name>` for any of them.

Currently built for **Apple Silicon** only; Intel support is a
one-line change to the build matrix if it's wanted.

## What's in scope

A utility earns its place here on any one of three grounds:

1. **Dependency escape** — its formula pulls in libraries the tool never
   touches at run time. Static-link them and they disappear.
2. **Suite extraction** — you want one binary out of twenty.
3. **Convenience** — not hard to install, but *here*, in the same shape
   as everything else, one line away.

Each package's README says which of these applies. A tool in group 3
isn't pretending to rescue you from anything.

## Why not webi?

[webinstall.dev](https://webinstall.dev) covers a lot of the same
ground: `curl … | sh`, installs into `~/.local`, no package manager, no
root. If you already use it, keep using it — this isn't an argument that
you picked wrong.

The differences are real, though, and they're mostly about scope:

- **webi downloads, unflab compiles.** webi fetches the binaries
  upstreams already publish. That's faster, covers far more tools, and
  needs no build infrastructure at all — but it can only offer what an
  upstream chose to ship, exactly as they built it. unflab compiles from
  source, so a package can be built *without* the dependencies its
  Homebrew formula would drag in. That's the whole point of the group-1
  packages: nobody publishes a `wget` with openssl statically linked in,
  so it has to be built.
- **webi is multi-platform, unflab is macOS-only.** macOS is the
  platform where this problem bites — no package manager in the box, and
  a userland old enough that `timeout` simply isn't there. On Linux the
  distro already solved it.
- **Different rosters.** webi leans towards web-dev tooling; unflab
  leans towards Unix plumbing, and is the only one of the two that will
  hand you a single `gtimeout`.
- **unflab checks what it ships.** Every binary is put through the
  `otool -L` gate in CI. webi is passing along someone else's artefact,
  so there's nothing equivalent for it to check.

None of that makes them mutually exclusive, and plenty of tools are
better got from webi. So it's packaged here too:

```sh
curl -fsSL https://unflab.app/get | sh -s -- webi
```

Which is a slightly absurd thing for one installer to do to another, but
it seemed friendlier than a paragraph explaining that we're not rivals.

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
it. Delete it if its presence offends you; nothing depends on it, and

```sh
curl -fsSL https://tomgidden.github.io/unflab/get | sh -s -- <utility>
```

does everything it does.

## Installing

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

```sh
make                  # list the recipes
make packages         # list every installable package
make tree             # what you can do with one
make tree.prereqs     # what building it needs
make tree.build       # fetch, verify, build, gate
make tree.install     # install what you just built
make tree.package     # make a release archive
```

Targets take either a package name or a recipe name, which matters where
one recipe builds several packages:

```sh
make ftp.install         # just ftp
make inetutils.install   # everything that recipe builds (ftp, telnet)
make coreutils.install   # the whole suite, if you really want it
make timeout.install     # builds coreutils, installs only timeout
```

Recipes live in `utils/<name>/`: `recipe.sh` pins the upstream source and
its SHA-256, and `manifest.tsv` says what gets installed where. Building
without a pinned checksum is refused.

`make <util>.prereqs` will tell you what's missing, but won't install a
large toolchain behind your back — needing one to build a 50KB binary
would rather defeat the point.

## How CI works

Each recipe builds in its own job, in parallel, so a broken recipe fails
alone instead of aborting a serial run and hiding the state of every
recipe after it. The matrix is generated from `utils/`, so adding a
recipe needs no CI changes. Branch protection can require the single
"All recipes built" check.

Every job runs the `otool -L` gate on what it built, again on what it
packaged, then installs the package into a throwaway HOME with only
`/usr/bin:/bin` on `PATH` and runs it. Nothing is released that hasn't
been installed and executed with no Homebrew in sight.

**Intel builds are currently disabled** to halve runner cost — releases
are Apple Silicon only for now. Everything downstream is arch-agnostic;
re-enabling means uncommenting one matrix entry in `build.yml` and
`release.yml`.

## Licence

This repository's own code — the recipes, the installer, the workflows —
is MIT (see `LICENSE`).

Every utility it builds stays under its own upstream licence, shipped
verbatim inside the package. `unflab` compiles and packages other
people's software; it doesn't relicense it. Each recipe records the exact
source URL, version and checksum it was built from.
