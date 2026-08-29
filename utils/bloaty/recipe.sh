# bloaty -- a size profiler for binaries
#
# Class 1 (dependency escape), and the project's best joke: `brew install
# bloaty` pulls abseil, protobuf, capstone and re2 -- two of the largest
# C++ dependency trees in the ecosystem -- to install a tool whose entire
# purpose is telling you why your binary is too big.
#
# It needs none of them at runtime. Upstream's release tarball vendors
# all four, so this builds them into a single self-contained binary.

UNFLAB_NAME=bloaty
UNFLAB_VERSION=1.1
UNFLAB_HOMEPAGE=https://github.com/google/bloaty
UNFLAB_LICENSE=Apache-2.0
UNFLAB_SOURCE=https://github.com/google/bloaty/releases/download/v1.1/bloaty-1.1.tar.bz2
UNFLAB_SHA256=a308d8369d5812aba45982e55e7c3db2ea4780b7496a5455792fb3dcba9abd6f
UNFLAB_TOOLCHAIN="c cmake make"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=bloaty

unflab_build() {
  # The release tarball ships third_party/{abseil-cpp,capstone,protobuf,
  # re2,demumble} already populated, so nothing is fetched at build time
  # and nothing is linked dynamically -- the four formulae Homebrew
  # installs are compiled straight into the binary.
  #
  # CMAKE_POLICY_VERSION_MINIMUM=3.5 is required, not cosmetic: bloaty
  # 1.1 is from 2020 and its vendored trees declare minimums as low as
  # cmake_minimum_required(VERSION 2.6). CMake 4.x refuses anything below
  # 3.5 outright, so without this the configure step fails before
  # compiling a line.
  cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DBUILD_TESTING=OFF \
    >/dev/null
  cmake --build build -j "$(sysctl -n hw.ncpu)"
}

unflab_stage() {
  install -d "$STAGE_DIR/bin"
  install -m 755 build/bloaty "$STAGE_DIR/bin/bloaty"
  install -m 644 LICENSE "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
  # No man page upstream; `bloaty --help` is the documentation.
}
