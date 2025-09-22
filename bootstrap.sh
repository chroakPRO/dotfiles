#!/usr/bin/env bash
set -euo pipefail

# ---- which packages to stow ----
PACKAGES=(zsh nvim tmux ghostty)   # common to all OSes
MAC_PACKAGES=(aerospace)           # macOS-only packages
LINUX_PACKAGES=()                  # linux-only packages (add later if needed)
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

# Build the full package list for *this* OS (space-separated echo)
build_all_packages() {
  local arr=("${PACKAGES[@]}")
  if [ "$OS" = "Darwin" ] && [ "${#MAC_PACKAGES[@]}" -gt 0 ]; then
    arr+=("${MAC_PACKAGES[@]}")
  fi
  if [ "$OS" = "Linux" ] && [ "${#LINUX_PACKAGES[@]}" -gt 0 ]; then
    arr+=("${LINUX_PACKAGES[@]}")
  fi
  echo "${arr[@]}"
}

# List first-level package dirs under an overlay root (newline-separated)
list_overlay_packages() {
  local root="$1"
  [ -d "$root" ] || return 0
  find "$root" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sed 's|.*/||'
}

# Parse Stow diagnostics and emit absolute target paths to back up (macOS-safe)
# Handles:
#  - "existing target is not a link: <path>"
#  - "existing target is a directory: <path>"
#  - "existing target is not owned by stow: <path>"
#  - "cannot stow <pkg> over existing target <path> since ..."
extract_conflict_paths() {
  local line path
  while IFS= read -r line; do
    if printf '%s\n' "$line" | grep -qE 'existing target is (not a link|a directory|not owned by stow):'; then
      # everything after the last colon+space
      path="${line##*: }"
    elif printf '%s\n' "$line" | grep -q 'cannot stow ' && printf '%s\n' "$line" | grep -q ' over existing target '; then
      # extract between "over existing target " and " since"
      path="$(printf '%s\n' "$line" | sed -n 's/.*over existing target \([^ ]*\) since.*/\1/p')"
      # fallback: if no "since ..." present
      [ -z "${path:-}" ] && path="$(printf '%s\n' "$line" | sed -n 's/.*over existing target \([^ ]*\)$/\1/p')"
      [ -z "${path:-}" ] && continue
    else
      continue
    fi

    # Normalize to absolute path inside $HOME when needed
    case "$path" in
      /*) : ;;
      ~/*) path="${path/#\~/$HOME}" ;;
      ./*) path="$HOME/${path#./}" ;;
      *)   path="$HOME/$path" ;;
    esac

    # Emit only if it actually exists (file, dir, or symlink)
    if [ -e "$path" ] || [ -L "$path" ]; then
      printf '%s\n' "$path"
    fi
  done
}

# Run a stow dry-run and back up any conflicting targets it reports
dry_run_and_backup() {
  local base="$1"; shift
  local pkgs=("$@")
  [ "${#pkgs[@]}" -gt 0 ] || return 0

  echo "Scanning conflicts in: $base [${pkgs[*]}]"

  # Stow prints diagnostics on stderr; capture them
  local diag
  if ! diag="$(stow -nvt "$HOME" -d "$base" "${pkgs[@]}" 2>&1 1>/dev/null)"; then
    : # ignore non-zero exit; we only need the text
  fi

  # Extract paths and move them to backup
  printf '%s\n' "$diag" | extract_conflict_paths | while IFS= read -r target_path; do
    local dst="$HOME/dotfiles_backup/${target_path/#$HOME\//}"
    mkdir -p "$(dirname "$dst")"
    mv "$target_path" "$dst"
    echo "moved $target_path -> $dst"
  done
}

# Always scan & back up conflicts for everything we’re about to stow
backup_conflicts_now() {
  echo "Backing up conflicting dotfiles to ~/dotfiles_backup ..."
  mkdir -p "$HOME/dotfiles_backup"

  # 1) Base + OS-specific package sets
  IFS=' ' read -r -a ALL_PKGS <<<"$(build_all_packages)"
  dry_run_and_backup "." "${ALL_PKGS[@]}"

  # 2) OS overlay (e.g., os/Darwin/* or os/Linux/*)
  local os_root="os/$OS"
  if [ -d "$os_root" ]; then
    mapfile -t OS_OVER_PKGS < <(list_overlay_packages "$os_root")
    [ "${#OS_OVER_PKGS[@]}" -gt 0 ] && dry_run_and_backup "$os_root" "${OS_OVER_PKGS[@]}"
  fi

  # 3) Host overlay (e.g., hosts/<hostname>/*)
  local host_root="hosts/$HOST"
  if [ -d "$host_root" ]; then
    mapfile -t HOST_OVER_PKGS < <(list_overlay_packages "$host_root")
    [ "${#HOST_OVER_PKGS[@]}" -gt 0 ] && dry_run_and_backup "$host_root" "${HOST_OVER_PKGS[@]}"
  fi
}

stow_tree() {
  local base="$1"; shift
  [ "$#" -eq 0 ] && return 0
  for pkg in "$@"; do
    [ -d "$base/$pkg" ] && stow -v -d "$base" -t "$HOME" "$pkg"
  done
}

apply_overlay_dir() {
  local root="$1"  # e.g., os/Linux or hosts/myhost
  [ -d "$root" ] || return 0
  find "$root" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | while IFS= read -r pkg; do
    stow -v -d "$root" -t "$HOME" "$(basename "$pkg")"
  done
}

main() {
  cd "$(dirname "$0")"
  install_stow

  # Always scan + back up conflicts before stowing
  backup_conflicts_now

  echo "Stowing base packages: ${PACKAGES[*]}"
  stow_tree "." "${PACKAGES[@]}"

  if [ "$OS" = "Darwin" ] && [ "${#MAC_PACKAGES[@]}" -gt 0 ]; then
    echo "Stowing macOS-only packages: ${MAC_PACKAGES[*]}"
    stow_tree "." "${MAC_PACKAGES[@]}"
  fi

  if [ "$OS" = "Linux" ] && [ "${#LINUX_PACKAGES[@]}" -gt 0 ]; then
    echo "Stowing Linux-only packages: ${LINUX_PACKAGES[*]}"
    stow_tree "." "${LINUX_PACKAGES[@]}"
  fi

  echo "Applying OS overlay (if any)"
  apply_overlay_dir "os/$OS"

  echo "Applying host overlay (if any): $HOST"
  apply_overlay_dir "hosts/$HOST"

  echo "✔ Dotfiles installed"
  echo "Tip: run 'make restow' after editing files."
}

main "$@"
