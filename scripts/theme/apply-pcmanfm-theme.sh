#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃              PCManFM-Qt Neon Theme Applier                  ┃
# ┃     Apply neon-themed styling to PCManFM-Qt                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Colors for output
NEON_PINK='\033[95m'
NEON_BLUE='\033[96m'
NEON_GREEN='\033[92m'
NEON_PURPLE='\033[94m'
NC='\033[0m' # No Color

# Configuration
PCMANFM_CONFIG_DIR="$HOME/.config/pcmanfm-qt/default"
GTK_CONFIG_DIR="$HOME/.config/gtk-3.0"
HYPR_CONFIG_DIR="$HOME/.config/hypr"

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

# Function to restart PCManFM-Qt
restart_pcmanfm() {
    log "INFO" "Restarting PCManFM-Qt..."
    
    # Kill any running PCManFM-Qt instances
    pkill -f pcmanfm-qt
    
    # Wait a moment
    sleep 1
    
    # Start PCManFM-Qt in the background
    pcmanfm-qt &
    
    log "SUCCESS" "PCManFM-Qt restarted with new theme"
}

# Function to reload Hyprland configuration
reload_hyprland() {
    log "INFO" "Reloading Hyprland configuration..."
    
    # Reload Hyprland
    if command -v hyprctl &> /dev/null; then
        hyprctl reload
        log "SUCCESS" "Hyprland configuration reloaded"
    else
        log "WARNING" "hyprctl not found, could not reload Hyprland configuration"
    fi
}

# Main function
main() {
    log "INFO" "Starting PCManFM-Qt Neon Theme application..."
    
    # Check directories
    check_dir "$PCMANFM_CONFIG_DIR"
    check_dir "$GTK_CONFIG_DIR"
    
    # Check if Papirus-Dark icon theme is installed
    if [ ! -d "/usr/share/icons/Papirus-Dark" ]; then
        log "WARNING" "Papirus-Dark icon theme not found. Installing..."
        
        # Try to install Papirus icon theme
        if command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm papirus-icon-theme
        elif command -v apt &> /dev/null; then
            sudo apt install -y papirus-icon-theme
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y papirus-icon-theme
        else
            log "ERROR" "Could not install Papirus icon theme. Please install it manually."
        fi
    fi
    
    # Apply Hyprland configuration
    log "INFO" "Applying Hyprland configuration..."
    
    # Copy fixed configuration files
    if [ -f "$HYPR_CONFIG_DIR/config/decoration_enhanced_fixed.conf" ] && [ -f "$HYPR_CONFIG_DIR/config/pcmanfm_enhanced_fixed.conf" ]; then
        # Update user-config.conf to use the fixed configuration files
        sed -i 's/pcmanfm_enhanced_compatible.conf/pcmanfm_enhanced_fixed.conf/g' "$HYPR_CONFIG_DIR/config/user-config.conf"
        sed -i 's/decoration_enhanced_compatible.conf/decoration_enhanced_fixed.conf/g' "$HYPR_CONFIG_DIR/config/user-config.conf"
        log "SUCCESS" "Updated Hyprland configuration to use fixed files"
    else
        log "ERROR" "Fixed configuration files not found"
    fi
    
    # Reload Hyprland configuration
    reload_hyprland
    
    # Apply the theme
    log "INFO" "Applying neon theme to PCManFM-Qt..."
    
    # Restart PCManFM-Qt to apply changes
    restart_pcmanfm
    
    log "SUCCESS" "Neon theme applied to PCManFM-Qt"
    log "INFO" "You may need to restart PCManFM-Qt for all changes to take effect."
}

# Run main function
main