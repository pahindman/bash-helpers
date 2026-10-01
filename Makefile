# Default install directory
PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
REPO_DIR := $(shell pwd)

# Find all *.bash files at the base of the repo
SCRIPTS := $(wildcard *.bash)

.PHONY: install uninstall

install:
	@mkdir -p $(BIN_DIR)
	@for script in $(SCRIPTS); do \
		ln -sf "$$(pwd)/$$script" "$(BIN_DIR)/$$script"; \
		echo "Linked $$script -> $(BIN_DIR)/$$script"; \
	done

uninstall:
	@for script in $(SCRIPTS); do \
		target="$(BIN_DIR)/$$script"; \
		if [ -L "$$target" ]; then \
			link_dest=$$(readlink "$$target"); \
			case "$$link_dest" in \
				"$(REPO_DIR)"/*) \
					rm -f "$$target"; \
					echo "Removed $$target (pointed to $(REPO_DIR))"; \
					;; \
				*) \
					echo "Skipped $$target (symlink points elsewhere: $$link_dest)"; \
					;; \
			esac; \
		elif [ -e "$$target" ]; then \
			echo "Skipped $$target (not a symlink)"; \
		fi; \
	done
