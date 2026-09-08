# mutool (unflab build)

Inspect, convert and manipulate PDF files, from MuPDF.

`mutool` merges and splits documents, extracts text and images, renders
pages to PNG, and rewrites and inspects PDF internals.

```sh
mutool draw -o page.png doc.pdf 1        # render page 1
mutool draw -F txt doc.pdf               # extract text
mutool merge -o out.pdf a.pdf b.pdf      # merge
mutool pages doc.pdf                     # page dimensions
mutool extract doc.pdf                   # pull out fonts and images
mutool clean -d doc.pdf out.pdf          # rewrite, decompressing streams
mutool info doc.pdf                      # fonts, images, page count
```

`mutool` with no arguments lists every subcommand; `man mutool` is the
full documentation.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

The binary installs as `mutool-cjk`, and `mutool` is added as a symlink
if nothing else on your machine already answers to that name.

## Which one is this?

This is the **full** build: every fallback font MuPDF ships, including
the per-language CJK faces. About 41 MB.

If you don't work with CJK documents, `mutool-lite` is the same tool at
about 21 MB — the difference is entirely fonts. See its README for what
it drops.

Fallback fonts only matter for documents that *don't* embed their own.
Most PDFs do embed them, and text extraction doesn't depend on them at
all; rendering a document with unembedded text is where they earn their
place.

## What isn't included

**Digital signature verification.** MuPDF verifies PDF signatures
through OpenSSL, which would mean linking a library from outside the
base system — the one thing every package here avoids. `mutool sign`
still lists and clears signature fields; it cannot verify them. If you
need that, `brew install mupdf` is the honest answer.

**OCR and barcodes.** Upstream leaves Tesseract and zxing-cpp off by
default and so does this build. OCR in particular would mean bundling
Tesseract and Leptonica — a very large dependency for a feature that
belongs to a different tool.

**The viewers.** `mupdf-gl` and `mupdf-x11` are GUI applications; only
the command-line tool is packaged.

## About this build

One binary, linked against nothing but macOS's own `libSystem`.

MuPDF vendors its dependencies — FreeType, HarfBuzz, jbig2dec, libjpeg,
OpenJPEG, lcms2, zlib, brotli, gumbo and MuJS all live in the source
tree and are built from it. Homebrew's formula deletes those bundled
copies and links system libraries instead, which is correct for a
package manager sharing libraries across formulae, and is why
`brew install mupdf` brings a dozen dependencies. This build just lets
MuPDF build the way it ships.

## Upstream

- Home: https://mupdf.com/
- Docs: https://mupdf.readthedocs.io/
- Source: https://git.ghostscript.com/?p=mupdf.git
- Version: 1.28.3
- Licence: AGPL-3.0-or-later (see `LICENSE`)

MuPDF is Artifex Software's work. unflab only compiles and packages it.

The AGPL requires that the source for this binary be available: it is
the tarball recorded in `.unflab/provenance`, with its SHA-256, exactly
as fetched.
