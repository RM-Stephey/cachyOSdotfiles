#!/bin/bash
#
# Enhanced logout script to return to SDDM greeter
# Properly handles systemd-managed sessions and SDDM integration
#

# Setup logging
LOG_FILE="/tmp/sddm-logout-$USER.log"
echo "===== Starting SDDM logout at $(date) =====" > "$LOG_FILE"

log() {
  echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Find which VT the SDDM greeter is on
SDDM_VT=$(loginctl list-sessions --no-legend | grep "greeter" | awk '{print $6}' | sed 's/tty//')

# If we can't find the greeter, check for SDDM's X server
if [ -z "$SDDM_VT" ]; then
    # Check where SDDM's X server is running
    SDDM_VT=$(ps aux | grep -E "/usr/lib/Xorg.*-auth /run/sddm" | grep -v grep | sed -n 's/.*vt\([0-9]\+\).*/\1/p')
fi

# Default to VT2 if we still can't find it
if [ -z "$SDDM_VT" ]; then
    SDDM_VT=2
fi

log "SDDM VT detected: $SDDM_VT"

# Method 1: Try to stop systemd-managed Hyprland service first
if systemctl --user is-active wayland-wm@hyprland.service &>/dev/null; then
    log "Stopping systemd-managed Hyprland service..."
    systemctl --user stop wayland-wm@hyprland.service
    sleep 1
fi

# Method 2: Exit Hyprland gracefully via hyprctl
if pgrep -x Hyprland >/dev/null; then
    log "Attempting graceful Hyprland exit..."
    hyprctl dispatch exit 2>/dev/null || true
    sleep 1
fi

# Method 3: Force kill if still running
if pgrep -x Hyprland >/dev/null; then
    log "Force killing Hyprland..."
    pkill -TERM Hyprland
    sleep 0.5
    if pgrep -x Hyprland >/dev/null; then
        pkill -KILL Hyprland
    fi
fi

# Clean up user services
log "Stopping user services..."
systemctl --user stop --no-block \
  graphical-session.target \
  graphical-session-pre.target \
  xdg-desktop-portal-hyprland.service \
  xdg-desktop-portal-gtk.service \
  xdg-desktop-portal.service 2>/dev/null || true

# Switch to SDDM's VT
log "Switching to VT${SDDM_VT} where SDDM is running..."
if loginctl activate $(loginctl list-sessions --no-legend | grep "greeter" | awk '{print $1}') 2>/dev/null; then
    log "Successfully activated SDDM greeter session"
elif sudo chvt $SDDM_VT 2>/dev/null; then
    log "Successfully switched to VT${SDDM_VT} via sudo"
elif chvt $SDDM_VT 2>/dev/null; then
    log "Successfully switched to VT${SDDM_VT}"
else
    log "Failed to switch to SDDM VT, trying session termination..."
    # Final cleanup - terminate our session to ensure clean logout
    if [ -n "$XDG_SESSION_ID" ]; then
        loginctl kill-session "$XDG_SESSION_ID" 2>/dev/null
    fi
fi

log "SDDM logout completed at $(date)"
exit 0
