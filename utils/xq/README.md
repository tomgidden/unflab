# xq (unflab build)

`xq` pretty-prints XML and HTML with syntax colouring, and pulls content
out of them using XPath or CSS selectors. It works on messy real-world
HTML as well as well-formed XML.

```sh
xq feed.xml                             # indent and colour
curl -s https://example.com | xq -m     # the same for HTML
xq -x '//item/title' feed.xml           # XPath
xq -q 'a.nav' -a href page.html         # CSS selector, one attribute
xq -j config.xml                        # XML to JSON
xq -i messy.xml                         # reformat in place
```

`man xq` has the full set of options.

## xq, yq, jq and xmlstarlet

These tools overlap:

- **`xq`** is for *reading* XML and HTML: looking at a document, or
  pulling values out of it. It's the only one of these tools that
  handles HTML or CSS selectors.
- **`xmlstarlet`** also does XPath, and it's the one to use for *changing*
  XML: editing nodes, validation, XSLT.
- **`yq -p xml`** turns XML into a tree you can query and convert with
  yq's jq-style language.
- **`jq`** takes the output of `xq -j` if you'd rather work in JSON.

This is sibprogrammer's Go `xq`, the one Homebrew installs. The Python
`yq` package (kislyuk/yq) has an unrelated `xq` of its own, which is a
`jq` wrapper for XML. That one isn't shipped here.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Configuration

`xq` works with no configuration. It reads defaults for its flags
(indentation, colour, HTML mode, and so on) from `~/.xq` if that file
exists; nothing is written there. Long output goes through `$XQ_PAGER`,
or `$PAGER` if that isn't set. Set either one to an empty value to turn
paging off.

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
nothing but `libSystem`.

Upstream publishes prebuilt macOS binaries too. This package exists so
`xq` installs the same way as everything else here, not because it was
hard to get.

## Upstream

- Source: https://github.com/sibprogrammer/xq
- Version: 1.5.1
- Licence: MIT (see `LICENSE`)

`xq` is Alexey Yuzhakov's work. unflab only compiles and packages it.
