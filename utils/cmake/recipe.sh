# cmake -- cross-platform build system generator
#
# Refer. No dependency problem on macOS (its only dependency is the
# system ncurses), and upstream ships official macOS builds. Excluded on
# shape: four binaries plus a large share/cmake module tree, which is a
# lot to own when upstream already does it well.

UNFLAB_NAME=cmake
UNFLAB_KIND=refer
UNFLAB_HOMEPAGE=https://cmake.org/
