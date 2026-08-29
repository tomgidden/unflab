# xmlstarlet (unflab build)

`xmlstarlet` is a command-line XML toolkit: query with XPath, transform
with XSLT, validate, format, and edit XML in place — the same kind of job
`jq` does for JSON.

```sh
xmlstarlet sel -t -v '//book/title' catalogue.xml
xmlstarlet ed -u '//price' -v '9.99' catalogue.xml
xmlstarlet fo --indent-tab messy.xml
xmlstarlet val --err schema.xsd document.xml
```

`man xmlstarlet` documents the full command set.

## The command name

Upstream builds the binary as `xml`. That's a very generic name to put on
your `PATH`, so this package installs it as **`xmlstarlet`** and adds
`xml` as a symlink *only* if nothing else on your machine already
provides that name. Both work; `xmlstarlet` always does.

Use `--no-plain` at install time if you'd rather not have the `xml`
alias at all.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

macOS ships libxml2, libxslt and libexslt in `/usr/lib`, so this links
against the system's own copies — nothing is bundled and nothing is
statically linked.

Upstream has been dormant since 2014 and the sources no longer compile
against a current toolchain without help: libxml2 later added a `const`
qualifier to a callback signature, which newer clang treats as an error
rather than a warning. The recipe disables that specific diagnostic
rather than patching the source, since the qualifier doesn't affect the
ABI.

## Upstream

- Home: https://xmlstar.sourceforge.net/
- Version: 1.6.1
- Licence: MIT (see `LICENSE`)

`xmlstarlet` is Mikhail Grushinskiy's work. unflab only compiles and
packages it.
