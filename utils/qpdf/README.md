# qpdf (unflab build)

qpdf transforms PDF files while preserving their content. It is not a
renderer, a text extractor or an editor — it works on PDF *structure*:
splitting, merging, rotating, linearising, encrypting, decrypting, and
converting between compressed and human-readable forms.

```sh
# Split every page into its own file
qpdf --split-pages in.pdf out.pdf

# Merge, and take pages 1-3 from one file and all of another
qpdf --empty --pages a.pdf 1-3 b.pdf -- merged.pdf

# Remove a password you know
qpdf --decrypt --password=secret locked.pdf open.pdf

# Rotate page 2 by 90 degrees
qpdf --rotate=+90:2 in.pdf out.pdf

# Linearise ("optimise for web") so a viewer can start on page 1
qpdf --linearize in.pdf out.pdf

# Inspect structure: uncompress streams into readable form
qpdf --qdf --object-streams=disable in.pdf readable.pdf

# Check a file for damage
qpdf --check suspect.pdf
```

`man qpdf` is thorough, and `qpdf --help=topics` is a good way in.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install qpdf` pulls in **jpeg-turbo** and **openssl@3** (which
brings **ca-certificates** with it) — three formulae, and an OpenSSL on
your machine that then needs keeping current for its own sake.

This package needs none of them at runtime. qpdf ships its own native
crypto provider, covering the RC4, AES and SHA-2 that PDF encryption
actually uses, so OpenSSL is a build-time default rather than a
requirement; this build selects the native provider and drops it
entirely. libjpeg is genuinely needed and is compiled from source and
linked statically, and zlib comes from macOS itself.

The result depends on nothing outside `/usr/lib` and `/System/`.
Encrypted PDFs, JPEG-encoded images and compressed streams all work as
they normally would — nothing is given up for this.

Three binaries ship together, all from the same build and each with its
own man page:

- **`qpdf`** — the tool.
- **`fix-qdf`** — repairs a QDF file's cross-reference data after you
  have hand-edited it. QDF mode is qpdf's readable-PDF format, and this
  is what makes editing one practical.
- **`zlib-flate`** — raw zlib compression and decompression, the
  encoding PDF streams use.
