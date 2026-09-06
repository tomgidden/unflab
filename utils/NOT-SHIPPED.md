# Tools considered and not shipped

Recording these so a rejected candidate isn't silently re-proposed, and
so the reason can be revisited if it stops being true.

## mtr

Needs raw sockets to send its own ICMP and UDP probes, which on macOS
means installing setuid root. A `curl | sh` installer that quietly takes
ownership of a setuid binary in the user's `PATH` is the wrong shape for
this project — the same reason `ping` and `traceroute` were left out of
the inetutils recipe.

## dig

BIND 9.20 needs three libraries built from source: OpenSSL, libuv and
liburcu. Six of Homebrew's eight dependencies do drop out cleanly
(`--without-json-c --without-readline --without-jemalloc --disable-doh
--disable-geoip`, and libidn2 defaults to off), so the dependency-escape
story is real — but liburcu is mandatory with no fallback, and libuv
ships no pre-generated `./configure`, so it needs autotools or CMake
before it will build at all.

That is a 496-file, 43 MB build with three bundled dependencies to get
one binary out of a DNS *server* suite — a poor ratio next to the rest
of the roster.

The deciding factor is that **`doggo` already covers most of dig's
remit** and is shipped here: arbitrary record types (`-t`), `@resolver`
selection, reverse lookups (`-x`), and transports dig cannot match
without dependencies this build would drop anyway — DoH, DoT, DNSCrypt
and DNS-over-QUIC, including HTTP/3. It is a single static Go binary
with no dependencies at all. macOS also still ships `host` and
`dscacheutil` for the simplest lookups.

What genuinely has no substitute here is dig's exact presentation
format — the `;; ANSWER SECTION:` output that scripts and documentation
parse — and `+trace`. If someone needs those specifically, that is the
argument for revisiting; wanting to look up a DNS record is not.

## class-dump

No licence at all. Upstream (`nygard/class-dump`) last committed in
April 2022 and specifies no terms, so there is no right to redistribute
a built binary. Needs a maintained, actually-licensed fork before it can
be reconsidered.

## Others, briefly

- **exiftool**, **ipcalc** — Perl scripts, so they cannot be single
  self-contained binaries.
- **ncat** / nmap — the licence restricts redistributing derived binaries.
- **ghostscript** — AGPL, and Homebrew drags in tesseract, an entire OCR
  engine.
- **cdrtools** — needs Schily's bespoke `smake`.
- **netpbm** — non-standard build, hundreds of interdependent binaries.
- **cmake** — no dependency problem on macOS (its only dep is system
  ncurses), and upstream ships official macOS binaries. Excluded on
  shape: 4 binaries plus a large `share/cmake` module tree.
