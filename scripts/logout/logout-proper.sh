#!/bin/bash
# Proper logout script for SDDM + Hyprland
# Uses loginctl to properly terminate the session

# Exit Hyprland gracefully first
hyprctl dispatch exit 2>/dev/null || true

# Give it a moment
sleep 0.5

# If still running, force exit
if pgrep -x Hyprland >/dev/null; then
    pkill -TERM Hyprland
    sleep 0.5
    if pgrep -x Hyprland >/dev/null; then
        pkill -KILL Hyprland
    fi
fi

# Stop the systemd service
systemctl --user stop wayland-wm@hyprland.service 2>/dev/null || true

# Get the current session ID and terminate it properly
SESSION_ID=$(loginctl show-session $(loginctl list-sessions --no-legend | grep "$USER" | awk '{print $1}') --property=Id --value 2>/dev/null)

if [ -n "$SESSION_ID" ]; then
    echo "Terminating session $SESSION_ID"
    loginctl kill-session "$SESSION_ID" 2>/dev/null
else
    echo "No session found, trying to switch to VT1"
    # Fallback: switch to VT1 where SDDM should be
    sudo chvt 1 2>/dev/null || true
fi

exit 0