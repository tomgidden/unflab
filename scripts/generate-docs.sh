#!/usr/bin/env bash
# Generates the docs site's content from the recipes, so it can't drift
# from what the project actually builds:
#
#   docs/<name>.md    one page per utility
#   docs/index.md     the landing page, with the utility table
#   site-extra/get    the curl|sh bootstrap, with URLs substituted
#   site-extra/index.txt  name/version index the bootstrap reads
#
# Run before `docmd build`. Output is regenerated each deploy rather than
# committed.
#
# Usage: scripts/generate-docs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
EXTRA_DIR="$ROOT_DIR/site-extra"

REPO="${UNFLAB_REPO:-tomgidden/unflab}"
BASE_URL="${UNFLAB_BASE_URL:-https://tomgidden.github.io/unflab}"
RELEASE_URL="${UNFLAB_RELEASE_URL:-https://github.com/$REPO/releases/latest/download}"

mkdir -p "$DOCS_DIR" "$EXTRA_DIR"

field() { sed -n "s/^$1=//p" "$2" | tr -d '"' | head -1; }

# Frontmatter values are YAML. A description containing a colon, a quote
# or an apostrophe breaks the parse -- coreutils' logname ships "print
# user\'s login name", roff escape and all, which took docmd's build
# down. Strip stray backslash escapes, then emit a double-quoted scalar
# with the two characters YAML cares about escaped.
yaml_scalar() {
  printf '%s' "$1" \
    | sed -e 's/\\\(.\)/\1/g' \
          -e 's/\\/\\\\/g' \
          -e 's/"/\\"/g' \
    | awk '{printf "\"%s\"", $0}'
}

# Class 1/2/3 -> the honest one-line reason this utility is here.
class_text() {
  case "$1" in
    1) echo "Escapes a dependency tree: Homebrew's build pulls in libraries this tool never touches at run time." ;;
    2) echo "One binary out of a much larger suite." ;;
    3) echo "No dependency problem to solve — it's here so it installs the same way as everything else." ;;
    *) echo "" ;;
  esac
}

: > "$EXTRA_DIR/index.txt"
rows=""

# Navigation entries, accumulated as pages are written. docmd builds its
# sidebar from an explicit `navigation` array rather than the directory
# layout, so it's generated here alongside the pages -- otherwise adding
# a recipe would mean remembering to edit the config by hand.
#
# Recipes emitting one or two packages sit at the top level. A recipe
# emitting many (coreutils' 105) becomes a collapsible group, so it
# doesn't bury the dozen tools that are the point of the collection.
NAV_TOP="$(mktemp)"
NAV_GROUPS="$(mktemp)"
trap 'rm -f "$NAV_TOP" "$NAV_GROUPS"' EXIT

for recipe in "$ROOT_DIR"/utils/*/recipe.sh; do
  [[ -f "$recipe" ]] || continue
  dir="$(dirname "$recipe")"
  name="$(field UNFLAB_NAME "$recipe")"
  version="$(field UNFLAB_VERSION "$recipe")"
  license="$(field UNFLAB_LICENSE "$recipe")"
  homepage="$(field UNFLAB_HOMEPAGE "$recipe")"
  source_url="$(field UNFLAB_SOURCE "$recipe")"
  class="$(field UNFLAB_CLASS "$recipe")"
  # UNFLAB_PACKAGES may be a command substitution -- coreutils builds its
  # list of 105 from utils.txt -- so it has to be evaluated, not scraped.
  # Sourcing in a subshell keeps the recipe's variables and functions out
  # of this script's environment.
  packages="$(
    RECIPE_DIR="$dir" BUILD_ROOT="" bash -c '
      set -eu
      # shellcheck disable=SC1090
      . "$1" >/dev/null 2>&1 || true
      printf "%s" "${UNFLAB_PACKAGES:-$UNFLAB_NAME}"
    ' _ "$recipe"
  )"
  packages="${packages:-$name}"

  # Line 1 of a recipe is "# <name> -- <description>".
  recipe_desc="$(sed -n '1s/^#[^-]*-- *//p' "$recipe")"

  for pkg in $packages; do
    # A multi-package recipe's shared summary ("GNU ftp and telnet
    # clients") is wrong on an individual page, so prefer the first
    # non-empty line of that package's own README.
    desc="$recipe_desc"
    if [[ -f "$dir/README-$pkg.md" ]]; then
      pkg_desc="$(sed -n '3,8p' "$dir/README-$pkg.md" | grep -m1 -v '^$' || true)"
      [[ -n "$pkg_desc" ]] && desc="$pkg_desc"
    elif [[ -f "$dir/descriptions.tsv" ]]; then
      # A recipe emitting many packages (coreutils' 105) can supply a
      # name -> one-liner table, so every page says what that utility
      # actually does rather than repeating the suite's summary.
      pkg_desc="$(awk -F'\t' -v n="$pkg" '$1 == n {print $2; exit}' "$dir/descriptions.tsv")"
      [[ -n "$pkg_desc" ]] && desc="$pkg_desc"
    fi
    printf '%s\t%s\n' "$pkg" "$version" >> "$EXTRA_DIR/index.txt"
    # <recipe> <package> <description>, consumed after the loop.
    printf '%s\t%s\t%s\n' "$name" "$pkg" "$desc" >> "$NAV_GROUPS"
    rows="$rows| [\`$pkg\`]($pkg.md) | $desc | $version | $license |
