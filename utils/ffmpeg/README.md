# ffmpeg, ffprobe, ffplay

FFmpeg 9.0.2 for Apple Silicon, as three standalone binaries that each
install on their own. Each one links against nothing outside the base
system.

## Where the binary comes from

unflab doesn't build these. They are Martin Riedl's static builds from
[ffmpeg.martin-riedl.de](https://ffmpeg.martin-riedl.de/), made with
his open build script
([git.martin-riedl.de/ffmpeg/build-script](https://git.martin-riedl.de/ffmpeg/build-script)).

This package holds the man pages, the licence and this README. When you
install it, its `install.sh` downloads the binary from Martin Riedl's
site and keeps it only if both of these hold:

- its SHA-256 matches the one pinned in unflab's recipe, which is the
  exact file unflab's CI checked;
- it carries a valid Apple Developer ID signature from Martin Riedl's
  team (`KU3N25YGLU`).

If either check fails, nothing is installed. CI makes the same two
checks, and also confirms that every binary links only against `/usr/lib`
and `/System/`.

We'd encourage supporting Martin's efforts and hosting costs with a
donation to his [PayPal account](https://paypal.me/martinr92), as 
indicated at the bottom of his build page.

## What's in it

Codecs and libraries: x264, x265 (8, 10 and 12-bit), aom, dav1d,
rav1e, SVT-AV1, vvenc, openh264, libvpx, libwebp, OpenJPEG, LAME,
Opus, Vorbis and Theora. Filters and other libraries: libvmaf, zimg,
libass with FreeType, fontconfig and HarfBuzz, SRT, libbluray, zvbi,
libklvanc, snappy, libxml2 and OpenSSL.

macOS frameworks: VideoToolbox (hardware decode, plus the
`h264_videotoolbox`, `hevc_videotoolbox` and `prores_videotoolbox`
encoders) and AudioToolbox (`aac_at`).

`ffmpeg -buildconf` prints the full configuration.

## Worth knowing

- **Size.** Every library is linked into every binary, so each one is
  about 65 MB. The three are separate packages so you can install only
  the ones you need.
- **Licence.** The build is GPLv3 (`--enable-gpl --enable-version3`)
  and contains nothing nonfree. The corresponding FFmpeg source is the
  release tarball at
  [ffmpeg.org/releases](https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz),
  and the libraries' versions are pinned in Martin Riedl's build script.
- **Man pages.** `man ffmpeg` and `man ffmpeg-all` are installed with
  ffmpeg, along with the component pages that the other tools also
  refer to: `ffmpeg-filters`, `ffmpeg-codecs`, `ffmpeg-formats`,
  `ffmpeg-protocols`, `ffmpeg-devices`, `ffmpeg-bitstream-filters`,
  `ffmpeg-utils`, `ffmpeg-scaler` and `ffmpeg-resampler`. ffprobe and
  ffplay install their own page and their `-all` page, which already
  includes the component text.
- **Versions.** A new FFmpeg release reaches unflab only after Martin
  Riedl has published a build of it, and it's been noticed and merged
  into unflab.
- **More features.** If you have need for a more fully-featured build
  of FFmpeg, in addition to their [standard `ffmpeg` formula](https://formulae.brew.sh/formula/ffmpeg)
  which is of similar capability to this version, Homebrew have a more
  extensive [`ffmpeg-full` formula](https://formulae.brew.sh/formula/ffmpeg-full).
