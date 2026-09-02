#!/usr/bin/env python3
#
# Generates the docs site's content from the recipes, so it can't drift
# from what the project actually builds:
#
#   docs/<name>.md        one page per utility
#   docs/index.md         the landing page, with the utility table
#   site-extra/get        the curl|sh bootstrap, with URLs substituted
#   site-extra/unflab     the helper, likewise
#   site-extra/index.txt  name/recipe/version index the bootstrap reads
#   docmd.config.json     the sidebar, merged into the committed base
#
# Run before `docmd build`. Output is regenerated each deploy rather
# than committed.
#
# Usage: scripts/generate-docs.py
#
# Environment: UNFLAB_REPO, UNFLAB_BASE_URL, UNFLAB_RELEASE_URL,
# NAV_GROUP_THRESHOLD -- same names the shell version used.

import collections
import json
import os
import re
import subprocess
import sys

# This script's directory.
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# The repo's root directory.
ROOT_DIR = os.path.dirname(SCRIPT_DIR)

# The destination directory for the docs for the GitHub Pages site.
DOCS_DIR = os.path.join(ROOT_DIR, "docs")

# The extra (non-docmd) files for the GitHub Pages site.
EXTRA_DIR = os.path.join(ROOT_DIR, "site-extra")

# The GH name of the repo
REPO = os.environ.get("UNFLAB_REPO", "tomgidden/unflab")

# The URL to use for the bootstrap.
BASE_URL = os.environ.get("UNFLAB_BASE_URL", "https://unflab.app")

# Template for the index page
INDEX_TEMPLATE = os.path.join(ROOT_DIR, "README.md")

# The URL to use for the bootstrap's release assets.
RELEASE_URL = os.environ.get(
    "UNFLAB_RELEASE_URL",
    f"https://github.com/{REPO}/releases/latest/download",
)

# A recipe emitting more than this many packages becomes a collapsible
# sidebar group, and moves to its own table at the foot of the index.
# Without it, coreutils' entries bury the handful of other tools that
# are the point of the collection.
NAV_GROUP_THRESHOLD = int(os.environ.get("NAV_GROUP_THRESHOLD", "3"))


# Recipes

def field(name, path):
    """Scrape a simple KEY=value line out of a recipe."""
    pat = re.compile(rf"^{re.escape(name)}=(.*)$", re.M)
    m = pat.search(open(path, encoding="utf-8").read())
    return m.group(1).strip().strip('"').strip("'") if m else ""


def packages_of(recipe, dir_, fallback):
    """
    The package list, which may be a command substitution -- coreutils
    builds its huge list from utils.txt -- so it has to be evaluated,
    not scraped. Sourcing in a subshell keeps the recipe's variables and
    functions out of this process.
    """
    script = (
        'set -eu\n'
        '. "$1" >/dev/null 2>&1 || true\n'
        'printf "%s" "${UNFLAB_PACKAGES:-${UNFLAB_NAME:-}}"\n'
    )
    out = subprocess.run(
        ["bash", "-c", script, "_", recipe],
        capture_output=True, text=True,
        env={**os.environ, "RECIPE_DIR": dir_, "BUILD_ROOT": ""},
    ).stdout.split()
    return out or [fallback]


def describe(dir_, pkg, recipe_desc):
    """
    A multi-package recipe's shared summary ("GNU ftp and telnet
    clients") is wrong on an individual page, so prefer a description
    from the package's own README, or the recipe's descriptions.tsv.
    """

    # Load the package-specific README, if it exists.
    readme = os.path.join(dir_, f"README-{pkg}.md")
    if os.path.exists(readme):
        # Skip the heading; take the first non-empty line after it.
        for line in open(readme, encoding="utf-8").read().splitlines()[2:8]:
            # If that line is non-empty, return it.
            if line.strip(): return line.strip()

    tsv = os.path.join(dir_, "descriptions.tsv")
    if os.path.exists(tsv):
        for line in open(tsv, encoding="utf-8"):
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 2 and parts[0] == pkg and parts[1].strip():
                return parts[1].strip()

    return recipe_desc


