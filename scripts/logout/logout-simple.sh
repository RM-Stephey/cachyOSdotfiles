#!/bin/bash
# Simple logout script for UWSM + SDDM
# This should work more reliably with systemd-managed sessions

# Exit Hyprland gracefully
hyprctl dispatch exit 2>/dev/null || true

# Give it a moment to exit
sleep 0.5

# If still running, force exit
if pgrep -x Hyprland >/dev/null; then
    pkill -TERM Hyprland
    sleep 0.5
    if pgrep -x Hyprland >/dev/null; then
        pkill -KILL Hyprland
    fi
fi

# Terminate the current session to return to SDDM
if [ -n "$XDG_SESSION_ID" ]; then
    loginctl kill-session "$XDG_SESSION_ID" 2>/dev/null
fi

exit 0
