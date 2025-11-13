#!/bin/bash
# Screenshot script that preserves window visibility during selection

# Colors
NEON_PINK="ff00ffaa"
NEON_BLUE="00d8ffaa"
BG_COLOR="00000088"

# Directories
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Function to take screenshot
screenshot_mode() {
    local mode="${1:-region}"
    
    case "$mode" in
        region)
            # Freeze Hyprland animations during selection
            hyprctl keyword misc:no_vfr 1
            hyprctl keyword animations:enabled 0
            
            # Take screenshot with selection
            grim -g "$(slurp -d -c ${NEON_PINK} -b ${BG_COLOR} -w 2)" - | wl-copy -t image/png
            
            # Re-enable animations
            hyprctl keyword animations:enabled 1
            hyprctl keyword misc:no_vfr 0
            
            notify-send "📸 Screenshot" "Region copied to clipboard" -i edit-copy
            ;;
            
        region-edit)
            # Freeze animations
            hyprctl keyword misc:no_vfr 1
            hyprctl keyword animations:enabled 0
            
            # Capture and edit
            grim -g "$(slurp -d -c ${NEON_BLUE} -b ${BG_COLOR} -w 2)" - | swappy -f -
            
            # Re-enable animations
            hyprctl keyword animations:enabled 1
            hyprctl keyword misc:no_vfr 0
            ;;
            
        *)
            echo "Usage: $0 {region|region-edit}"
            ;;
    esac
}

screenshot_mode "$1"
