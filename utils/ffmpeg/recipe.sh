# ffmpeg -- record, convert and stream audio and video
#
# Class 1 (dependency escape). `brew install ffmpeg` pulls 14 formulae
# and still leaves out most of what makes a build useful -- no aom,
# rav1e, VMAF, libass or zimg. `brew install ffmpeg-full` has those, at
# the price of a 102-formula closure. These are three standalone
# binaries with all of that linked in and nothing outside the base
# system.
#
# The first recipe in the collection that does not compile its
# binaries. FFmpeg with this many codecs is a forty-library build, and
# Martin Riedl already publishes one for Apple Silicon -- static,
# signed with his Developer ID, from an open build script
# (https://git.martin-riedl.de/ffmpeg/build-script). Maintaining a
# second copy of that build here would buy nothing but the maintenance.
#
# So each package ships only the man pages, the licence and a README,
# and its install.sh downloads the binary from ffmpeg.martin-riedl.de
# on the user's machine. It is accepted only if it matches the SHA-256
# pinned in fetch.tsv AND carries a valid Developer ID signature from
# his team. build.sh fetches the same files, makes the same checks, and
# puts the binaries through the linkage gate, so what a user downloads
# is byte-for-byte what CI verified.
#
# Verified for 9.0.2: all three binaries are thin arm64, minimum macOS
# 12.0; libx265 is multi-bit (8, 10 and 12-bit encodes all work);
# libvmaf, VideoToolbox (hwaccel plus the h264, hevc and prores
# encoders) and AudioToolbox (aac_at) are present. It is GPLv3 --
# --enable-gpl --enable-version3 -- with nothing nonfree.
#
# The man pages come from the FFmpeg release tarball of the same
# version, which is also the GPL source reference for the binaries.
# They are generated straight from the texinfo with the base system's
# perl and pod2man: FFmpeg's own `make doc` would first build the
# libraries to generate two option tables no man page includes.

UNFLAB_NAME=ffmpeg
UNFLAB_VERSION=9.0.2
UNFLAB_HOMEPAGE=https://ffmpeg.org/
UNFLAB_LICENSE=GPL-3.0-or-later
UNFLAB_SOURCE=https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz
UNFLAB_SHA256=8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e
UNFLAB_ATTEST=gnupg:https://ffmpeg.org/ffmpeg-devel.asc
UNFLAB_SIG_URL="$UNFLAB_SOURCE.asc"
UNFLAB_TOOLCHAIN=""
UNFLAB_CLASS=1
UNFLAB_PACKAGES="ffmpeg ffprobe ffplay"
UNFLAB_VERSION_FLAG=-version

# The binaries lag FFmpeg's own releases, and the man pages must match
# them, so the version to watch is the one Martin Riedl has published
# rather than the one ffmpeg.org has.
UNFLAB_CHECK="html-re:https://ffmpeg.martin-riedl.de/:/download/macos/arm64/[0-9]+_([0-9][0-9.]*)/"

# Component pages every tool refers to. They ship with the ffmpeg
# package only: a file two packages install is removed by uninstalling
# either. ffprobe-all and ffplay-all carry the same text inline.
FFMPEG_COMPONENTS="utils scaler resampler codecs bitstream-filters formats protocols devices filters"

# The libraries FFmpeg's configure marks as enabled in doc/config.texi.
# The texinfo tests only these flags -- plus config-all/config-not-all,
# given on texi2pod's command line, and config-readonly/writeonly, which
# stay unset -- so writing the file here gives the same pages without
# running configure at all.
FFMPEG_LIBS="avutil swscale swresample avcodec avformat avdevice avfilter"

unflab_build() {
  local p c flag unknown=""

  # A flag this list doesn't know means upstream's docs now depend on
  # something configure would have decided. Stop rather than quietly
  # dropping sections from the pages.
  for flag in $(grep -rhoE '@if(set|clear) config-[a-z0-9_-]+' doc/*.texi |
                  sed 's/.* config-//' | sort -u); do
    case " $FFMPEG_LIBS all not-all readonly writeonly " in
      *" $flag "*) ;;
      *) unknown="$unknown $flag" ;;
    esac
  done
  [[ -z "$unknown" ]] || {
    echo "ffmpeg: doc/*.texi tests unknown config flags:$unknown" >&2
    return 1
  }
  for c in $FFMPEG_LIBS; do
    echo "@set config-$c yes"
  done > doc/config.texi

  mkdir -p man
  for p in ffmpeg ffprobe ffplay; do
    unflab_ffmpeg_man "$p" "$p" -Dconfig-not-all=yes
    unflab_ffmpeg_man "$p" "$p-all" -Dconfig-all=yes
  done
  for c in $FFMPEG_COMPONENTS; do
    unflab_ffmpeg_man "ffmpeg-$c" "ffmpeg-$c" -Dconfig-not-all=yes
  done
}

# unflab_ffmpeg_man <texi> <page> <define> -- the two steps of FFmpeg's
# doc/Makefile pattern rules for doc/%.1, run by hand.
unflab_ffmpeg_man() {
  perl doc/texi2pod.pl "$3" -Idoc "doc/$1.texi" "man/$2.pod"
  pod2man --section=1 --center=" " --release=" " --date=" " \
    "man/$2.pod" > "man/$2.1"
  [[ -s "man/$2.1" ]]
}

unflab_stage() {
  local c
  install -d "$STAGE_DIR/share/man/man1"
  install -m 644 "man/$PKG.1" "man/$PKG-all.1" "$STAGE_DIR/share/man/man1/"
  if [[ "$PKG" == ffmpeg ]]; then
    for c in $FFMPEG_COMPONENTS; do
      install -m 644 "man/ffmpeg-$c.1" "$STAGE_DIR/share/man/man1/"
    done
  fi

  install -m 644 COPYING.GPLv3 "$STAGE_DIR/LICENSE"
  install -m 644 "$RECIPE_DIR/README.md" "$STAGE_DIR/README.md"
}
