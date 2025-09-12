#!/bin/bash
# Dynamic gaps management for Hyprland (uwsm-compatible)
# Removes gaps for maximized windows, restores for normal windows
# Compatible with uwsm session management

# Check for uwsm environment
if [ -n "${UWSM_ID:-}" ]; then
    export UWSM_ACTIVE=1
fi

# Default gap values (adjust to match your preferences)
DEFAULT_GAPS_IN=6
DEFAULT_GAPS_OUT=12
MAXIMIZED_GAPS_IN=0
MAXIMIZED_GAPS_OUT=0

# Function to check if active window is maximized
is_window_maximized() {
    # Get active window info
    active_window=$(hyprctl activewindow -j 2>/dev/null)

    if [ -z "$active_window" ]; then
        return 1
    fi

    # Check if window is fullscreen or maximized
    fullscreen=$(echo "$active_window" | jq -r '.fullscreen')
    # Check if window size matches workspace size (maximized)
    workspace_id=$(echo "$active_window" | jq -r '.workspace.id')
    workspace_info=$(hyprctl workspaces -j | jq ".[] | select(.id == $workspace_id)")

    ws_width=$(echo "$workspace_info" | jq -r '.width')
    ws_height=$(echo "$workspace_info" | jq -r '.height')
    win_width=$(echo "$active_window" | jq -r '.size[0]')
    win_height=$(echo "$active_window" | jq -r '.size[1]')

    # Check if maximized (fullscreen mode 1) or fullscreen (mode 0 or 2)
    if [ "$fullscreen" = "1" ]; then
        return 0  # Maximized
    elif [ "$fullscreen" = "0" ] || [ "$fullscreen" = "2" ]; then
        return 2  # Fullscreen
    fi

    # Check if window dimensions match workspace (accounting for gaps)
    if [ "$win_width" -ge $((ws_width - 50)) ] && [ "$win_height" -ge $((ws_height - 50)) ]; then
        return 0  # Maximized
    fi

    return 1  # Normal window
}

# Function to set gaps
set_gaps() {
    local gaps_in=$1
    local gaps_out=$2
    hyprctl keyword general:gaps_in "$gaps_in" >/dev/null 2>&1
    hyprctl keyword general:gaps_out "$gaps_out" >/dev/null 2>&1
}

# Function to handle window state changes
handle_window_change() {
    is_window_maximized
    state=$?

    if [ $state -eq 0 ]; then
        # Window is maximized - remove gaps
        set_gaps $MAXIMIZED_GAPS_IN $MAXIMIZED_GAPS_OUT
        # Also remove rounding for cleaner look
        hyprctl keyword decoration:rounding 0 >/dev/null 2>&1
    elif [ $state -eq 2 ]; then
        # Window is fullscreen - keep default gaps for now
        # Fullscreen apps handle their own spacing
        set_gaps $DEFAULT_GAPS_IN $DEFAULT_GAPS_OUT
        hyprctl keyword decoration:rounding 0 >/dev/null 2>&1
    else
        # Normal window - restore default gaps
        set_gaps $DEFAULT_GAPS_IN $DEFAULT_GAPS_OUT
        hyprctl keyword decoration:rounding 8 >/dev/null 2>&1
    fi
}

# Monitor for window events if run in monitor mode
if [ "${1:-}" = "monitor" ]; then
    # Wait for Hyprland to be ready (uwsm compatibility)
    while [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; do
        sleep 0.5
        # Source uwsm environment if available
        if [ -f "${XDG_RUNTIME_DIR}/uwsm/hyprland-env" ]; then
            source "${XDG_RUNTIME_DIR}/uwsm/hyprland-env" 2>/dev/null || true
        fi
    done

    # Initial check
    handle_window_change

    # Monitor for changes using socat
    socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r event; do
        case "$event" in
            fullscreen*|activewindow*|workspace*|windowtitle*)
                handle_window_change
                ;;
        esac
    done
else
    # Single run mode
    handle_window_change
fi
