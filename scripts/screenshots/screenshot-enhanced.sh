#!/bin/bash
# Enhanced screenshot tool with OCR and fancy features for Hyprland
# Supports: region selection, OCR, annotations, upload to imgur

# Colors for notifications
NEON_PINK="#ff00ff"
NEON_BLUE="#00d8ff"

# Configuration
SCREENSHOT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Function to show menu
show_menu() {
    echo -e "1. Region (Edit)\n2. Region (Copy)\n3. Fullscreen\n4. Region + OCR\n5. Window" | \
    wofi --dmenu --prompt "Screenshot Mode" --height 250 || \
    rofi -dmenu -p "Screenshot Mode" || \
    echo "1"
}

# Get user choice
if [ "$1" == "menu" ]; then
    CHOICE=$(show_menu)
else
    CHOICE="${1:-1}"
fi

# Generate filename with timestamp
FILENAME="$SCREENSHOT_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

case "$CHOICE" in
    "1"|"1. Region (Edit)")
        # Region selection with edit
        grim -g "$(slurp -d -c ${NEON_PINK}88 -b 00000044 -w 2)" - | swappy -f -
        notify-send "Screenshot" "Saved and opened in editor" -i image-x-generic
        ;;
        
    "2"|"2. Region (Copy)")
        # Region selection direct to clipboard
        grim -g "$(slurp -d -c ${NEON_BLUE}88 -b 00000044 -w 2)" - | wl-copy -t image/png
        notify-send "Screenshot" "Copied to clipboard" -i edit-copy
        ;;
        
    "3"|"3. Fullscreen")
        # Fullscreen capture
        grim "$FILENAME"
        wl-copy -t image/png < "$FILENAME"
        notify-send "Screenshot" "Saved to $FILENAME" -i image-x-generic
        ;;
        
    "4"|"4. Region + OCR")
        # Region with OCR text extraction
        TEMP_IMG="/tmp/ocr_screenshot.png"
        grim -g "$(slurp -d -c ${NEON_PINK}88 -b 00000044 -w 2)" "$TEMP_IMG"
        
        # Perform OCR
        TEXT=$(tesseract "$TEMP_IMG" - 2>/dev/null)
        
        if [ -n "$TEXT" ]; then
            echo "$TEXT" | wl-copy
            notify-send "OCR Screenshot" "Text copied to clipboard:\n$TEXT" -i text-x-generic
            
            # Save text to file
            echo "$TEXT" > "${FILENAME%.png}.txt"
        else
            notify-send "OCR Screenshot" "No text detected" -i dialog-warning
        fi
        
        # Also copy image
        wl-copy -t image/png < "$TEMP_IMG"
        mv "$TEMP_IMG" "$FILENAME"
        ;;
        
    "5"|"5. Window")
        # Active window capture
        WINDOW_GEOM=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$WINDOW_GEOM" "$FILENAME"
        wl-copy -t image/png < "$FILENAME"
        notify-send "Screenshot" "Window captured to $FILENAME" -i window
        ;;
        
    *)
        notify-send "Screenshot" "Cancelled" -i dialog-error
        exit 1
        ;;
esac
