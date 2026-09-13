# ant (unflab build)

`ant` is the command-line interface to the Claude API — send messages,
manage batches, files and keys, and script anything the API exposes
without writing a client.

```sh
ant auth login                    # or export ANTHROPIC_API_KEY=...
ant messages create \
  --model claude-haiku-4-5 \
  --max-tokens 1024 \
  --message '{"role":"user","content":"hello"}'
```

`man ant` documents the whole command tree; `ant --help` lists the
subcommands.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Credentials

`ant auth login` does an OAuth flow in the browser and stores the
result. Otherwise set `ANTHROPIC_API_KEY` yourself. `ant auth status`
says which is in effect.

## askclaude

A zsh function shipped alongside, for asking one-off questions without
composing JSON:

```sh
askclaude why is my zsh startup slow
```

There is a version for each shell, and none is enabled automatically.

**zsh** — installed to `~/.local/share/zsh/site-functions/askclaude`.
Unlike a completion, which `compinit` finds on its own, a function has
to be named before it autoloads:

```sh
# ~/.zshrc, with the fpath line above any compinit
fpath=(~/.local/share/zsh/site-functions $fpath)
autoload -Uz askclaude
```

**bash** — no autoload, so source it:

```sh
# ~/.bashrc
source ~/.local/share/ant/askclaude.bash
```

**fish** — source it from `config.fish`, or copy it to
`~/.config/fish/functions/askclaude.fish`, where fish autoloads it by
filename:

```sh
source ~/.local/share/ant/askclaude.fish
```

Installed under a different `--prefix`? Substitute `<prefix>/../share`
for `~/.local/share`. The post-install notes print the real paths.

All three shell out to `jq` to build the request and read the reply,
and this package does not install jq. `curl -fsSL
https://unflab.app/get | sh -s -- jq` if you don't have it.

This helper is not upstream's — it ships here because it is useless
without `ant`, and `ant messages create` is wordy for a one-line
question. Each shell gets its own file rather than one POSIX file
sourced by all three: the zsh version uses `emulate -L zsh`, and fish
is not POSIX at all.

## About this build

Compiled with `CGO_ENABLED=0`, matching what upstream's own
`.goreleaser.yml` does, so it's a single self-contained binary linking
nothing but macOS's own libraries.

The man page is generated at build time from the command tree, using
the same hidden `@manpages` command upstream calls before packaging a
release — so it describes exactly the version shipped. It is stored
uncompressed here, where upstream gzips it, to match every other
package in this collection.

Upstream also publishes prebuilt macOS binaries and an official
Homebrew tap; this package exists so `ant` installs the same way as
everything else here, not because it was hard to get.

## Upstream

- Home: https://github.com/anthropics/anthropic-cli
- Source: https://github.com/anthropics/anthropic-cli
- Version: 1.32.0
- Licence: MIT
