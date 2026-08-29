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

for recipe in "$ROOT_DIR"/utils/*/recipe.sh; do
  [[ -f "$recipe" ]] || continue
  dir="$(dirname "$recipe")"
  name="$(field UNFLAB_NAME "$recipe")"
  version="$(field UNFLAB_VERSION "$recipe")"
  license="$(field UNFLAB_LICENSE "$recipe")"
  homepage="$(field UNFLAB_HOMEPAGE "$recipe")"
  source_url="$(field UNFLAB_SOURCE "$recipe")"
  class="$(field UNFLAB_CLASS "$recipe")"
  packages="$(field UNFLAB_PACKAGES "$recipe")"
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
    fi
    printf '%s\t%s\n' "$pkg" "$version" >> "$EXTRA_DIR/index.txt"
    rows="$rows| [\`$pkg\`]($pkg.md) | $desc | $version | $license |
"

    {
      echo "---"
      echo "title: $pkg"
      echo "description: $desc"
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

# Landing page: the README, with the generated table swapped in for the
# marker, so the site and the repo can't disagree.
{
  echo "---"
  echo "title: unflab"
  echo "description: Small, self-contained macOS command-line tools."
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
