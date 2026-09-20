# envsubst (unflab build)

GNU `envsubst`: substitutes environment variables in shell templates.

macOS ships no `envsubst` at all, so this is the usual way to get one
without installing a localisation library to go with it.

```sh
# Substitute every variable that is set
export NAME=world PORT=8080
echo 'hello $NAME on port $PORT' | envsubst

# Substitute only the named ones, leaving the rest alone
envsubst '$NAME' < template.conf > out.conf
```

That second form is the useful one for config templating: anything not
named is passed through untouched, so a file full of `$` syntax meant
for some other tool survives intact. Variables that *are* named but
unset expand to nothing.

`envsubst --variables '$A $B'` lists the variables a template references,
which is handy for checking nothing is missing before substituting.

`man envsubst` has the rest.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install gettext` builds the whole GNU gettext project — 22
executables, `libintl`, `libasprintf`, `libtextstyle`, Emacs Lisp files
and the manual, against json-c and libunistring — to give you this one
93 KB binary. Homebrew's formula is really there as a *library*: dozens
of other formulae depend on it for `libintl`, and `envsubst` comes along
as a side effect.

This is just `envsubst`, built from gettext's `gettext-runtime`
subdirectory, which upstream's own `PACKAGING` file describes as
"utilities for sh programs" and recommends splitting out. Configured
`--disable-nls`, it links `libSystem` and nothing else, so there is
nothing further to install.

The rest of gettext is not packaged here. The other runtime programs
(`gettext`, `ngettext`, `printf_gettext`, `printf_ngettext`) translate
strings via `.mo` message catalogues, and nothing on a Mac installs
catalogues where they would be found — they would mostly echo their
arguments back. The developer tools (`msgfmt`, `msgmerge`, `xgettext`
and the rest) are a much larger build needing libunistring and libxml2,
and serve translators rather than shell users.

## Upstream

- Home: https://www.gnu.org/software/gettext/
- Version: 1.0
- Licence: GPL-3.0-or-later (see `LICENSE`)

GNU gettext is the Free Software Foundation's work. unflab only compiles
and packages it.
