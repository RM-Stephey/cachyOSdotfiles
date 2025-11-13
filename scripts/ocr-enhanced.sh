#!/bin/bash
# Enhanced OCR script with better preprocessing for screen text

# Dependencies: tesseract, imagemagick, wl-clipboard, grimblast

# Temp files
TEMP_IMG="/tmp/ocr_capture_$$.png"
PROCESSED_IMG="/tmp/ocr_processed_$$.png"
OUTPUT_TEXT="/tmp/ocr_output_$$.txt"

# Cleanup on exit
cleanup() {
    rm -f "$TEMP_IMG" "$PROCESSED_IMG" "$OUTPUT_TEXT" 2>/dev/null
}
trap cleanup EXIT

# Enhanced OCR processing
perform_ocr() {
    local input_img="$1"
    
    # Step 1: Preprocess the image for better OCR
    # - Scale up 2x for better character recognition
    # - Convert to grayscale
    # - Increase contrast
    # - Apply threshold to get clean black text on white
    # - Remove noise
    convert "$input_img" \
        -scale 200% \
        -colorspace Gray \
        -sharpen 0x1 \
        -contrast-stretch 0 \
        -threshold 50% \
        -morphology close diamond:1 \
        "$PROCESSED_IMG"
    
    # Step 2: Run Tesseract with optimized settings
    # --psm 6: Uniform block of text
    # -c preserve_interword_spaces=1: Keep spacing
    tesseract "$PROCESSED_IMG" "$OUTPUT_TEXT" \
        --psm 6 \
        -c preserve_interword_spaces=1 \
        -c tessedit_char_whitelist='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz !@#$%^&*()-_=+[]{}|;:,.<>?/~`"'"'"' ' \
        2>/dev/null
    
    # Step 3: Clean up the output
    if [ -f "${OUTPUT_TEXT}.txt" ]; then
        # Remove extra whitespace and clean up
        sed 's/[[:space:]]\+/ /g' "${OUTPUT_TEXT}.txt" | \
        sed 's/^ *//;s/ *$//' | \
        grep -v '^$' > "${OUTPUT_TEXT}.clean"
        
        cat "${OUTPUT_TEXT}.clean"
    else
        echo ""
    fi
}

# Main execution
case "${1:-region}" in
    region)
        # Capture region with grimblast
        grimblast --freeze save area "$TEMP_IMG"
        
        if [ -f "$TEMP_IMG" ]; then
            TEXT=$(perform_ocr "$TEMP_IMG")
            
            if [ -n "$TEXT" ]; then
                echo "$TEXT" | wl-copy
                notify-send "📋 OCR Success" "$TEXT" -t 10000
                echo "Extracted text:"
                echo "$TEXT"
            else
                notify-send "OCR Failed" "No text detected" -i dialog-warning
            fi
        fi
        ;;
        
    clipboard)
        # OCR from clipboard
        wl-paste -t image/png > "$TEMP_IMG" 2>/dev/null
        
        if [ -s "$TEMP_IMG" ]; then
            TEXT=$(perform_ocr "$TEMP_IMG")
            
            if [ -n "$TEXT" ]; then
                echo "$TEXT" | wl-copy
                notify-send "📋 OCR from Clipboard" "$TEXT" -t 10000
            else
                notify-send "OCR Failed" "No text detected in clipboard image" -i dialog-warning
            fi
        else
            notify-send "No Image" "No image found in clipboard" -i dialog-error
        fi
        ;;
        
    window)
        # OCR active window
        grimblast save active "$TEMP_IMG"
        
        if [ -f "$TEMP_IMG" ]; then
            TEXT=$(perform_ocr "$TEMP_IMG")
            
            if [ -n "$TEXT" ]; then
                echo "$TEXT" | wl-copy
                notify-send "📋 Window OCR" "$TEXT" -t 10000
            fi
        fi
        ;;
esac
