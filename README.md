# dotfiles

One-command, cross-platform dotfiles managed with **GNU Stow**.
Supports macOS + Linux, OS/host overlays, and safe backups of existing files.

## Contents

* `bootstrap.sh` – installs Stow, backs up conflicting files, symlinks packages
* `Makefile` – convenience targets (`install`, `restow`, `unstow`)
* Packages (symlinked into `$HOME`):

  * `zsh/`, `nvim/`, `tmux/`, `ghostty/`
  * macOS only: `aerospace/`
* Optional overlays:

  * `os/Darwin/…`, `os/Linux/…`
  * `hosts/<hostname>/…`

---

## Prereqs

* macOS: Homebrew (`https://brew.sh`)
* Linux: `apt`, `pacman`, or `dnf` (or install `stow` manually)

No other tools needed.

---

## Quick start (new machine)

```bash
git clone https://github.com/<you>/dotfiles ~/dotfiles
cd ~/dotfiles
./bootstrap.sh        # or: make install
```

What this does:

1. Installs **stow** if missing.
2. **Backs up** conflicting files to `~/dotfiles_backup/…`.
3. Symlinks packages into `$HOME`:

   * `~/.zshrc -> ~/dotfiles/zsh/.zshrc`
   * `~/.config/nvim -> ~/dotfiles/nvim/.config/nvim`
   * `~/.tmux.conf -> ~/dotfiles/tmux/.tmux.conf`
   * `~/.config/ghostty -> ~/dotfiles/ghostty/.config/ghostty`
   * macOS: `~/.config/aerospace/aerospace.toml -> ~/dotfiles/aerospace/.config/aerospace/aerospace.toml`
4. Applies `os/<OS>/…` and `hosts/<hostname>/…` overlays if present.

---

## Makefile cheatsheet

These are just shortcuts around Stow commands.

```bash
make install   # run bootstrap.sh (safe backups + stow everything)
make restow    # refresh symlinks after you add/rename files in packages
make unstow    # remove symlinks for the known packages
```

> Editing a file (e.g., `zsh/.zshrc`) does **not** require `restow`.
> You only need `restow` when you **add/rename** files or **add a new package**.

---

## Package structure

Each top-level dir is a package:

```
zsh/.zshrc
nvim/.config/nvim/...
tmux/.tmux.conf
ghostty/.config/ghostty/config
aerospace/.config/aerospace/aerospace.toml   # macOS only
```

Stow will link each package’s contents into `$HOME`.

---

## Overlays (optional)

Use overlays for small OS/host-specific tweaks without forking an entire package.

```
os/Darwin/zsh/.zshrc.local    # applied only on macOS
os/Linux/zsh/.zshrc.local     # applied only on Linux

hosts/<hostname>/zsh/.zshrc.local
```

These are symlinked **after** the base packages, so they can override.

Get your host name with:

```bash
hostname
```

Create the matching folder under `hosts/`.

---

## Adding a new package

1. Create a top-level folder that mirrors the target path under `$HOME`, for example:

```
alacritty/.config/alacritty/alacritty.yml
```

2. Run:

```bash
make restow
```

macOS/Linux-specific? Add the package name to `MAC_PACKAGES` or `LINUX_PACKAGES` arrays in `bootstrap.sh`.

---

## Adopting existing files into the repo (optional)

If you want to pull an unmanaged file into a package **and** create the symlink:

```bash
# Example: adopt an existing ~/.gitconfig into git/.gitconfig
mkdir -p git
stow --adopt -v -t "$HOME" git
git status
git add -A && git commit -m "adopt: import existing gitconfig"
```

Always check `git status` before committing.

---

## Backups & restoring

First run (and every run, by design) moves conflicting files into:

```
~/dotfiles_backup/...
```

If you want to restore something:

```bash
mv ~/dotfiles_backup/path/to/file ~/.config/...   # or wherever it belongs
make restow
```

Delete `~/dotfiles_backup` whenever you’re satisfied.

---

## Verifying symlinks

```bash
# Example checks
ls -l ~/.zshrc
ls -l ~/.tmux.conf
ls -l ~/.config/nvim
ls -l ~/.config/ghostty
```

You should see each pointing back into `~/dotfiles/...`.

---

## Common gotchas

* **“All operations aborted”**: means a file blocked Stow. `bootstrap.sh` now auto-backs it up and re-runs stow.
* **Editing files doesn’t “apply”**: symlinks point to the repo. Editing either side is the same file; no restow needed.
* **New file not linked**: run `make restow` (or re-run `./bootstrap.sh`) after adding/renaming files.
* **Wrong hostname overlay**: check `hostname` and your folder under `hosts/` matches exactly (case-sensitive).

---

## Uninstall everything (non-destructive)

Removes symlinks but leaves the repo and backups:

```bash
make unstow
```

---

## FAQ

**Why Stow?**
Minimal, predictable symlink management. No magic.

**Where are my old configs?**
`~/dotfiles_backup/…` (created automatically before linking).

**How do I add macOS-only stuff later?**
Put a package at the root and add its name to `MAC_PACKAGES` in `bootstrap.sh`. Or place it under `os/Darwin/<pkg>/…`.

