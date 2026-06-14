
mkdir -p ~/.config/niri
cat > ~/.config/niri/init <<'EOF'
#!/usr/bin/env bash
# Niri init script — runs on session start

# Wait a bit for session to be ready (tweak if needed)
sleep 1

# --- Wallpaper (swww) ---
# Initialize swww once
if command -v swww >/dev/null 2>&1; then
  swww init >/dev/null 2>&1 || true
  # Set your wallpaper here (change path)
  WALL="$HOME/Pictures/wallpapers/mywall.jpg"
  if [ -f "$WALL" ]; then
    swww img "$WALL" >/dev/null 2>&1 || true
  fi
fi

# --- Start Waybar (if installed) ---
if command -v waybar >/dev/null 2>&1; then
  # ensure single instance
  pkill -x waybar || true
  WAYBAR_CONFIG="$HOME/.config/waybar/config"
  WAYBAR_STYLE="$HOME/.config/waybar/style.css"
  if [ -f "$WAYBAR_CONFIG" ]; then
    waybar --config "$WAYBAR_CONFIG" --style "$WAYBAR_STYLE" >/dev/null 2>&1 &
  else
    waybar >/dev/null 2>&1 &
  fi
fi

# --- Start sxhkd for global hotkeys (Super+Space -> walker) ---
if command -v sxhkd >/dev/null 2>&1; then
  pkill -x sxhkd || true
  sxhkd -c "$HOME/.config/sxhkd/sxhkdrc" >/dev/null 2>&1 &
fi

# --- Start swaync (if used) ---
if command -v swaync >/dev/null 2>&1; then
  pkill -f swaync || true
  swaync >/dev/null 2>&1 &
fi

# --- Clipboard/history ---
if command -v cliphist >/dev/null 2>&1; then
  # run as background daemon
  pkill -x cliphist || true
  cliphist daemon >/dev/null 2>&1 &
fi

# --- Other helper apps you use in Omarchy defaults ---
# Start any additional apps you want (matugen, dms, etc.)
# matugen (if it has a daemon) and dms-shell are usually started via service.
EOF

