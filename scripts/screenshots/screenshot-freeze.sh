#!/bin/bash
# Screenshot with frozen desktop preview for region selection (Hyprland/Wayland)
# Uses satty for region selection and annotation

set -euo pipefail

SCREENSHOT_DIR="${XDG_SCREENSHOTS_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}/Screenshots"
mkdir -p "$SCREENSHOT_DIR"
OUT_FILE="$SCREENSHOT_DIR/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
TEMP_FULL="/tmp/screenshot_fullscreen_$$.png"

# Take a fullscreen screenshot
grim "$TEMP_FULL"

# Open in satty for region selection and annotation
satty --filename "$TEMP_FULL" --output-filename "$OUT_FILE" --copy-command wl-copy

sleep 0.2
hyprctl dispatch focuswindow satty

notify-send "📸 Screenshot" "Region copied to clipboard and saved as $OUT_FILE" -i edit-copy

rm -f "$TEMP_FULL"
