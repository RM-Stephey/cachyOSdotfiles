#!/bin/bash
# Alternative screenshot using grimblast-like approach
# Maintains window visibility during selection

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Function for region selection with visible windows
region_screenshot() {
    # Method 1: Use ImageMagick import command (X11 compatibility layer)
    if command -v import >/dev/null 2>&1; then
        import -window root -crop $(slurp -f "%g") png:- | wl-copy -t image/png
        notify-send "📸 Screenshot" "Region captured" -i edit-copy
        return
    fi
    
    # Method 2: Use grim with immediate capture
    # This captures at the moment slurp is invoked
    GEOMETRY=$(slurp -d -c ff00ffaa -b 00000044 -w 2)
    if [ $? -eq 0 ]; then
        sleep 0.1  # Brief delay to ensure windows are back
        grim -g "$GEOMETRY" - | wl-copy -t image/png
        notify-send "📸 Screenshot" "Region captured" -i edit-copy
    fi
}

# Main execution
case "${1:-region}" in
    region)
        region_screenshot
        ;;
    region-edit)
        GEOMETRY=$(slurp -d -c 00d8ffaa -b 00000044 -w 2)
        if [ $? -eq 0 ]; then
            sleep 0.1
            grim -g "$GEOMETRY" - | swappy -f -
        fi
        ;;
    *)
        echo "Usage: $0 {region|region-edit}"
        ;;
esac
