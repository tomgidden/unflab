# astyle -- reformat C, C++, C#, Java and Objective-C source
#
# Class 3 (convenience): astyle's Homebrew formula has no runtime
# dependencies either, so there is no dependency tree to escape. It is
# packaged so it installs the same way as everything else.
#
# Be straight about the overlap, because it is substantial. macOS
# already has two formatters: /usr/bin/indent, a BSD C formatter, and
# clang-format, which ships with the Command Line Tools at
# /Library/Developer/CommandLineTools/usr/bin/clang-format -- installed
# on any machine with `cc`, just not on PATH.
#
# clang-format is the real comparison, and it is not a weak one. It
# handles C, C++, Java and C#, and takes a named style on the command
# line (--style=GNU and friends) without any .clang-format file. Anyone
# happy with it does not need this. indent is the narrow one: C only,
# and it mangles a C++ class body.
#
# So the case for astyle is preference, not capability: a different set
# of brace styles (allman, kr, linux, ratliff, horstmann, pico, lisp),
# finer-grained switches for padding and one-liners, and behaviour
# people have scripted against for twenty years. That is a real reason
# to want a specific formatter and a thin reason to package one, which
# is what class 3 is for -- it is here so it installs like everything
# else, not because anything is missing without it.
#
# It links only libc++ and libSystem, both in /usr/lib.

UNFLAB_NAME=astyle
UNFLAB_VERSION=3.6.18
UNFLAB_HOMEPAGE=https://astyle.sourceforge.net/
UNFLAB_LICENSE=MIT
UNFLAB_SOURCE="https://downloads.sourceforge.net/project/astyle/astyle/astyle%203.6/astyle-3.6.18.tar.bz2"
UNFLAB_CHECK=html:https://sourceforge.net/projects/astyle/rss?path=/astyle:astyle
UNFLAB_SHA256=d4fc433cfeacc952de295961bc8ae9eab722e08580baa6c1e8e7b39a7a2fbb48
# SourceForge's RSS feed carries an MD5 per file, which is neither a
# signature nor a strong hash, and comes from the same host that served
# the tarball -- so it attests to nothing this recipe's own SHA-256
# doesn't already pin.
UNFLAB_ATTEST='none:SourceForge release publishes no checksum or signature'
UNFLAB_TOOLCHAIN="c cmake make"
UNFLAB_CLASS=3

unflab_build() {
  # Out-of-tree build: upstream's CMakeLists puts the binary at the top
  # of the build directory rather than in a subdirectory, so unflab_stage
  # looks for bld/astyle.
  #
  # The library options all default to OFF, and the defaults are what we
  # want -- this ships the command-line tool, not libastyle.
  cmake -S . -B bld -DCMAKE_BUILD_TYPE=Release >/dev/null
  cmake --build bld
}

unflab_stage() {
  install -d "$STAGE_DIR/bin" "$STAGE_DIR/share/man/man1" \
             "$STAGE_DIR/completion"

  # Staged by hand rather than with `cmake --install`. On Darwin
  # upstream's install rules ship the binary and the HTML manual but
  # skip the man page -- it is only in the branch guarded for Linux --
  # and they hardcode /usr/local, which is not where this installs.
  install -m 755 bld/astyle "$STAGE_DIR/bin/astyle"
  install -m 644 man/astyle.1 "$STAGE_DIR/share/man/man1/astyle.1"

  # All three completions are hand-written and shipped by upstream.
  # The installed names are what each shell expects to find, which is
  # not what the files are called here: zsh wants _astyle, bash and
  # fish want astyle. The manifest does that renaming.
  install -m 644 sh-completion/astyle.zsh "$STAGE_DIR/completion/_astyle"
  install -m 644 sh-completion/astyle.bash "$STAGE_DIR/completion/astyle.bash"
  install -m 644 sh-completion/astyle.fish "$STAGE_DIR/completion/astyle.fish"

  install -m 644 LICENSE.md "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
