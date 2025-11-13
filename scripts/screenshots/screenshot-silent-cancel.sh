#!/bin/bash
# Screenshot script that stays silent on cancellation

case "${1:-region}" in
    region)
        # Quick region to clipboard
        if grimblast --freeze copy area 2>/dev/null; then
            notify-send "📸 Screenshot" "Copied to clipboard" -i edit-copy
        fi
        # No notification if cancelled
        ;;
        
    region-edit)
        # Region with editor
        TEMP="/tmp/screenshot_$$.png"
        if grimblast --freeze save area "$TEMP" 2>/dev/null; then
            swappy -f "$TEMP"
            rm -f "$TEMP"
        fi
        # No notification if cancelled
        ;;
        
    fullscreen)
        # Fullscreen capture
        if grimblast copy output 2>/dev/null; then
            notify-send "📸 Fullscreen" "Copied to clipboard" -i computer
        fi
        ;;
        
    window)
        # Window capture
        if grimblast copy active 2>/dev/null; then
            notify-send "📸 Window" "Copied to clipboard" -i window
        fi
        ;;
        
    save)
        # Save to file
        OUTPUT="$HOME/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png"
        if grimblast save output "$OUTPUT" 2>/dev/null; then
            notify-send "💾 Screenshot Saved" "$OUTPUT" -i document-save
        fi
        ;;
esac
