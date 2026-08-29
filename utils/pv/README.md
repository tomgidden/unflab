# pv (unflab build)

`pv` — pipe viewer — sits in a pipeline and shows you what's going
through it: throughput, total volume, elapsed time, a progress bar and an
ETA.

```sh
pv bigfile.iso > /dev/sdb                # progress while writing
tar czf - dir | pv | ssh host 'cat > backup.tgz'
pv -L 1m stream                          # also useful as a rate limiter
```

`man pv` has the rest.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

Built with `--disable-nls`, which drops the translation catalogues and
with them the dependency on gettext that Homebrew's build carries. What
remains links only against `libncurses` and `libSystem`, both of which
macOS provides in `/usr/lib` — so there's nothing else to install and
nothing to keep updated.

## Upstream

- Home: https://www.ivarch.com/programs/pv.shtml
- Version: 1.9.31
- Licence: GPL-3.0-or-later (see `LICENSE`)

`pv` is Andrew Wood's work. unflab only compiles and packages it.
