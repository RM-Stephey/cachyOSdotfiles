#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                 Satty Screenshot Script                     ┃
# ┃            Modern screenshot tool with annotation           ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Colors for output
NEON_PINK='\033[95m'
NEON_BLUE='\033[96m'
NEON_GREEN='\033[92m'
NC='\033[0m' # No Color

# Configuration
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
TEMP_DIR="/tmp"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEMP_FILE="$TEMP_DIR/satty_$TIMESTAMP.png"

# Ensure screenshot directory exists
mkdir -p "$SCREENSHOT_DIR"

# Function to log messages
log() {
    local level=$1
    local message=$2
    local color=$NC

    case $level in
        "INFO") color=$NEON_BLUE ;;
        "SUCCESS") color=$NEON_GREEN ;;
        "ERROR") color=$NEON_PINK ;;
    esac

    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message${NC}"
}

# Function to clean up temp files
cleanup() {
    [ -f "$TEMP_FILE" ] && rm -f "$TEMP_FILE"
}

# Function to handle clipboard copy
copy_to_clipboard() {
    local file=$1
    if [ -f "$file" ]; then
        wl-copy < "$file"
        log "SUCCESS" "Copied to clipboard"
        notify-send "📋 Screenshot" "Copied to clipboard" -i edit-copy
    else
        log "ERROR" "File not found: $file"
    fi
}

# Function to take screenshot with Satty
take_screenshot() {
    local mode=$1
    
    case "$mode" in
        "region"|"area")
            log "INFO" "Taking region screenshot..."
            
            # First take a full screenshot as a base
            grim -t ppm "$TEMP_FILE"
            
            # Then use grimblast for area selection
            GEOMETRY=$(slurp -d -b "#00000033" -c "#00FFFF99" -s "#FF00FF33" -w 2)
            
            if [ -z "$GEOMETRY" ]; then
                log "INFO" "Screenshot selection cancelled"
                cleanup
                exit 0
            fi
            
            # Crop the screenshot to the selected area
            grim -g "$GEOMETRY" -t ppm "$TEMP_FILE"
            
            # Check if the file exists and has content
            if [ ! -s "$TEMP_FILE" ]; then
                log "ERROR" "Screenshot file is empty"
                cleanup
                exit 1
            fi
            
            # Now open with satty for annotation - using options from documentation
            satty --filename "$TEMP_FILE" --copy-command wl-copy
            
            # Check result
            if [ $? -eq 0 ]; then
                log "SUCCESS" "Screenshot processed successfully"
                notify-send "📸 Screenshot" "Processed with satty" -i camera-photo
            else
                log "INFO" "Screenshot annotation cancelled"
            fi
            ;;
            
        "fullscreen"|"full")
            log "INFO" "Taking fullscreen screenshot..."
            
            # Capture the entire screen
            if ! grim -t ppm "$TEMP_FILE"; then
                log "ERROR" "Failed to capture fullscreen"
                cleanup
                exit 1
            fi
            
            # Open with satty for annotation
            satty --filename "$TEMP_FILE" --copy-command wl-copy
            
            # Check result
            if [ $? -eq 0 ]; then
                log "SUCCESS" "Fullscreen screenshot processed successfully"
                notify-send "📸 Screenshot" "Fullscreen processed with satty" -i computer
            else
                log "INFO" "Screenshot annotation cancelled"
            fi
            ;;
            
        "window")
            log "INFO" "Taking window screenshot..."
            
            # Use grimblast for active window capture
            if ! grimblast --freeze save active "$TEMP_FILE"; then
                log "ERROR" "Failed to capture window"
                cleanup
                exit 1
            fi
            
            # Open with satty for annotation
            satty --filename "$TEMP_FILE" --copy-command wl-copy
            
            # Check result
            if [ $? -eq 0 ]; then
                log "SUCCESS" "Window screenshot processed successfully"
                notify-send "📸 Screenshot" "Window processed with satty" -i window
            else
                log "INFO" "Screenshot annotation cancelled"
            fi
            ;;
            
        "clipboard"|"copy")
            log "INFO" "Taking region screenshot to clipboard..."
            
            # First take a full screenshot as a base
            grim -t ppm "$TEMP_FILE.full"
            
            # Then use slurp for area selection with improved visibility
            GEOMETRY=$(slurp -d -b "#00000033" -c "#00FFFF99" -s "#FF00FF33" -w 2)
            
            if [ -z "$GEOMETRY" ]; then
                log "INFO" "Screenshot selection cancelled"
                rm -f "$TEMP_FILE.full"
                exit 0
            fi
            
            # Crop the screenshot to the selected area
            grim -g "$GEOMETRY" -t ppm -s 1 "$TEMP_FILE" < "$TEMP_FILE.full"
            rm -f "$TEMP_FILE.full"
            
            # Copy to clipboard
            copy_to_clipboard "$TEMP_FILE"
            ;;
            
        *)
            echo "Usage: $0 {region|fullscreen|window|clipboard}"
            echo "  region     - Select area and annotate with satty"
            echo "  fullscreen - Capture full screen and annotate with satty"
            echo "  window     - Capture active window and annotate with satty"
            echo "  clipboard  - Quick region capture to clipboard (no annotation)"
            exit 1
            ;;
    esac
    
    # Clean up temp file
    cleanup
}

# Main execution
take_screenshot "${1:-region}"