# gettext-tools -- msgfmt, xgettext and the other GNU gettext translation tools
#
# Refer.
#
# The developer and translator half of GNU gettext -- `msgfmt`,
# `msgmerge`, `xgettext`, `msginit`, `recode-sr-latin` and a dozen more.
# `envsubst` from the runtime half *is* shipped (`utils/gettext`); this is
# about the rest.
#
# Upstream splits the two itself, and the sizes are the argument: the
# runtime tools are 420 KB, gettext-tools is 5.5 MB. It wants libunistring
# and libxml2 (falling back to bundled subsets compiled into
# libgettextlib, which is worse, not better), and json-c and libcurl for
# `spit`, its machine-translation client.
#
# The deciding factor is audience. These are tools for maintaining `.po`
# catalogues -- you reach for them when translating a program, not when
# writing shell. Anyone doing that work is already inside a project's
# build system, where the gettext their toolchain expects is the one
# `configure` finds, not a standalone binary in `~/.local/bin`. That is
# the opposite of `envsubst`, which is a general-purpose sh utility that
# happens to live in the same tarball.
#
# If someone genuinely needs `msgfmt` on a Mac without Homebrew, that is
# the argument for revisiting. Wanting to substitute variables in a
# template is not -- that is `envsubst`, and it is here.

UNFLAB_NAME=gettext-tools
UNFLAB_KIND=refer
UNFLAB_HOMEPAGE=https://www.gnu.org/software/gettext/
UNFLAB_ALT_NAMES="msgfmt xgettext msgmerge msginit msgunfmt"
