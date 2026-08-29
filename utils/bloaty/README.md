# bloaty (unflab build)

Bloaty McBloatface is a size profiler for binaries. It tells you what's
actually taking up space in an executable — which sections, which symbols,
which source files, which compile units — and can diff two binaries to
show what grew.

```sh
bloaty ./my-binary
bloaty -d symbols ./my-binary            # break down by symbol
bloaty -d compileunits ./my-binary       # by source file
bloaty ./new -- ./old                    # what changed between builds
```

`bloaty --help` lists the data sources and options.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

There's a joke here worth spelling out. `brew install bloaty` pulls in
**abseil, protobuf, capstone and re2** — two of the largest C++
dependency trees around — to install a tool whose entire purpose is
telling you why your binary is too big.

It doesn't need any of them at run time. Upstream's release tarball
vendors all four, so this package compiles them straight into a single
self-contained binary that links only what macOS already provides.

No man page: upstream doesn't ship one, and `bloaty --help` is the
documentation.

## Upstream

- Source: https://github.com/google/bloaty
- Version: 1.1
- Licence: Apache-2.0 (see `LICENSE`)

Note that v1.1 (2020) is the latest tagged release, though development
continues on the main branch.

Bloaty is Google's work, principally Josh Haberman's. unflab only
compiles and packages it.
