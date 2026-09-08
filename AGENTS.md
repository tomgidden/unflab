# AGENTS.md

Working notes for this repository — how to add a package, update one,
and cut a release. Read `README.md` first for what the project is; this
is about how to change it.

The one rule everything else serves: **a shipped binary links against
nothing outside `/usr/lib` and `/System/`**. `scripts/verify.sh` is that
rule in code, and it runs before anything can be packaged. Homebrew is
fine to use at build time — for a static `.a`, headers, tooling — and
the gate is what proves none of it survived into the artefact.

## Layout

    utils/<recipe>/recipe.sh    metadata + unflab_build + unflab_stage
    utils/<recipe>/manifest.tsv what to install where (or generated)
    utils/<recipe>/README.md    ships inside the package
    scripts/build.sh            fetch, verify, extract, build, stage
    scripts/verify.sh           the gate
    scripts/package.sh          staged tree -> dist/*.tar.gz
    scripts/litmus-test.sh      install into a throwaway HOME and use it
    scripts/build-key.sh        content hash deciding what gets rebuilt
    scripts/templates/          install.sh and the curl|sh bootstrap
    docs/, docmd.config.json    GENERATED — never edit by hand

`docs/`, `out/` and `dist/` are build output. `make docs` regenerates
the site from the recipes, which is why a package page can't drift from
what the project actually builds.

## Adding a package

Before writing anything, check `utils/NOT-SHIPPED.md` — a candidate may
have been considered and rejected already, and the reason is recorded
there. If you reject one, add it there rather than leaving the next
person to redo the analysis.

Then decide what class it is. This is the honest part of the pitch and
it goes in the recipe's header comment:

- **Class 1** — escapes a dependency tree. `brew install poppler` pulls
  50 formulae to read text out of a PDF; `pdftotext` here needs none of
  them.
- **Class 2** — one binary out of a much larger suite (`ftp` from
  inetutils).
- **Class 3** — no dependency problem to solve. It's here so it
  installs the same way as everything else. Say so plainly; don't
  inflate it.

### The recipe

Copy the closest existing one. `utils/shfmt` (Go), `utils/typst`
(Rust), `utils/pdftotext` (CMake + a static dependency) and
`utils/tree` (plain make) cover most shapes.

Required metadata:

    UNFLAB_NAME, UNFLAB_VERSION, UNFLAB_LICENSE, UNFLAB_SOURCE, UNFLAB_SHA256

`build.sh` refuses to build without `UNFLAB_SHA256`. Also set:

- `UNFLAB_HOMEPAGE`, `UNFLAB_CLASS`, `UNFLAB_PACKAGES`
- `UNFLAB_CHECK` — how `check-updates.sh` finds the latest version
  (`github:owner/repo`, `github-tags:`, `gitlab-tags:`, `gnu:pkg`,
  `html:url:prefix`). A recipe without one is reported as unchecked,
  which is deliberate: an unwatched upstream is worth knowing about.
- `UNFLAB_ATTEST` — what upstream publishes to prove the tarball was
  ever the right one. `none:<reason>` is an acceptable answer and most
  recipes use it; the reason is the point.
- `UNFLAB_TOOLCHAIN` — what building it needs (`c`, `make`, `cmake`,
  `go`, `rust`/`cargo`, `autotools`, `pkg-config`). Drives
  `scripts/prereqs.sh` and the CI toolchain steps.
- `UNFLAB_SRC_DIR` — only when the tarball doesn't unpack to
  `<name>-<version>`. Use `$BUILD_ROOT`, not `$BUILD_DIR` (see below).

Line 1 must be `# <name> -- <description>`. The docs generator scrapes
it for the site.

### Two traps in build.sh

Both of these have bitten. They're worth knowing before writing a
recipe, not after CI tells you.

1. **`unflab_build` and `unflab_stage` run in separate subshells.** An
   `export` in the build does not reach the stage. Anything both phases
   need goes at recipe scope.

2. **The recipe is sourced ~140 lines before `BUILD_DIR` is
   exported.** At recipe scope `$BUILD_DIR` is empty, so
   `"$BUILD_DIR/x"` silently becomes `/x` at the filesystem root. Use
   `$BUILD_ROOT` at recipe scope; `$BUILD_DIR` only inside the
   functions, where it is set. Both phases run under
   `cd "$BUILD_DIR"`, so relative paths work in them.

### The manifest

`manifest.tsv` is tab-separated: `kind mode <path-in-package>
<installed-name> <alias>`. Kinds are `bin`, `man1`, `man5`, `man8`,
`doc`, `data`, `config`, `completion`. `-` means no alias.

**A file listed but missing from the package is a fatal error on the
user's machine, not in CI.** If the staged file list is anything but
fixed — generated man pages, a per-subcommand set — generate the
manifest in `unflab_stage` instead, writing it to
`$STAGE_DIR/.unflab/manifest.tsv`. `utils/coreutils` and `utils/typst`
both do. A generated manifest can only ever describe what actually
staged.

Ship the licence. If upstream has a `NOTICE` (Apache-2.0 requires it),
ship that too.

### Verifying before you push

    make <name>.prereqs      what building it needs, and what's missing
    make <name>.build        fetch, verify, build, stage, and gate it
    make <name>.package      make the release archive
    scripts/litmus-test.sh $(uname -m)-apple-darwin

Build locally if you possibly can. CI is an eight-minute round trip and
it will catch staging mistakes that a local build catches in seconds.

The litmus test is the project's real acceptance test: it installs each
archive into a throwaway `HOME` with Homebrew and `/usr/local` stripped
from `PATH`, runs every binary, resolves every man page, then purges
and checks nothing was left behind.

Finally: `make docs` and confirm the new page renders.

## Updating a package

    scripts/check-updates.sh              what has moved on
    scripts/bump.sh <recipe> <version>    rewrite version + re-pin sha

`bump.sh` rewrites only `UNFLAB_VERSION` and `UNFLAB_SOURCE` and
re-pins the checksum. It deliberately does not touch prose: the version
often appears in a comment whose truth a global replace would quietly
destroy. Read the diff and update the header comment and README
yourself.

A hash computed from a download cannot attest to that download —
`bump.sh` writes a candidate, not a fact. What makes it trustworthy is
CI building and gating it, and a human reading the diff. Nothing here
auto-bumps to main.

## The site

The site deploys on **every push to `main`** — no tag, no version bump.
So a docs fix, a template change, or an edit to `generate-docs.py` goes
live on push.

What it says is generated from two sources, deliberately:

- **Prose** comes from the working tree, so documentation edits are
  live immediately.
- **The download-facing data** — `index.txt` and the per-package
  versions — comes from *the latest release's asset list*.

That split is why a new package needs a release before it appears.
Pages deploys on every push while archives only publish on a tag, so a
package with no archive behind it is left out of `index.txt` entirely.
The site can only ever advertise what `get` can actually fetch —
without that rule it advertises packages that 404, which is exactly
what happened to webi, btop, shfmt and socat.

To redeploy the site without touching a package, run the Pages workflow
by hand (`workflow_dispatch`). There is no need to cut a release for it.

## Releases

Tags are `vX.Y.Z`, annotated, and `X` stays `0`.

A tag push is not a marker — `.github/workflows/release.yml` builds
every recipe, publishes a GitHub release with the archives and
`SHA256SUMS`, and dispatches the Pages deploy. Tag only a commit whose
build is green.

**Users never see this number.** They ask for packages by name, and
`get` resolves them through `index.txt`. Nobody should need to know
which unflab they are on, and nothing prompts them to upgrade. The
version is release plumbing — which is an argument for tagging freely
rather than hoarding changes.

### Choosing Y or Z

`scripts/build-key.sh` decides what actually gets rebuilt. It is a
content hash of everything that determines a recipe's artefacts, and
the release job skips any recipe whose key matches the previous
release, copying its archives forward. A release is therefore mostly
unchanged artefacts being republished: v0.3.0 shipped 129 assets and
built three.

So the number says what the release *rebuilt*:

| Change | Rebuilds | Bump |
|---|---|---|
| Site, docs, `generate-docs.py`, docmd config | nothing (live on push) | none |
| A package added, or upstream versions bumped | those recipes only | **Z** |
| `templates/install.sh`, `build.sh`, `package.sh`, `verify.sh` | everything | **Y** |
| A `scripts/lib/*.sh` helper | only recipes sourcing it | **Z** |
| `prereqs.sh`, `check-updates.sh`, `bump.sh`, Makefile, workflows | nothing | none |

**Y is for the installer and for genuinely across-the-board changes** —
`templates/install.sh` ships inside every package, so an installer
bugfix reaches every user and rebuilds every artefact. Keep it
conservative; the aim is that X and Y sit still once the roster
settles.

The last row is the trap. `prereqs.sh` and friends *feel* shared, but
they are not in the build key and change no artefact — verified, not
assumed:

    scripts/build-key.sh <recipe> macos-latest   # before and after

Run that around your change. If the key moves for a recipe you did not
touch, you have a Y. If nothing moves anywhere, you have no release at
all — let it ride along with the next package change.

`scripts/affected.sh` encodes the same three-way split for CI, deciding
which recipes a push actually builds — everything, a scoped few, or
none at all. It is the counterpart to `build-key.sh`: that one answers
"would this artefact differ?" for the release cache, this one answers
"should CI run?", which additionally covers the test scripts. Both
default to doing more work rather than less when a path is unfamiliar,
so a file added to the repo can never silently skip a build.

### Batch package changes into one Z

Several bumps arriving as separate PRs should become **one** Z, not one
each. Merge them all, let `main` build green, then tag once.

This is not only tidiness. `build.yml` uses
`group: build-${{ github.ref }}` with `cancel-in-progress: true`, and
every push to `main` shares that group — so merging a second PR
**cancels the first one's build mid-flight**. A cancelled run reads as
"not failed" at a glance, so the honest state is that neither package
got verified.

Worse, a cancelled run leaves a real gap: change detection builds only
what a push's diff touched, so if merge B cancels merge A's run, B's
run builds only B. A was never built by anything. (This happened while
adding typst: a shfmt merge cancelled the typst build, and the
replacement run built only shfmt.)

`release.yml` has no concurrency group at all, so several tags in quick
succession do not cancel each other — they run concurrently and fight
over a small macOS runner pool instead.

The rhythm that avoids all of it:

1. Merge the PRs you want in the batch.
2. Wait for `main` to go green **once**, after the last merge — that
   run's diff covers every recipe the batch touched.
3. If an earlier run was cancelled and you need certainty about a
   recipe it was building, run `build.yml` via `workflow_dispatch`,
   which has no base diff and so builds everything.
4. Tag one Z.

### Cutting one

1. Confirm `main` is green and your working tree is clean and in sync.
2. `git tag -a vX.Y.Z -F -` with a message naming what changed and why
   — `git tag -l -n1` shows the house style.
3. `git push origin vX.Y.Z`.
4. Watch the run. The release job only publishes if every recipe
   succeeded, so a partial release cannot ship.

Pushing a tag is public and hard to walk back. Confirm with the user
before pushing one unless they have already asked for it.

## Conventions

**Comments explain why, not what.** This codebase's comments record the
reasoning and the failures behind a decision — which mirror got used
and why a signature must come from beside the tarball that served it,
why `|| true` is load-bearing in `build-key.sh`. Match that. A comment
restating the code is noise; the one recording the bug that made the
line necessary is why the code survives.

**macOS ships bash 3.2.** No `mapfile`, and expanding an empty array
under `set -u` is an error. `build.sh` carries comments where both have
already caused failures.

**Don't edit generated files.** `docs/*.md`, `docmd.config.json` and
`site-extra/` come from `make docs`. Edit the recipe or its README.

**Prefer honest scope.** If part of a package doesn't work or isn't
shipped, say so in the README and the recipe comment — the way
`utils/shfmt` records that `--version` reports `(unknown)`, and
`utils/typst` records that `typst update` replaces an unflab binary
with an unverified upstream one. Being straight about a limitation is
worth more than a clean-looking package.
