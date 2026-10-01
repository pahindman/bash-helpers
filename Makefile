# Default install directory
PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
REPO_DIR := $(shell pwd)

# Use symlinks unless the user specifies otherwise
USE_SYMLINKS ?= 1

# Find all *.bash files at the base of the repo
SCRIPTS := $(wildcard *.bash)
INSTALLED_SCRIPTS := $(addprefix $(BIN_DIR)/, $(SCRIPTS))

#### INSTALL TARGETS ####
ifeq ($(USE_SYMLINKS),1)
    INSTALL_CMD = ln -sf $(realpath $<) $@ && echo "Linked $@ -> $(realpath $<)"
else
    INSTALL_CMD = cp $< $@ && echo "Copied $(realpath $<) to $@"
endif

.PHONY: install

install: install-scripts

install-scripts: $(INSTALLED_SCRIPTS)
	@echo "Script installation complete. Ensure $(BIN_DIR) is in your PATH."

$(BIN_DIR)/%.bash: %.bash | $(BIN_DIR)
	@$(INSTALL_CMD)

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

#### UNINSTALL TARGETS ####
.PHONY: uninstall

uninstall: uninstall-scripts

# Uninstall scripts only if they are symlinks pointing to the repo
uninstall-scripts:
	@for script in $(SCRIPTS); do \
		installed_script="$(BIN_DIR)/$$script"; \
		if [ "$(USE_SYMLINKS)" -eq 1 ]; then \
			if [ -L "$$installed_script" ]; then \
				link_target=$$(readlink "$$installed_script"); \
				if [ "$$link_target" = "$(REPO_DIR)/$$script" ]; then \
					rm -f "$$installed_script"; \
					echo "Removed $$installed_script"; \
				else \
					echo "Skipped $$installed_script (symlink points elsewhere: $$link_target)"; \
				fi; \
			elif [ -e "$$installed_script" ]; then \
				echo "Skipped $$installed_script (not a symlink)"; \
			fi; \
		else \
			if [ -L "$$installed_script" ]; then \
				echo "Skipped $$installed_script (is a symlink, expected regular file)"; \
			elif [ -e "$$installed_script" ]; then \
				rm -f "$$installed_script"; \
				echo "Removed $$installed_script"; \
			fi; \
		fi; \
	done

