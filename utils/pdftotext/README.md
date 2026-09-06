# pdftotext (unflab build)

`pdftotext` extracts the text from a PDF. Not OCR — it reads the text
that is already in the file, which is most PDFs that came from a word
processor, a browser, LaTeX or a report generator.

```sh
# Text to a file (in.pdf -> in.txt)
pdftotext report.pdf

# ...or to stdout, to pipe somewhere
pdftotext report.pdf - | grep -i invoice

# Preserve the page's column layout instead of reflowing
pdftotext -layout report.pdf -

# Just pages 3 to 7
pdftotext -f 3 -l 7 report.pdf -

# What is this file, and does it have text at all?
pdfinfo report.pdf
pdffonts report.pdf
```

If `pdftotext` gives you nothing, the PDF is probably a scan — page
images with no text layer. No amount of extraction will help; that needs
OCR, which this does not do.

Seven tools ship, all from one build:

- **`pdftotext`** — the text.
- **`pdfinfo`** — page count, size, producer, dates, encryption.
- **`pdffonts`** — which fonts a PDF uses and whether they are embedded.
- **`pdftops`** — convert to PostScript.
- **`pdfdetach`** — list and extract file attachments.
- **`pdfseparate`** — split into one file per page.
- **`pdfunite`** — join files back together.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

This is the collection's clearest case. `brew install poppler` pulls a
dependency closure of **50 formulae** — cairo, glib, harfbuzz, nss,
nspr, gpgme, GnuPG, five X11 libraries and a full TLS stack among them —
and installs 13 binaries, in order to get text out of a PDF. You can
check that yourself with `brew deps --tree poppler`.

This package needs none of it. Poppler's Qt, GLib, cairo, crypto and
image-codec backends are all optional and simply default to on; the
font backend can be set to `generic`, which drops fontconfig and
harfbuzz with it. What is left needs FreeType — compiled from source
and linked statically here — plus zlib and iconv, which macOS provides.

`otool -L` on any of the seven binaries shows only `libz`, `libc++` and
`libSystem`, all from `/usr/lib`.

Dropping fontconfig costs nothing here. Font *matching* — finding a
system font to stand in for one the PDF does not embed — matters for
rendering a page, not for reading its text. A two-column academic paper
with embedded Type 1 subsets extracts 6,152 words correctly, accents,
CJK, ligatures and `-layout` column positions included.

### What is deliberately not here

Poppler also builds `pdfimages`, `pdftoppm` and cairo-backed
`pdftohtml`. Those are raster tools, and without the image codecs this
build leaves out they do not merely lose features — `pdftoppm -png`
produces no file at all. A binary that silently does nothing is worse
than one that is absent, so they are not shipped.

If you want those, you want a full poppler with its image stack, and
Homebrew is the right way to get it. This package is for the text.
