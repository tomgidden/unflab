# subversion (unflab build)

Apache Subversion, the centralised version control system. Still the
system of record for a great many long-lived repositories, and the only
way to read them.

```sh
svn checkout https://svn.example.com/repos/project
svn status
svn commit -m "..."
svn log --limit 10

# Serve a repository over svn:// with no web server involved
svnadmin create /path/to/repo
svnserve -d -r /path/to/repo
```

`man svn` documents the client; each of the other tools has its own
page.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install subversion` pulls in **apache-serf, apr, apr-util, lz4,
utf8proc and gettext** — six formulae for a version control client.
This package has none of them:

- **apr** and **apr-util** are compiled from source and linked
  statically. macOS does ship APR in `/usr/lib`, but not the
  `apr-1-config` script that both serf and Subversion use to find it —
  and those stubs are deprecated Apple libraries that may not survive a
  future macOS release.
- **serf** is compiled and linked statically, against a static OpenSSL.
- **lz4** and **utf8proc** are bundled by upstream, so
  `--with-lz4=internal --with-utf8proc=internal` drops both.
- **gettext** goes with `--disable-nls`.

The result depends only on `libz`, `libsqlite3`, `libexpat`,
`libiconv`, `libsasl2` and `libSystem`, plus the CoreServices, Security
and CoreFoundation frameworks — all of which macOS already provides.

`http://` and `https://` access works, which is the point of including
serf at all: without it Subversion can only reach `file://` and
`svn://`, which would be a package that looks complete and can't talk
to any repository anyone actually hosts. Certificate verification uses
macOS's own trust store.

## What's included

All eleven binaries upstream builds. They share one library set, so
none of them adds a dependency the others didn't already bring:

| | |
|---|---|
| `svn` | the client |
| `svnadmin` | create and maintain repositories |
| `svnlook` | inspect a repository without a working copy |
| `svnserve` | serve a repository over `svn://` |
| `svnsync` | mirror one repository into another |
| `svnrdump` | dump and load over the network |
| `svndumpfilter` | filter a dump stream by path |
| `svnfsfs` | maintenance for FSFS-backed repositories |
| `svnmucc` | commit multiple changes in one operation |
| `svnversion` | report a working copy's revision |
| `svnbench` | benchmarking helper |

`svnserve` is a daemon but not a service: it runs in the foreground,
needs no privileges, and installs nothing that starts on boot.

## A note on old working copies

Subversion 1.7 changed the working copy format, and **1.14 cannot
upgrade a working copy created before then** — it reports "working copy
is too old" and offers no way forward. If you have pre-1.7 checkouts
(a `.svn` directory in every subdirectory rather than one at the root),
you need Subversion 1.7 to upgrade them first. The file contents are
readable directly from `.svn/text-base/` in the meantime.

Repositories are unaffected: 1.14 reads repository formats going a long
way back.
