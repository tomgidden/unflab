# Tools not shipped, and not stubbed

Candidates rejected without a stub, because nobody is likely to type
the name at `unflab` or there's nothing useful to point them to.

A tool people *will* ask for gets a stub recipe instead
(`UNFLAB_KIND=refer` or `delegate`; see AGENTS.md), and its reasoning
lives in that recipe's header, beside the message `get` prints.

## brew

Homebrew is the thing unflab exists to avoid needing. Its installer
also needs sudo, and installs the Xcode Command Line Tools. Anyone who
wants it knows where it is.

## Others, briefly

- **cdrtools**: needs Schily's own `smake` to build.
- **netpbm**: non-standard build, and hundreds of interdependent
  binaries.
- **exiftool**, **ipcalc**: Perl scripts. These were rejected as unable
  to be self-contained, but `rename` ships as a Perl script, and macOS
  ships Perl. Worth revisiting as script-only packages: exiftool is pure
  Perl, with a `lib/` of its own modules.
