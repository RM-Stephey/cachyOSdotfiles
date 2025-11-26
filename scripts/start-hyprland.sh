#!/bin/bash

# Fallback script to ensure Hyprland starts properly
# This script checks if Hyprland is running and starts it if needed

# Set up logging
LOG_FILE="$HOME/.local/share/hyprland-start.log"
echo "=== Hyprland Start Script - $(date) ===" >> "$LOG_FILE"

# Function to log messages
log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if Hyprland is already running
if pgrep -x "Hyprland" > /dev/null; then
    log "Hyprland is already running"
    exit 0
fi

# Set up environment variables
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland

# NVIDIA specific settings for RTX 4090
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __GL_GSYNC_ALLOWED=1
export NVD_BACKEND=direct
export GBM_BACKEND=nvidia-drm
export __GL_VRR_ALLOWED=1
export WLR_RENDERER_ALLOW_SOFTWARE=0
export __GL_YIELD=USLEEP
export MOZ_ENABLE_WAYLAND=1

# Cursor settings (match UWSM defaults)
export HYPRCURSOR_THEME=Future-Cyan-Hyprcursor_Theme
export HYPRCURSOR_SIZE=48
export XCURSOR_THEME=Future-Cyan-Hyprcursor_Theme
export XCURSOR_SIZE=48
export QT_CURSOR_SIZE=48
export ELECTRON_OZONE_PLATFORM_HINT=auto

# DBus settings
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

# SSH and Keyring
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"

# Import environment to systemd
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null

# Try to start with uwsm first
log "Attempting to start Hyprland with uwsm..."
if command -v uwsm &> /dev/null; then
    # Check if we can start with uwsm
    if uwsm check may-start 2>/dev/null; then
        log "Starting with uwsm..."
        exec uwsm start -- hyprland.desktop 2>&1 | tee -a "$LOG_FILE"
    else
        log "uwsm check failed, trying direct start..."
    fi
fi

# Fallback: Start Hyprland directly
log "Starting Hyprland directly (fallback mode)..."

# Ensure runtime directory exists
mkdir -p "$XDG_RUNTIME_DIR/hypr"

# Start essential services before Hyprland
log "Starting essential services..."
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
gnome-keyring-daemon --start --components=pkcs11,secrets,ssh &

# Give services a moment to start
sleep 1

# Start Hyprland directly
log "Executing Hyprland..."
exec Hyprland 2>&1 | tee -a "$LOG_FILE"
