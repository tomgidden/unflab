# yq (unflab build)

`yq` is a `jq`-style processor for YAML, and for most other structured
formats: JSON, XML, TOML, CSV/TSV, INI, HCL, properties files and Lua
tables. It converts between them, and edits YAML in place without losing
its comments.

```sh
yq '.spec.replicas' deploy.yaml             # read a value
yq -i '.image.tag = "1.2.3"' values.yaml    # edit in place, comments kept
yq -o json config.yaml                      # YAML to JSON
yq -p xml -o yaml feed.xml                  # XML to YAML
yq -p toml '.package.version' Cargo.toml    # query TOML
```

`man yq` covers every operator. The same text is at
https://mikefarah.gitbook.io/yq/.

## yq, jq and xq

All three are shipped here, and they overlap:

- **`jq`** is the reference language for JSON and the most capable of
  the three at it. yq's syntax looks like jq's but is a separate
  implementation. Simple paths and pipes carry over; more elaborate jq
  programs often don't.
- **`yq`** reads formats `jq` can't. It's the tool for YAML, and for
  converting from one format to another.
- **`xq`** is for XML *and HTML*: it pretty-prints them and extracts
  content with XPath or CSS selectors. `yq -p xml` converts XML to a
  tree you can query, but it doesn't understand HTML, or XPath.

This is mikefarah's Go `yq`, the one Homebrew installs. It isn't the
Python `yq` (kislyuk/yq), which wraps `jq` and has an `xq` of its own.
That one isn't shipped here, and the `xq` in this collection is a
different, unrelated tool.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Shell completions

Completions for zsh, bash and fish are installed to each shell's
conventional directory. Nothing is sourced and no rc file is edited:

- **bash**: `~/.local/share/bash-completion/completions`, found
  automatically by bash-completion 2.x.
- **fish**: `~/.local/share/fish/vendor_completions.d`, found
  automatically.
- **zsh**: `~/.local/share/zsh/site-functions`, which is *not* in the
  default `fpath`. Add it in `~/.zshrc`, above the line that runs
  `compinit`:

  ```sh
  fpath=(~/.local/share/zsh/site-functions $fpath)
  autoload -Uz compinit && compinit
  ```

## About this build

A single static binary built with `CGO_ENABLED=0`, so it links against
nothing but `libSystem`. It's built with every format enabled.

The man page is generated from upstream's documentation with pandoc, as
upstream's own release does. That's only needed at build time: what
ships is an ordinary man page.

Upstream publishes prebuilt macOS binaries too. This package exists so
`yq` installs the same way as everything else here, not because it was
hard to get.

## Upstream

- Home: https://mikefarah.gitbook.io/yq/
- Source: https://github.com/mikefarah/yq
- Version: 4.53.6
- Licence: MIT (see `LICENSE`)

`yq` is Mike Farah's work. unflab only compiles and packages it.