"

    {
      echo "---"
      # Quoted, because coreutils ships utilities called true, false
      # and yes -- all YAML booleans unquoted, which makes `title` a
      # bool and breaks any plugin that calls a string method on it.
      echo "title: $(yaml_scalar "$pkg")"
      echo "description: $(yaml_scalar "$desc")"
      echo "---"
      echo ""
      echo "# $pkg"
      echo ""
      echo "$desc"
      echo ""
      echo '```sh'
      echo "curl -fsSL $BASE_URL/get | sh -s -- $pkg"
      echo '```'
      echo ""
      echo "Installs to \`~/.local/bin\`. Add \`--prefix /usr/local/bin\` to"
      echo "put it somewhere else, or \`--uninstall\` to remove it."
      echo ""
      echo "## Why it's here"
      echo ""
      echo "$(class_text "$class")"
      echo ""
      echo "## Details"
      echo ""
      echo "| | |"
      echo "|---|---|"
      echo "| Version | $version |"
      echo "| Licence | $license |"
      [[ -n "$homepage" ]] && echo "| Upstream | [$homepage]($homepage) |"
      echo "| Source | [\`$(basename "$source_url")\`]($source_url) |"
      echo ""
      echo "Built from that exact tarball, with its SHA-256 pinned in the"
      echo "recipe. The binary links against nothing outside \`/usr/lib\`"
      echo "and \`/System/\`, checked in CI before release."
      echo ""

      # Fold in the package README's body, minus its title. A recipe
      # emitting several packages gives each its own README-<pkg>.md.
      readme="$dir/README-$pkg.md"
      [[ -f "$readme" ]] || readme="$dir/README.md"
      if [[ -f "$readme" ]]; then
        echo "---"
        echo ""
        tail -n +2 "$readme"
      fi
    } > "$DOCS_DIR/$pkg.md"
    echo "==> docs/$pkg.md"
  done
done

sort -o "$EXTRA_DIR/index.txt" "$EXTRA_DIR/index.txt"

# The bootstrap, with its URLs baked in.
sed -e "s|{{BASE_URL}}|$BASE_URL|g" \
    -e "s|{{RELEASE_URL}}|$RELEASE_URL|g" \
    "$SCRIPT_DIR/templates/get.sh" > "$EXTRA_DIR/get"
chmod +x "$EXTRA_DIR/get"
echo "==> site-extra/get"

# The `unflab` helper, served from the same place. `get` downloads this
# and drops it in beside the binaries it installs.
sed -e "s|{{BASE_URL}}|$BASE_URL|g" \
    "$SCRIPT_DIR/templates/unflab.sh" > "$EXTRA_DIR/unflab"
chmod +x "$EXTRA_DIR/unflab"
echo "==> site-extra/unflab"


