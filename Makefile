SHELL := /bin/bash
OS := $(shell uname -s)
PACKAGES := zsh nvim tmux
MAC_PACKAGES := ghostty aerospace yabai skhd
HOME_DIR := $(HOME)

ifeq ($(OS),Darwin)
PACKAGES += $(MAC_PACKAGES)
endif

.PHONY: install restow unstow

install:
	@./bootstrap.sh

restow:
	@echo "Restowing packages..."
	@stow -vDt $(HOME_DIR) $(PACKAGES) || true
	@stow -vSt $(HOME_DIR) $(PACKAGES)

unstow:
	@echo "Unstowing packages..."
	@stow -vDt $(HOME_DIR) $(PACKAGES) || true
