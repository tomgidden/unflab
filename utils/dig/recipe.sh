# dig -- DNS lookup utility from BIND
#
# Refer.
#
# BIND 9.20 needs three libraries built from source: OpenSSL, libuv and
# liburcu. Six of Homebrew's eight dependencies do drop out cleanly
# (`--without-json-c --without-readline --without-jemalloc --disable-doh
# --disable-geoip`, and libidn2 defaults to off), so the dependency-escape
# story is real — but liburcu is mandatory with no fallback, and libuv
# ships no pre-generated `./configure`, so it needs autotools or CMake
# before it will build at all.
#
# That is a 496-file, 43 MB build with three bundled dependencies to get
# one binary out of a DNS *server* suite — a poor ratio next to the rest
# of the roster.
#
# The deciding factor is that **`doggo` already covers most of dig's
# remit** and is shipped here: arbitrary record types (`-t`), `@resolver`
# selection, reverse lookups (`-x`), and transports dig cannot match
# without dependencies this build would drop anyway — DoH, DoT, DNSCrypt
# and DNS-over-QUIC, including HTTP/3. It is a single static Go binary
# with no dependencies at all. macOS also still ships `host` and
# `dscacheutil` for the simplest lookups.
#
# What genuinely has no substitute here is dig's exact presentation
# format — the `;; ANSWER SECTION:` output that scripts and documentation
# parse — and `+trace`. If someone needs those specifically, that is the
# argument for revisiting; wanting to look up a DNS record is not.

UNFLAB_NAME=dig
UNFLAB_KIND=refer
UNFLAB_HOMEPAGE=https://www.isc.org/bind/
