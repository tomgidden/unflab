# mtr -- traceroute and ping combined
#
# Refer.
#
# Needs raw sockets to send its own ICMP and UDP probes, which on macOS
# means installing setuid root. A `curl | sh` installer that quietly takes
# ownership of a setuid binary in the user's `PATH` is the wrong shape for
# this project — the same reason `ping` and `traceroute` were left out of
# the inetutils recipe.

UNFLAB_NAME=mtr
UNFLAB_KIND=refer
UNFLAB_HOMEPAGE=https://www.bitwizard.nl/mtr/
