# cc2md (unflab build)

`cc2md` reads Claude Code's session logs — the JSONL files under
`~/.claude/projects/` — and renders them as markdown: in the terminal
with [glamour](https://github.com/charmbracelet/glamour), or exported
to a file. Run with no arguments in a TTY and it opens an interactive
session picker.

```sh
cc2md                                  # interactive session picker
cc2md --last 1                         # view the most recent session
cc2md session.jsonl --output session.md  # export to a markdown file
cc2md list                             # list available sessions
```

`cc2md --help` lists the full set of flags (rendering style, width,
thinking blocks, tool-output collapsing, markdown flavor).

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

A single static binary built with `CGO_ENABLED=0`, so it links against
nothing but `libSystem`.

Upstream (magarcia/cc2md) has no `LICENSE` file as of v0.1.0 — the MIT
grant is stated only in its `README.md`. The `LICENSE` shipped here
reproduces that grant so the licence travels with the package as it
does for every other build in this project.

## Upstream

- Home: https://github.com/magarcia/cc2md
- Version: 0.1.0
- Licence: MIT (see `LICENSE`; text reproduced from upstream's README,
  no `LICENSE` file exists in the source repository)

`cc2md` is Miguel A. Garcia's work. unflab only compiles and packages it.
