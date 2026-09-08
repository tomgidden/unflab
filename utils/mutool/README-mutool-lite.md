# mutool-lite (unflab build)

The same PDF tool as mutool, at half the size without the per-language CJK fonts.

Same source, same version, same subcommands — it just embeds fewer
fallback fonts, so it is about 21 MB rather than 41 MB.

```sh
mutool draw -o page.png doc.pdf 1        # render page 1
mutool draw -F txt doc.pdf               # extract text
mutool merge -o out.pdf a.pdf b.pdf      # merge
mutool pages doc.pdf                     # page dimensions
mutool extract doc.pdf                   # pull out fonts and images
mutool clean -d doc.pdf out.pdf          # rewrite, decompressing streams
mutool info doc.pdf                      # fonts, images, page count
```

`mutool` with no arguments lists every subcommand; `man mutool-lite` is
the full documentation.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

The binary installs as `mutool-lite`, and `mutool` is added as a symlink
if nothing else on your machine already answers to that name.

## What's different

Every byte of the difference is fonts. The code is identical.

MuPDF embeds fallback fonts for text a PDF *doesn't* carry its own copy
of. This build drops three sets:

| Dropped | What it costs |
|---|---|
| Source Han Serif | Per-language CJK glyph forms — 24 MB on its own |
| Historic scripts | Ancient and historic writing systems |
| Symbol font | Miscellaneous symbols |

CJK text still renders: DroidSansFallback is kept, and it covers the
CJK range. What's lost is *per-language* correctness — the same
character is drawn differently in Japanese, Chinese and Korean
typography, and this build can only draw it one way.

Kept in both builds: the Base 14 PDF fonts (upstream warns that
dropping them makes PDF "unusable") and Charis SIL for EPUB and HTML
(dropping it makes EPUB "ugly").

**None of this affects text extraction, merging, splitting, or any
document that embeds its own fonts** — which is most of them. It only
shows up when rendering a document whose fonts aren't included in the
file.

If you work with CJK documents regularly, install `mutool` instead.

## What isn't included

Everything under this heading in `mutool`'s README applies here too:
no PDF signature *verification* (that needs OpenSSL), no OCR or
barcodes (off upstream by default), and no GUI viewers.

## About this build

One binary, linked against nothing but macOS's own `libSystem`.

MuPDF vendors its dependencies — FreeType, HarfBuzz, jbig2dec, libjpeg,
OpenJPEG, lcms2, zlib, brotli, gumbo and MuJS all live in the source
tree and are built from it. Homebrew's formula deletes those bundled
copies and links system libraries instead, which is why
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
as fetched. This build additionally sets `-DTOFU_CJK_LANG
-DTOFU_HISTORIC -DTOFU_SYMBOL`, which is recorded in the recipe.
