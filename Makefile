# unflab -- per-utility build, install and packaging.
#
# NOTE: You're probably NOT intending to use this!
#       If you just want to install packages, use the `unflab`
#       Installer instead, which is a lot easier to use
#       and far faster:
#
#           curl -fsSL https://unflab.app/get | sh -s -- ‹utility›
#
#       Of course, you're welcome to use this if you want
#       to build and install your own utilities, to fix things,
#       or you're just curious.
#
#       See the README.md for more information.
#
#   make                 list every utility
#   make ‹utility›            Show options for the specified ‹utility›
#   make ‹utility›.build      fetch, verify, build, stage, and gate it
#   make ‹utility›.install    build (if needed) and install to ~/.local/bin
#   make ‹utility›.package    build (if needed) and make a release archive
#   make ‹utility›.uninstall  remove an installed utility
#   make ‹utility›.prereqs    check/install what building it needs
#
#   make all             build everything
#   make clean           remove build trees, staged output and archives
#
# PREFIX=... overrides the install location, e.g.:
#
#   make wget.install PREFIX=/usr/local/bin

SHELL := /bin/bash
ROOT  := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

UTILS := $(notdir $(wildcard $(ROOT)/utils/*))
ARCH  ?= $(shell uname -m)-apple-darwin
PREFIX ?= $(HOME)/.local/bin

.DEFAULT_GOAL := list

# Only genuine phonies here: naming the pattern-rule targets (%.build
# etc) in .PHONY stops those rules matching at all, and make then reports
# "nothing to be done".
.PHONY: list packages all clean $(UTILS)

# `make list` lists every utility currently available to build.
list:
	@echo ""
	@echo "unflab -- standalone macOS CLI utilities"
	@echo ""
	@echo "Recipes ($(words $(UTILS))):"
	@for u in $(UTILS); do \
	  desc=$$(sed -n '1s/^#[^-]*-- *//p' $(ROOT)/utils/$$u/recipe.sh); \
	  n=$$($(ROOT)/scripts/resolve.sh packages $$u | wc -l | tr -d ' '); \
	  if [ "$$n" -gt 1 ]; then \
	    printf "  %-14s %s (%s packages)\n" "$$u" "$$desc" "$$n"; \
	  else \
	    printf "  %-14s %s\n" "$$u" "$$desc"; \
	  fi; \
	done
	@echo ""
	@echo "Targets take either a package or a recipe name:"
	@echo "  make ftp.install         just ftp"
	@echo "  make inetutils.install   everything that recipe builds (ftp, telnet)"
	@echo "  make coreutils.install   all 105, if you really want them"
	@echo ""
	@echo "Try:  make ‹name›          to see what you can do with one"
	@echo "      make all             to build everything"
	@echo "      make packages        to list every installable package"
	@echo ""

# `make ‹utility›` explains rather than guessing which action was meant.
$(UTILS):
	@u=$@; \
	echo "$$u -- $$(sed -n '1s/^#[^-]*-- *//p' $(ROOT)/utils/$$u/recipe.sh)"; \
	echo ""; \
	grep -E '^UNFLAB_(VERSION|LICENSE|HOMEPAGE)=' $(ROOT)/utils/$$u/recipe.sh \
	  | sed -e 's/^UNFLAB_/  /' -e 's/=/: /'; \
	echo ""; echo ""; \
	pkgs=$$($(ROOT)/scripts/resolve.sh packages $$u); \
	n=$$(echo "$$pkgs" | wc -l | tr -d ' '); \
	if [ "$$n" -gt 1 ]; then \
	  echo "  Builds $$n packages:"; \
	  echo "$$pkgs" | tr '\n' ' ' | fold -w 66 -s | sed 's/^/    /'; \
	  echo ""; \
	fi; \
	echo "  make $$u.prereqs     what building it needs"; \
	echo "  make $$u.build       fetch, verify, build, stage, gate"; \
	echo "  make $$u.install     install to $(PREFIX)"; \
	echo "  make $$u.package     build release archives"; \
	echo "  make $$u.uninstall   remove it"; \
	if [ "$$n" -gt 1 ]; then \
	  first=$$(echo "$$pkgs" | head -1); \
	  echo ""; \
	  echo "  Any single package works too, e.g. 'make $$first.install'."; \
	fi; \
	echo "";

# Targets can name either a package or a recipe, and both are useful:
# `make ftp.install` installs the one binary you want, while
# `make inetutils.install` installs everything that recipe produces and
# `make coreutils.install` installs all 105 deliberately. resolve.sh maps
# the name to the recipe that builds it and to the package(s) it means,
# so building and installing can differ in granularity.

%.build:
	@$(ROOT)/scripts/build.sh $$($(ROOT)/scripts/resolve.sh recipe $*)

# Build only if the packages aren't staged yet, so repeated installs are
# quick. Note the recipe is what gets built, but only the named packages
# get installed -- `make ftp.install` builds inetutils and installs ftp.
%.install:
	@for p in $$($(ROOT)/scripts/resolve.sh packages $*); do 	  test -d $(ROOT)/out/$$p || $(ROOT)/scripts/build.sh $$($(ROOT)/scripts/resolve.sh recipe $*); 	  break; 	done
	@for p in $$($(ROOT)/scripts/resolve.sh packages $*); do 	  $(ROOT)/scripts/install-local.sh $$p $(PREFIX) || exit 1; 	done

%.package:
	@for p in $$($(ROOT)/scripts/resolve.sh packages $*); do 	  test -d $(ROOT)/out/$$p || $(ROOT)/scripts/build.sh $$($(ROOT)/scripts/resolve.sh recipe $*); 	  break; 	done
	@$(ROOT)/scripts/package.sh $(ARCH) $$($(ROOT)/scripts/resolve.sh packages $*)

%.uninstall:
	@for p in $$($(ROOT)/scripts/resolve.sh packages $*); do 	  $(ROOT)/scripts/install-local.sh $$p $(PREFIX) --uninstall || exit 1; 	done

%.prereqs:
	@$(ROOT)/scripts/prereqs.sh $$($(ROOT)/scripts/resolve.sh recipe $*)

# Every installable package, as opposed to every recipe.
packages:
	@$(ROOT)/scripts/resolve.sh list-packages | tr '\n' ' ' | fold -w 74 -s
	@echo ""
	@echo "$$($(ROOT)/scripts/resolve.sh list-packages | wc -l | tr -d ' ') packages from $(words $(UTILS)) recipes."

all:
	@for u in $(UTILS); do $(ROOT)/scripts/build.sh $$u || exit 1; done

clean:
	@rm -rf $(ROOT)/.build $(ROOT)/out $(ROOT)/dist
	@echo "Removed .build/, out/ and dist/"
