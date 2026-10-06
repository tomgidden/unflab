# apfel

`apfel` puts the language model built into macOS — the one behind
Apple Intelligence — on the command line. It runs entirely on your
Mac: no API key, no account, nothing sent anywhere.

```sh
apfel "summarise this in one line" -f notes.txt
git diff | apfel "write a commit message for this"
apfel --chat                    # interactive conversation
apfel --serve                   # OpenAI-compatible server on localhost
```

`apfel --help` covers the flags; `man apfel` is the full reference.

## Requirements

- Apple Silicon. There is no Intel build.
- macOS 26 or later.
- Apple Intelligence switched on in System Settings → Apple
  Intelligence & Siri, with its model downloaded. Until it is, apfel
  installs and runs but has no model to answer with.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## Where the binary comes from

unflab doesn't build this one. Upstream publishes a release binary
that is already what unflab would produce: signed with the author's
Apple Developer ID, notarised, and linking nothing outside the base
system.

This package holds the man page, the shell completions, the licence
and this README. When you install it, its `install.sh` downloads the
binary from apfel's GitHub release and keeps it only if both of these
hold:

- its SHA-256 matches the one pinned in unflab's recipe, which is the
  exact file unflab's CI checked;
- it carries a valid Apple Developer ID signature from the author's
  team (`7D2YX5DQ6M`).

If either check fails, nothing is installed. CI makes the same two
checks, and also confirms the binary links only against `/usr/lib` and
`/System/`.

## Shell completions

Completions for zsh, bash and fish are installed to each shell's usual
directory. zsh only finds them if `fpath` includes that directory
*before* `compinit` runs — the post-install message gives the line.

## Not shipped

The `demo/` scripts from upstream's release tarball. They are embedded
in the binary, and `apfel demos <dir>` writes them out.

## Upstream

- Home: https://apfel.franzai.com
- Source: https://github.com/Arthur-Ficial/apfel
- Version: 1.16.0
- Licence: MIT
