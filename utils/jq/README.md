# jq (unflab build)

`jq` is a command-line JSON processor — filter, reshape and query JSON
with a concise expression language.

```sh
curl -s api.example.com/users | jq '.[] | {name, email}'
jq -r '.items[].id' data.json
jq '.a.b // "default"' config.json
```

`man jq` and https://jqlang.github.io/jq/manual/ have the full language.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

A single static binary linking nothing but `libSystem`. Regex support is
included: jq's vendored copy of oniguruma is compiled in, rather than
depending on Homebrew's.

Upstream publishes prebuilt macOS binaries too — this package exists so
`jq` installs the same way as everything else here, not because it was
hard to get.

## Upstream

- Home: https://jqlang.github.io/jq/
- Version: 1.8.1
- Licence: MIT (see `LICENSE`)

`jq` is Stephen Dolan's work, now maintained by the jq team. unflab only
compiles and packages it.
