#!/usr/bin/env bash
#
# bootstrap.sh — set up a fresh Arch Linux machine from this repo.
#
# Steps (each is prompted / safe):
#   1. Install GNU Stow + base tooling via pacman.
#   2. Reinstall explicitly-installed repo packages from pkglist.txt.
#   3. Reinstall AUR/foreign packages from aurlist.txt (needs an AUR helper).
#   4. Symlink the dotfiles by calling ./install.sh.
#
# This script NEVER removes packages and NEVER pushes anything.
# Run it on the NEW machine after cloning this repo.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

confirm() { read -rp "$1 [y/N] " a; [[ "$a" == [yY] ]]; }

echo "== dotfiles bootstrap =="

# 1. Core tooling -----------------------------------------------------------
if confirm "Install GNU Stow + git + base-devel via pacman?"; then
  sudo pacman -S --needed --noconfirm stow git base-devel
fi

# 2. Official-repo packages -------------------------------------------------
if [ -f pkglist.txt ] && confirm "Reinstall packages from pkglist.txt (official repos)?"; then
  # --needed skips already-installed; AUR entries in the list are ignored by
  # filtering to those pacman can actually see in the sync DBs.
  mapfile -t want < pkglist.txt
  avail=()
  for p in "${want[@]}"; do
    if pacman -Si "$p" >/dev/null 2>&1; then avail+=("$p"); fi
  done
  echo "   ${#avail[@]} of ${#want[@]} packages are in official repos; installing those."
  sudo pacman -S --needed --noconfirm "${avail[@]}"
fi

# 3. AUR packages -----------------------------------------------------------
if [ -f aurlist.txt ] && confirm "Reinstall AUR packages from aurlist.txt?"; then
  if command -v yay >/dev/null 2>&1; then HELPER=yay
  elif command -v paru >/dev/null 2>&1; then HELPER=paru
  else
    echo "   No AUR helper (yay/paru) found. Install one first, then re-run."
    HELPER=""
  fi
  if [ -n "$HELPER" ]; then
    mapfile -t aur < aurlist.txt
    "$HELPER" -S --needed "${aur[@]}"
  fi
fi

# 4. Stow the dotfiles ------------------------------------------------------
if confirm "Symlink dotfiles into \$HOME now (runs ./install.sh)?"; then
  ./install.sh
fi

echo "== bootstrap complete =="