CLASS_TEXT = {
    "1": "Escapes a dependency tree: Homebrew's build pulls in libraries "
         "this tool never touches at run time.",
    "2": "One binary out of a much larger suite.",
    "3": "No dependency problem to solve — it's here so it installs the "
         "same way as everything else.",
}


def yaml_scalar(s):
    """
    Frontmatter values are YAML. A description containing a colon, a
    quote or an apostrophe breaks the parse -- coreutils' logname ships
    "print user\\'s login name", roff escape and all, which took docmd's
    build down. Strip stray backslash escapes, then emit a double-quoted
    scalar with the two characters YAML cares about escaped.

    Quoting matters for `title` too: coreutils ships utilities called
    true, false and yes, all YAML booleans unquoted -- which makes
    `title` a bool and breaks any plugin calling a string method on it.
    """
    s = re.sub(r"\\(.)", r"\1", s)
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

# Collect
# -------

Package = collections.namedtuple(
    "Package", "name recipe version license homepage source desc dir class_"
)

packages = []

for entry in sorted(os.listdir(os.path.join(ROOT_DIR, "utils"))):
    dir_ = os.path.join(ROOT_DIR, "utils", entry)
    recipe = os.path.join(dir_, "recipe.sh")
    if not os.path.isfile(recipe):
        continue

    name = field("UNFLAB_NAME", recipe)
    version = field("UNFLAB_VERSION", recipe)

    # Line 1 of a recipe is "# <name> -- <description>".
    first = open(recipe, encoding="utf-8").readline()
    m = re.match(r"^#[^-]*--\s*(.*)$", first)
    recipe_desc = m.group(1).strip() if m else ""

    for pkg in packages_of(recipe, dir_, name):
        packages.append(Package(
            name=pkg,
            recipe=name,
            version=version,
            license=field("UNFLAB_LICENSE", recipe),
            homepage=field("UNFLAB_HOMEPAGE", recipe),
            source=field("UNFLAB_SOURCE", recipe),
            desc=describe(dir_, pkg, recipe_desc),
            dir=dir_,
            class_=field("UNFLAB_CLASS", recipe),
        ))

# Reconcile against a release
# ---------------------------

# By default the site describes the working tree. That is right for a
# local `make docs`, but wrong for the published site: Pages deploys on
# every push while archives only publish on a tag, so a package added
# between tags would be advertised with no download behind it. That gap
# is what made `get webi` return a 404.
#
# With UNFLAB_RELEASE_MANIFEST pointing at a file of asset names, the
# download-facing data is taken from the release instead: a package is
# listed only if an archive for it exists, at the version that archive
# carries. Prose still comes from the working tree, so docs edits go
# live on push -- only what `get` acts on is pinned to the release.
manifest = os.environ.get("UNFLAB_RELEASE_MANIFEST")
if manifest:
    # Asset names are unflab-<name>-<version>-<arch>.tar.gz. The name
    # may contain dashes (sha256sum) and so may the arch triple, so
    # anchor on the known suffix and take the last dash-separated field
    # before it as the version.
    shipped = {}
    with open(manifest, encoding="utf-8") as fh:
        for line in fh:
            m = re.match(r"^unflab-(.+)-([^-]+)-[^-]+-apple-darwin\.tar\.gz$",
                         line.strip())
            if m:
                shipped[m.group(1)] = m.group(2)

    if not shipped:
        sys.exit(f"generate-docs: no assets parsed from {manifest}")

    missing = sorted({p.name for p in packages} - set(shipped))
    packages = [p._replace(version=shipped[p.name])
                for p in packages if p.name in shipped]

    print(f"==> release manifest: {len(packages)} package(s) shipped"
          + (f", {len(missing)} not yet released: {' '.join(missing)}"
             if missing else ""))

os.makedirs(DOCS_DIR, exist_ok=True)
os.makedirs(EXTRA_DIR, exist_ok=True)

