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
UNFLAB_CHECK=github:google/bloaty
UNFLAB_SHA256=a308d8369d5812aba45982e55e7c3db2ea4780b7496a5455792fb3dcba9abd6f
UNFLAB_ATTEST='none:upstream release publishes no checksum or signature'
UNFLAB_TOOLCHAIN="c cmake make"
UNFLAB_CLASS=1
UNFLAB_PACKAGES=bloaty

unflab_build() {
  # The release tarball ships third_party/{abseil-cpp,capstone,protobuf,
  # re2,demumble} already populated, so nothing is fetched at build time
  # and nothing is linked dynamically -- the four formulae Homebrew
  # installs are compiled straight into the binary.
  #
  # Needs CMake 3.x. bloaty 1.1 is from 2020 and its vendored trees
  # declare minimums as low as cmake_minimum_required(VERSION 2.6);
  # worse, the vendored capstone does `cmake_policy(SET CMP0048 OLD)`
  # explicitly, and CMake 4 removed that policy's OLD behaviour
  # altogether. CMAKE_POLICY_VERSION_MINIMUM does not help there -- the
  # code asks for a behaviour that no longer exists -- so CI pins CMake
  # 3.31 rather than carrying patches to third-party CMake files.
  if cmake --version | head -1 | grep -qE '\b4\.'; then
    echo "bloaty recipe: needs CMake 3.x; found $(cmake --version | head -1)." >&2
    echo "Vendored capstone requires policy CMP0048 OLD, which CMake 4 removed." >&2
    exit 1
  fi

  cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
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
