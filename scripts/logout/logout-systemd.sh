#!/bin/bash
# Proper logout script for UWSM + SDDM with systemd integration
# Research shows: use loginctl kill-session (not terminate-session) for proper SDDM return

echo "Logging out from Hyprland session..."

# Method 1: Use loginctl kill-session with current session ID (most reliable for SDDM)
# This is the proper way to terminate session and return to SDDM login screen
if [ -n "$XDG_SESSION_ID" ]; then
    echo "Terminating user session $XDG_SESSION_ID with kill-session..."
    if loginctl kill-session "$XDG_SESSION_ID" 2>/dev/null; then
        echo "Session terminated successfully, returning to SDDM"
        exit 0
    else
        echo "Failed to kill session $XDG_SESSION_ID"
    fi
fi

# Method 2: Find and kill the current user's main session (seat0)
echo "Finding current user session..."
CURRENT_SESSION=$(loginctl list-sessions --no-legend | grep "$(whoami)" | grep "seat0" | awk '{print $1}' | head -1)
if [ -n "$CURRENT_SESSION" ]; then
    echo "Found session $CURRENT_SESSION, killing it..."
    if loginctl kill-session "$CURRENT_SESSION" 2>/dev/null; then
        echo "Session killed successfully, returning to SDDM"
        exit 0
    else
        echo "Failed to kill session $CURRENT_SESSION"
    fi
fi

# Method 3: Try UWSM stop as fallback (but this may not return to SDDM)
echo "Trying UWSM stop as fallback..."
if uwsm stop 2>/dev/null; then
    echo "UWSM session stopped"
    # Give it a moment to see if it returns to SDDM
    sleep 2
    exit 0
fi

# Method 4: Last resort - force Hyprland exit and let systemd clean up
echo "All methods failed, forcing Hyprland exit..."
if hyprctl dispatch exit 2>/dev/null; then
    echo "Sent exit command to Hyprland"
    sleep 3
else
    echo "Hyprland exit failed, killing processes..."
    pkill -TERM Hyprland
    sleep 2
    pkill -KILL Hyprland 2>/dev/null
fi

echo "Logout script completed"
exit 0