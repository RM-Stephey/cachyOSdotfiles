#!/bin/bash
# Professional OCR with multiple enhancement techniques

TEMP_DIR="/tmp/ocr_$$"
mkdir -p "$TEMP_DIR"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Function to try different preprocessing methods
multi_process_ocr() {
    local input="$1"
    local best_text=""
    local best_confidence=0
    
    # Method 1: High DPI screen text (your case)
    convert "$input" \
        -modulate 100,0 \
        -resize 200% \
        -sharpen 0x1.0 \
        -white-threshold 60% \
        "$TEMP_DIR/method1.png"
    
    # Method 2: For light/dark themes
    convert "$input" \
        -resize 200% \
        -colorspace gray \
        -negate \
        -lat 25x25+10% \
        -negate \
        "$TEMP_DIR/method2.png"
    
    # Method 3: Edge detection for better character boundaries
    convert "$input" \
        -resize 200% \
        -colorspace Gray \
        -edge 1 \
        -negate \
        -threshold 50% \
        "$TEMP_DIR/method3.png"
    
    # Try OCR with each method
    for method in "$TEMP_DIR"/method*.png; do
        # Use PSM 3 (fully automatic page segmentation)
        tesseract "$method" stdout --psm 3 -l eng 2>/dev/null
        echo "---METHOD SEPARATOR---"
    done | head -n 100
}

# Main capture and OCR
case "${1:-region}" in
    region)
        grimblast --freeze save area "$TEMP_DIR/capture.png"
        if [ -f "$TEMP_DIR/capture.png" ]; then
            # Get all OCR attempts
            ALL_TEXT=$(multi_process_ocr "$TEMP_DIR/capture.png")
            
            # Use the first non-empty result
            TEXT=$(echo "$ALL_TEXT" | sed '/---METHOD SEPARATOR---/,$d' | grep -v '^$' | head -50)
            
            if [ -n "$TEXT" ]; then
                echo "$TEXT" | wl-copy
                notify-send "📋 OCR Complete" "$TEXT" -t 10000
            else
                notify-send "OCR Failed" "Try adjusting selection or zoom level"
            fi
        fi
        ;;
esac
