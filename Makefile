# unflab -- per-utility build, install and packaging.
#
#   make                 list every utility
#   make tree            explain what you can do with tree
#   make tree.build      fetch, verify, build, stage, and gate it
#   make tree.install    build (if needed) and install to ~/.local/bin
#   make tree.package    build (if needed) and make a release archive
#   make tree.uninstall  remove an installed utility
#   make tree.prereqs    check/install what building it needs
#
#   make all             build everything
#   make clean           remove build trees, staged output and archives
#
# PREFIX=... overrides the install location:
#   make tree.install PREFIX=/usr/local/bin

SHELL := /bin/bash
ROOT  := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

UTILS := $(notdir $(wildcard $(ROOT)/utils/*))
ARCH  ?= $(shell uname -m)-apple-darwin
PREFIX ?= $(HOME)/.local/bin

.DEFAULT_GOAL := list
# Only genuine phonies here: naming the pattern-rule targets (%.build
# etc) in .PHONY stops those rules matching at all, and make then reports
# "nothing to be done".
.PHONY: list all clean $(UTILS)

list:
	@echo "unflab -- standalone macOS CLI utilities"
	@echo ""
	@echo "Utilities ($(words $(UTILS))):"
	@for u in $(UTILS); do \
	  desc=$$(sed -n '1s/^#[^-]*-- *//p' $(ROOT)/utils/$$u/recipe.sh); \
	  printf "  %-14s %s\n" "$$u" "$$desc"; \
	done
	@echo ""
	@echo "Try:  make <utility>        to see what you can do with one"
	@echo "      make all              to build everything"

# `make tree` explains rather than guessing which action was meant.
$(UTILS):
	@u=$@; \
	echo "$$u -- $$(sed -n '1s/^#[^-]*-- *//p' $(ROOT)/utils/$$u/recipe.sh)"; \
	echo ""; \
	grep -E '^UNFLAB_(VERSION|LICENSE|HOMEPAGE)=' $(ROOT)/utils/$$u/recipe.sh \
	  | sed -e 's/^UNFLAB_/  /' -e 's/=/: /'; \
	echo ""; \
	echo "  make $$u.prereqs     what building it needs"; \
	echo "  make $$u.build       fetch, verify, build, stage, gate"; \
	echo "  make $$u.install     install to $(PREFIX)"; \
	echo "  make $$u.package     build a release archive"; \
	echo "  make $$u.uninstall   remove it"

%.build:
	@$(ROOT)/scripts/build.sh $*

# Build only if it hasn't been staged yet, so repeated installs are quick.
%.install:
	@test -d $(ROOT)/out/$* || $(ROOT)/scripts/build.sh $*
	@$(ROOT)/scripts/install-local.sh $* $(PREFIX)

%.package:
	@test -d $(ROOT)/out/$* || $(ROOT)/scripts/build.sh $*
	@$(ROOT)/scripts/package.sh $(ARCH) $*

%.uninstall:
	@$(ROOT)/scripts/install-local.sh $* $(PREFIX) --uninstall

%.prereqs:
	@$(ROOT)/scripts/prereqs.sh $*

all:
	@for u in $(UTILS); do $(ROOT)/scripts/build.sh $$u || exit 1; done

clean:
	@rm -rf $(ROOT)/.build $(ROOT)/out $(ROOT)/dist
	@echo "Removed .build/, out/ and dist/"
