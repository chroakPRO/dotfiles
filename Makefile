SHELL := /bin/bash
PACKAGES := zsh nvim tmux ghostty
HOME_DIR := $(HOME)

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
