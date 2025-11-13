#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃              Hypr Qt6 Engine Initializer                    ┃
# ┃     Set up hyprqt6engine style for Qt applications          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Colors for output
NEON_PINK='\033[95m'
NEON_BLUE='\033[96m'
NEON_GREEN='\033[92m'
NEON_PURPLE='\033[94m'
NC='\033[0m' # No Color

# Configuration
HYPR_QT6_DIR="$HOME/.config/hypr/qt6"
QT6CT_DIR="$HOME/.config/qt6ct"
PCMANFM_DIR="$HOME/.config/pcmanfm-qt/default"

# Function to log messages
log() {
    local level=$1
    local message=$2
    local color=$NC

    case $level in
        "INFO") color=$NEON_BLUE ;;
        "SUCCESS") color=$NEON_GREEN ;;
        "ERROR") color=$NEON_PINK ;;
        "WARNING") color=$NEON_PURPLE ;;
    esac

    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message${NC}"
}

# Function to check if a directory exists
check_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        log "INFO" "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# Function to set environment variables
set_env_vars() {
    log "INFO" "Setting environment variables for Qt6..."

    # Create environment.d directory if it doesn't exist
    check_dir "$HOME/.config/environment.d"

    # Create Qt environment file
    cat > "$HOME/.config/environment.d/qt-style.conf" << EOF
# Qt Style Configuration
QT_QPA_PLATFORMTHEME=hyprqt6engine
EOF

    log "SUCCESS" "Environment variables set"
}

# Function to restart PCManFM-Qt
restart_pcmanfm() {
    log "INFO" "Restarting PCManFM-Qt..."

    # Kill any running PCManFM-Qt instances
    pkill -f pcmanfm-qt

    # Wait a moment
    sleep 1

    # Set the environment variable for this session
    export QT_QPA_PLATFORMTHEME=hyprqt6engine

    # Start PCManFM-Qt in the background
    pcmanfm-qt &

    log "SUCCESS" "PCManFM-Qt restarted with new Qt style"
}

# Main function
main() {
    log "INFO" "Starting Hypr Qt6 Engine initialization..."

    # Check directories
    check_dir "$HYPR_QT6_DIR"
    check_dir "$QT6CT_DIR"
    check_dir "$PCMANFM_DIR"

    # Set environment variables
    set_env_vars

    # Apply to current session
    export QT_QPA_PLATFORMTHEME=hyprqt6engine

    # Restart PCManFM-Qt
    #restart_pcmanfm

    log "SUCCESS" "Hypr Qt6 Engine initialized"
    log "INFO" "You may need to log out and log back in for all changes to take effect"
}

# Run main function
main
