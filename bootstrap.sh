#!/usr/bin/env bash
set -euo pipefail

# ---- which packages to stow ----
PACKAGES=(zsh nvim tmux ghostty)
# --------------------------------

OS="$(uname -s)"               # "Linux" or "Darwin"
HOST="$(hostname | tr '[:upper:]' '[:lower:]')"

have() { command -v "$1" >/dev/null 2>&1; }

install_stow() {
  if have stow; then
    echo "✔ stow already installed"
    return
  fi
  case "$OS" in
    Darwin)
      if ! have brew; then
        echo "Homebrew is required on macOS. Install from https://brew.sh"
        exit 1
      fi
      brew install stow
      ;;
    Linux)
      if have apt; then
        sudo apt update && sudo apt install -y stow
      elif have pacman; then
        sudo pacman -Sy --noconfirm stow
      elif have dnf; then
        sudo dnf install -y stow
      else
        echo "No supported package manager found. Please install GNU stow manually."
        exit 1
      fi
      ;;
    *) echo "Unsupported OS: $OS"; exit 1 ;;
  esac
}

backup_conflicts_once() {
  local logfile=".stow-conflicts.log"
  [ -f "$logfile" ] && return 0
  echo "Backing up conflicting dotfiles to ~/dotfiles_backup ..."
  mkdir -p "$HOME/dotfiles_backup"
  # dry-run to find conflicts
  stow -nvt "$HOME" "${PACKAGES[@]}" 2>&1 | \
    awk '/existing target is not a link:/ {print $NF}' | \
    while read -r f; do
      [ -e "$f" ] || continue
      dst="$HOME/dotfiles_backup/${f/#$HOME\//}"
      mkdir -p "$(dirname "$dst")"
      mv "$f" "$dst"
      echo "moved $f -> $dst"
    done
  touch "$logfile"
}

stow_tree() {
  local base="$1"
  shift
  for pkg in "$@"; do
    [ -d "$base/$pkg" ] && stow -v -d "$base" -t "$HOME" "$pkg"
  done
}

apply_overlay_dir() {
  local root="$1"  # e.g., os/Linux or hosts/myhost
  [ -d "$root" ] || return 0
  # stow every first-level dir within the overlay root
  find "$root" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | while IFS= read -r -d '' pkg; do
    stow -v -d "$root" -t "$HOME" "$(basename "$pkg")"
  done
}

main() {
  cd "$(dirname "$0")"
  install_stow
  backup_conflicts_once || true

  echo "Stowing base packages: ${PACKAGES[*]}"
  stow_tree "." "${PACKAGES[@]}"

  echo "Applying OS overlay (if any)"
  apply_overlay_dir "os/$OS"

  echo "Applying host overlay (if any): $HOST"
  apply_overlay_dir "hosts/$HOST"

  echo "✔ Dotfiles installed"
  echo "Tip: run 'make restow' after editing files."
}

main "$@"