# Which recipes are big enough to be grouped -- used for both the
# sidebar and the index table, so the two can't disagree.
counts = collections.Counter(p.recipe for p in packages)
big = {r for r, n in counts.items() if n > NAV_GROUP_THRESHOLD}


# Pages
# -----

for p in packages:
    out = [
        "---",
        f"title: {yaml_scalar(p.name)}",
        f"description: {yaml_scalar(p.desc)}",
        "---",
        "",
        f"# {p.name}",
        "",
        p.desc,
        "",
        "```sh",
        f"curl -fsSL {BASE_URL}/get | sh -s -- {p.name}",
        "```",
        "",
        "Installs to `~/.local/bin`. Add `--prefix /usr/local/bin` to",
        "put it somewhere else, or `--uninstall` to remove it.",
        "",
    ]

    if CLASS_TEXT.get(p.class_):
        out += ["## Why it's here", "", CLASS_TEXT[p.class_], ""]

    out += [
        "## Details", "",
        "| | |", "|---|---|",
        f"| Original package | {p.recipe} |",
        f"| Version | {p.version} |",
        f"| Licence | {p.license} |",
    ]
    if p.homepage:
        out.append(f"| Upstream | [{p.homepage}]({p.homepage}) |")
    out += [
        f"| Source | [`{os.path.basename(p.source)}`]({p.source}) |",
    ]

    # A direct link to the built archive, but only when the versions
    # came from a real release -- linking one built from the working
    # tree would promise a download that doesn't exist yet.
    if manifest:
        asset = f"unflab-{p.name}-{p.version}-arm64-apple-darwin.tar.gz"
        out += [f"| Download | [`{asset}`]({RELEASE_URL}/{asset}) |"]

    out += [
        "",
        "Built from that exact tarball, with its SHA-256 pinned in the",
        "recipe. The binary links against nothing outside `/usr/lib`",
        "and `/System/`, checked in CI before release.",
        "",
    ]

    # Fold in the package README's body, minus its title. A recipe
    # emitting several packages gives each its own README-<pkg>.md;
    # a big suite may instead share one README-common.md, since a wall
    # of near-identical files would be silly.
    for candidate in (f"README-{p.name}.md", "README-common.md", "README.md"):
        path = os.path.join(p.dir, candidate)
        if os.path.exists(path):
            body = open(path, encoding="utf-8").read().splitlines()[1:]
            # Drop the blank line that followed the heading, so the fold
            # marker isn't left with two blanks under it.
            while body and not body[0].strip():
                body.pop(0)
            out += ["---", ""] + body
            break

    with open(os.path.join(DOCS_DIR, f"{p.name}.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(out).rstrip("\n") + "\n")
    print(f"==> docs/{p.name}.md")


# index.txt
# ---------

# <name> <TAB> <recipe> <TAB> <version>, sorted by name. `get` reads
# this to resolve a name to a release asset.
with open(os.path.join(EXTRA_DIR, "index.txt"), "w", encoding="utf-8") as fh:
    for p in sorted(packages, key=lambda p: p.name):
        fh.write(f"{p.name}\t{p.recipe}\t{p.version}\n")


# site-extra
# ----------

for template, out_name in (("get.sh", "get"), ("unflab.sh", "unflab")):
    src = open(os.path.join(SCRIPT_DIR, "templates", template),
               encoding="utf-8").read()
    src = src.replace("{{BASE_URL}}", BASE_URL)
    src = src.replace("{{RELEASE_URL}}", RELEASE_URL)
    path = os.path.join(EXTRA_DIR, out_name)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(src)
    os.chmod(path, 0o755)
    print(f"==> site-extra/{out_name}")


# index page
# ----------


def table(rows):
    out = ["| Utility | What it does | Original Package | Version | Licence |",
           "|---|---|---|---|---|"]
    for p in rows:
        out.append(f"| [`{p.name}`]({p.name}.md) | {p.desc} | "
                   f"{p.recipe} | {p.version} | {p.license} |")
    return out


index_template = open(INDEX_TEMPLATE, encoding="utf-8").read()
index_template = index_template.replace("https://unflab.app", BASE_URL)

# Add a link above the first ## heading, so it's easy to find.
index_template = index_template.replace(
    "\n##", 
    "\n* [Skip to the package list](#available-now)\n##",
    1
)

# Start by building the list of packages
index = []

# Small recipes first, alphabetically. A big suite goes in its own
# table below rather than swamping this one -- same reasoning as the
# sidebar grouping, and driven by the same threshold.
index += table(sorted((p for p in packages if p.recipe not in big),
                      key=lambda p: p.name))

for recipe in sorted(big):
    rows = sorted((p for p in packages if p.recipe == recipe),
                  key=lambda p: p.name)
    index += ["", f"### {recipe} ({len(rows)})", ""]
    index += table(rows)

# Add the table at the first --- divider in the template.
preamble, postamble = index_template.split("---", 1)
index = ["---", "title: unflab", "---", "", preamble, "", "## Available now", ""] + index + [ postamble ]

with open(os.path.join(DOCS_DIR, "index.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(index).rstrip("\n") + "\n")
print("==> docs/index.md")


# Sidebar
# -------

# docmd's sidebar comes from a `navigation` array in docmd.config.json,
# not from the directory layout, so write that here from what was just
# generated -- otherwise adding a recipe would mean remembering to edit
# the config by hand.
top = [{"title": p.name, "path": f"/{p.name}"}
       for p in packages if p.recipe not in big]
top.sort(key=lambda e: e["title"])

groups = []
for recipe in sorted(big):
    children = sorted((p.name for p in packages if p.recipe == recipe))
    groups.append({
        # A static group label: no `path`, so the header just groups its
        # children rather than linking to a page that doesn't exist.
        "title": f"{recipe} ({len(children)})",
        "children": [{"title": c, "path": f"/{c}"} for c in children],
    })

# Hand-maintained settings live in docmd.config.base.json and are
# committed; only `navigation` is generated. Writing the whole config
# here would mean every run showed a diff, and any theme tweak would be
# silently overwritten.
base_path = os.path.join(ROOT_DIR, "docmd.config.base.json")
if not os.path.exists(base_path):
    sys.exit(f"generate-docs: missing {base_path} -- it holds the "
             "hand-maintained docmd settings that navigation is merged into.")

config = json.load(open(base_path, encoding="utf-8"))
config["url"] = BASE_URL
config["navigation"] = (
    [{"title": "Overview", "path": "/", "icon": "home"}] + top + groups
)

with open(os.path.join(ROOT_DIR, "docmd.config.json"), "w", encoding="utf-8") as fh:
    json.dump(config, fh, indent=2)
    fh.write("\n")

print(f"==> docmd.config.json ({len(top)} top-level, {len(groups)} group(s): "
      f"{', '.join(g['title'] for g in groups) or 'none'})")


# Validation
# ----------

# Catch the frontmatter traps before docmd does: punctuation that breaks
# the parse, and utilities called "true", "yes" and "false" that YAML
# reads as booleans.
try:
    import yaml
except ImportError:
    print("==> frontmatter not validated (no PyYAML)")
    sys.exit(0)

bad = 0
for name in sorted(os.listdir(DOCS_DIR)):
    if not name.endswith(".md"):
        continue
    text = open(os.path.join(DOCS_DIR, name), encoding="utf-8").read()
    if not text.startswith("---\n"):
        continue
    try:
        data = yaml.safe_load(text.split("---\n", 2)[1])
    except Exception as e:
        print(f"  INVALID YAML in {name}: {e}")
        bad += 1
        continue
    for key in ("title", "description"):
        if key in data and not isinstance(data[key], str):
            print(f"  {name}: {key} is {type(data[key]).__name__}, not str "
                  f"({data[key]!r}) -- needs quoting")
            bad += 1

if bad:
    sys.exit(f"generate-docs: {bad} frontmatter problem(s)")

print("==> frontmatter validated")