# Landing page: the README, with the generated table swapped in for the
# marker, so the site and the repo can't disagree.
{
  echo "---"
  echo "title: unflab"
  echo "---"
  echo ""
  sed -e "s|https://tomgidden.github.io/unflab|$BASE_URL|g" "$ROOT_DIR/README.md"
  echo ""
  echo "## Available now"
  echo ""
  echo "| Utility | What it does | Version | Licence |"
  echo "|---|---|---|---|"
  printf '%s' "$rows"
} > "$DOCS_DIR/index.md"
echo "==> docs/index.md"

# --- navigation ------------------------------------------------------
#
# docmd's sidebar comes from a `navigation` array in docmd.config.json,
# not from the directory layout, so write that config here from what was
# just generated.
#
# Any recipe emitting more than NAV_GROUP_THRESHOLD packages becomes a
# collapsible group. Without this, coreutils' 105 entries bury the dozen
# other tools -- roughly 90% of the sidebar for one suite.
NAV_GROUP_THRESHOLD="${NAV_GROUP_THRESHOLD:-3}"

python3 - "$NAV_GROUPS" "$ROOT_DIR/docmd.config.json" "$BASE_URL" "$NAV_GROUP_THRESHOLD" <<'NAVGEN'
import sys, json, collections

entries_path, config_path, base_url, threshold = sys.argv[1:5]
threshold = int(threshold)

by_recipe = collections.OrderedDict()
for line in open(entries_path):
    recipe, pkg, desc = (line.rstrip("\n").split("\t") + ["", ""])[:3]
    by_recipe.setdefault(recipe, []).append((pkg, desc))

top, groups = [], []
for recipe, pkgs in by_recipe.items():
    if len(pkgs) > threshold:
        # A static group label: no `path`, so the header just groups its
        # children rather than linking to a page that doesn't exist.
        groups.append({
            "title": f"{recipe} ({len(pkgs)})",
            "children": [
                {"title": pkg, "path": f"/{pkg}"} for pkg, _ in sorted(pkgs)
            ],
        })
    else:
        top.extend({"title": pkg, "path": f"/{pkg}"} for pkg, _ in pkgs)

top.sort(key=lambda e: e["title"])
groups.sort(key=lambda g: g["title"])

# Hand-maintained settings live in docmd.config.base.json and are
# committed; only `navigation` is generated. Writing the whole config
# here would mean every run showed a diff, and any theme tweak would be
# silently overwritten.
import os
base_path = os.path.join(os.path.dirname(config_path), "docmd.config.base.json")
if not os.path.exists(base_path):
    sys.exit(f"generate-docs: missing {base_path} -- it holds the "
             "hand-maintained docmd settings that navigation is merged into.")
with open(base_path) as fh:
    config = json.load(fh)

config["url"] = base_url
config["navigation"] = ([{"title": "Overview", "path": "/", "icon": "home"}]
                        + top + groups)

with open(config_path, "w") as fh:
    json.dump(config, fh, indent=2)
    fh.write("\n")

print(f"==> docmd.config.json ({len(top)} top-level, "
      f"{len(groups)} group(s): "
      f"{', '.join(g['title'] for g in groups) or 'none'})")
NAVGEN

# Frontmatter is YAML, and two separate bugs have reached CI through it:
# an apostrophe from a man page (logname), and utilities named true,
# false and yes parsing as booleans rather than strings. Both broke the
# docs build several minutes into a run. Check here instead, where it
# costs nothing -- but only if a YAML parser is available, so this stays
# a lint rather than a hard dependency.
if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null; then
  python3 - "$DOCS_DIR" <<'VALIDATE'
import sys, glob, os, yaml
bad = 0
for f in sorted(glob.glob(os.path.join(sys.argv[1], '*.md'))):
    txt = open(f).read()
    if not txt.startswith('---\n'):
        continue
    try:
        d = yaml.safe_load(txt.split('---\n', 2)[1])
    except Exception as e:
        print(f"  INVALID YAML in {os.path.basename(f)}: {e}"); bad += 1; continue
    for k in ('title', 'description'):
        if k in d and not isinstance(d[k], str):
            print(f"  {os.path.basename(f)}: {k} is {type(d[k]).__name__}, not str "
                  f"({d[k]!r}) -- needs quoting"); bad += 1
if bad:
    print(f"generate-docs: {bad} frontmatter problem(s)", file=sys.stderr)
    sys.exit(1)
VALIDATE
  echo "==> frontmatter validated"
fi
