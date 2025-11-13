#!/bin/bash
# Advanced screenshot with OCR integration
set -euo pipefail

# Dependencies: grim, slurp, swappy, tesseract, wl-clipboard, imagemagick

# Neon colors for selection
NEON_PINK="#ff00ff"
NEON_BLUE="#00d8ff"
NEON_GREEN="#00ff9f"

# Directories
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
OCR_DIR="$HOME/Documents/OCR"
mkdir -p "$SCREENSHOT_DIR" "$OCR_DIR"

# Temp file
TEMP_IMG="/tmp/screenshot_$$.png"

# Function to perform OCR
do_ocr() {
    local img="$1"
    local output="${2:-}"
    
    # Preprocess image for better OCR (increase contrast, denoise)
    convert "$img" -colorspace gray -contrast-stretch 2%x2% -despeckle "$TEMP_IMG.processed.png"
    
    # Perform OCR with multiple languages if available
    local text=$(tesseract "$TEMP_IMG.processed.png" - -l eng 2>/dev/null || tesseract "$img" - 2>/dev/null)
    
    if [ -n "$text" ]; then
        echo "$text" | wl-copy
        notify-send -i text-x-generic "📋 OCR Complete" "$text" -t 5000
        
        if [ -n "$output" ]; then
            echo "$text" > "$output"
            notify-send -i document-save "💾 OCR Saved" "Text saved to $output"
        fi
        
        return 0
    else
        notify-send -i dialog-warning "OCR Failed" "No text detected in image"
        return 1
    fi
}

# Main logic
case "${1:-region}" in
    region)
        # Interactive region selection
        grim -g "$(slurp -d -c ${NEON_PINK}aa -b 00000066 -w 2)" "$TEMP_IMG"
        swappy -f "$TEMP_IMG" -o "$SCREENSHOT_DIR/$(date +%Y%m%d_%H%M%S).png"
        ;;
        
    region-ocr)
        # Region with immediate OCR
        grim -g "$(slurp -d -c ${NEON_BLUE}aa -b 00000066 -w 2)" "$TEMP_IMG"
        wl-copy -t image/png < "$TEMP_IMG"
        do_ocr "$TEMP_IMG" "$OCR_DIR/ocr_$(date +%Y%m%d_%H%M%S).txt"
        cp "$TEMP_IMG" "$SCREENSHOT_DIR/ocr_$(date +%Y%m%d_%H%M%S).png"
        ;;
        
    fullscreen)
        # Full screen capture
        grim "$TEMP_IMG"
        swappy -f "$TEMP_IMG" -o "$SCREENSHOT_DIR/fullscreen_$(date +%Y%m%d_%H%M%S).png"
        ;;
        
    window)
        # Active window capture
        local geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$geom" "$TEMP_IMG"
        swappy -f "$TEMP_IMG" -o "$SCREENSHOT_DIR/window_$(date +%Y%m%d_%H%M%S).png"
        ;;
        
    clipboard-ocr)
        # OCR from clipboard image
        wl-paste -t image/png > "$TEMP_IMG" 2>/dev/null || {
            notify-send -i dialog-error "No Image" "No image in clipboard"
            exit 1
        }
        do_ocr "$TEMP_IMG" "$OCR_DIR/clipboard_ocr_$(date +%Y%m%d_%H%M%S).txt"
        ;;
        
    *)
        echo "Usage: $0 {region|region-ocr|fullscreen|window|clipboard-ocr}"
        exit 1
        ;;
esac

# Cleanup
rm -f "$TEMP_IMG" "$TEMP_IMG.processed.png" 2>/dev/null || true
