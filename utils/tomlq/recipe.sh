# tomlq -- jq for TOML, from the Python yq package
#
# Refer.
#
# Three thin wrappers that convert YAML, XML or TOML to JSON and hand it
# to `jq`, so the query language is exactly jq's. That is its real
# advantage over the `yq` shipped here (`utils/yq`, mikefarah's Go
# implementation), whose language is jq-like but separate.
#
# It's Python, though, and needs PyYAML, xmltodict and tomlkit on top.
# A fresh Mac has no usable `python3`, only the stub that offers to
# install the Command Line Tools, so this can't be a self-contained
# package without bundling an interpreter (PyInstaller or similar). That's
# a lot of weight for a wrapper, when the formats are already covered:
# `utils/yq` for YAML and TOML, and `utils/xq` and `utils/xmlstarlet`
# for XML.
#
# Note the name clash. The `xq` shipped here is sibprogrammer/xq, an XML
# and HTML formatter and extractor, which is unrelated to this package's
# `xq`.
#
# If a Python tool ever makes a compelling enough case, a PyInstaller
# build is the route to consider, and this could come back with it.

UNFLAB_NAME=tomlq
UNFLAB_KIND=refer
UNFLAB_HOMEPAGE=https://github.com/kislyuk/yq
