# typst (unflab build)

`typst` is a markup-based typesetting system — the same job as LaTeX,
with a syntax closer to Markdown, a real scripting language, and
compilation fast enough to recompile on every keystroke.

```sh
typst compile paper.typ            # -> paper.pdf
typst compile paper.typ out.pdf    # explicit output
typst compile --format svg p.typ   # SVG or PNG instead
typst watch paper.typ              # recompile as you edit
typst init @preview/charged-ieee   # start from a template
typst fonts                        # list the fonts it can see
```

`typst --help` lists the subcommands, and each has a man page:
`man typst-compile`, `man typst-watch`, and so on.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Fonts

Nothing external is needed to produce a document. Libertinus Serif and
New Computer Modern (text and math) are compiled into the binary, so a
freshly-installed Mac with no fonts of its own still typesets.

Your installed system fonts are found as well, and `--font-path` adds a
directory. `typst fonts` shows what it found.

## Shell completions

Not installed, but generated on demand:

```sh
typst completions zsh > ~/.zfunc/_typst
typst completions bash > /usr/local/etc/bash_completion.d/typst
```

`typst completions --help` lists the shells it knows.

## Updating

`typst update` is enabled in this build, and it's worth knowing exactly
what it does before using it.

unflab installs packages; it doesn't manage them. Nothing here checks
for new versions, so a tool that can update itself when you ask it to is
filling a gap rather than fighting the design. The command is never
automatic — it runs only when you type it, keeps a backup of the
replaced binary, and `typst update --revert` puts it back.

The caveat is what it installs. It downloads typst's own prebuilt binary
from GitHub and replaces this one with it. That binary is not an unflab
build: it hasn't been through this project's linkage check, and typst
publishes no checksum for its release assets, so the download is trusted
on HTTPS alone. Afterwards the file no longer matches the manifest
recorded at install time — `--uninstall` still removes it, but what's on
disk is upstream's binary rather than the one described here.

To stay on unflab builds, reinstall instead:

```sh
curl -fsSL https://unflab.app/get | sh -s -- typst
```

## About this build

One binary, linked against nothing but macOS's own libraries. That
takes no special effort in Rust — the standard library links statically
by default — but two dependencies looked like they might spoil it and
don't:

- Downloading packages from Typst Universe needs TLS, which on macOS
  goes through Security.framework rather than OpenSSL. The OpenSSL
  dependency in typst's manifest is explicitly excluded on Apple
  platforms.

- System font discovery uses a feature called `fontconfig`, which
  sounds like libfontconfig and the freetype/harfbuzz stack behind it.
  It isn't: it's `fontconfig-parser`, a pure-Rust reader for
  fontconfig's XML configuration files.

Built from the committed `Cargo.lock` (`--locked`), so every crate is
the version upstream tested, pinned by hash.

Upstream publishes prebuilt macOS binaries too — this package exists so
`typst` installs the same way as everything else here, not because it
was hard to get. What it does escape is the alternative: the traditional
way to typeset from the command line is a TeX distribution, which is
several gigabytes and thousands of files.

## Upstream

- Home: https://typst.app/
- Docs: https://typst.app/docs/
- Source: https://github.com/typst/typst
- Version: 0.15.1
- Licence: Apache-2.0 (see `LICENSE` and `NOTICE`)

`typst` is the work of Typst GmbH and its contributors. unflab only
compiles and packages it.
