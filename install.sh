#!/usr/bin/env bash
#
# install.sh — symlink dotfiles into place using GNU Stow.
#
# SAFE BY DEFAULT:
#   * Uses `stow`, which REFUSES to overwrite existing real files (it errors
#     instead of clobbering). Nothing is deleted or force-overwritten.
#   * If you hit conflicts, either back up/remove the offending files yourself,
#     or re-run with --adopt to let stow pull your existing files INTO the repo
#     (review the resulting git diff afterwards).
#   * keyd is special-cased: its config lives in /etc (needs sudo) and the
#     existing file is backed up before being replaced.
#
# Usage:
#   ./install.sh            # stow all packages into $HOME
#   ./install.sh --adopt    # adopt existing files into the repo, then stow
#   ./install.sh fish git   # stow only the named packages
#   ./install.sh --no-keyd  # skip the keyd (sudo /etc) step

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Home-targeted stow packages (each mirrors $HOME).
ALL_PACKAGES=(fish bash git niri alacritty kitty ghostty terminator warp \
              noctalia starship waybar btop fastfetch cava)

STOW_FLAGS=(--verbose --target="$HOME" --restow)
DO_KEYD=1
SELECTED=()

for arg in "$@"; do
  case "$arg" in
    --adopt)   STOW_FLAGS+=(--adopt) ;;
    --no-keyd) DO_KEYD=0 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "Unknown flag: $arg" >&2; exit 2 ;;
    *)         SELECTED+=("$arg") ;;
  esac
done

# If specific packages were named, only stow those.
if [ "${#SELECTED[@]}" -gt 0 ]; then
  PACKAGES=("${SELECTED[@]}")
else
  PACKAGES=("${ALL_PACKAGES[@]}")
fi

if ! command -v stow >/dev/null 2>&1; then
  echo "ERROR: GNU Stow is not installed." >&2
  echo "Install it with:  sudo pacman -S --needed stow" >&2
  exit 1
fi

echo ">> Stowing into \$HOME: ${PACKAGES[*]}"
for pkg in "${PACKAGES[@]}"; do
  if [ ! -d "$pkg" ]; then
    echo "   !! skipping '$pkg' (no such package dir)" >&2
    continue
  fi
  echo "   -> $pkg"
  stow "${STOW_FLAGS[@]}" "$pkg"
done

# ---- keyd (system config, requires sudo) ----
if [ "$DO_KEYD" -eq 1 ] && { [ "${#SELECTED[@]}" -eq 0 ] || printf '%s\n' "${SELECTED[@]}" | grep -qx keyd; }; then
  echo ">> Installing keyd config (requires sudo)"
  # User-level keyd file (non-symlinked copy; harmless if unused by your setup).
  install -Dm644 keyd/basic.conf "$HOME/.config/keyd/basic.conf"

  # System-level /etc/keyd/default.conf — back up any existing file first.
  if [ -f /etc/keyd/default.conf ] && \
     ! sudo cmp -s keyd/default.conf /etc/keyd/default.conf; then
    ts="$(date +%Y%m%d-%H%M%S)"
    echo "   backing up existing /etc/keyd/default.conf -> default.conf.bak.$ts"
    sudo cp -p /etc/keyd/default.conf "/etc/keyd/default.conf.bak.$ts"
  fi
  sudo install -Dm644 keyd/default.conf /etc/keyd/default.conf
  echo "   reloading keyd (if active)"
  sudo systemctl reload keyd 2>/dev/null || sudo keyd reload 2>/dev/null || true
fi

echo ">> Done. Review with: stow --no --verbose --target=\$HOME <pkg>  (dry run)"
