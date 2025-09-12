#!/bin/bash
# Waybar auto-hide handler for fullscreen mode (uwsm-compatible)
# Keeps waybar visible for maximized windows, hides for fullscreen
# Shows waybar on cursor hover at top of screen in fullscreen mode
# Compatible with uwsm session management

# Check for uwsm environment
if [ -n "${UWSM_ID:-}" ]; then
    export UWSM_ACTIVE=1
fi

# Configuration
WAYBAR_HEIGHT=30  # Adjust based on your waybar height
HOVER_ZONE=5      # Pixels from top to trigger waybar
HIDE_DELAY=0.3    # Delay before hiding waybar
SHOW_DELAY=0.1    # Delay before showing waybar

# State tracking
WAYBAR_VISIBLE=true
FULLSCREEN_MODE=false
LAST_CURSOR_Y=-1
HOVER_TIMER_PID=""

# Get waybar process
get_waybar_pid() {
    pgrep -x waybar | head -1
}

# Show waybar with slide animation
show_waybar() {
    if [ "$WAYBAR_VISIBLE" = false ]; then
        WAYBAR_VISIBLE=true
        # Signal waybar to show
        pkill -SIGUSR2 waybar 2>/dev/null || true
        # Or use layer shell command if waybar doesn't respond to signals
        hyprctl keyword layerrule "animation slide down, waybar" 2>/dev/null
        hyprctl keyword layerrule "noanim 0, waybar" 2>/dev/null
    fi
}

# Hide waybar with slide animation
hide_waybar() {
    if [ "$WAYBAR_VISIBLE" = true ] && [ "$FULLSCREEN_MODE" = true ]; then
        WAYBAR_VISIBLE=false
        # Signal waybar to hide
        pkill -SIGUSR1 waybar 2>/dev/null || true
        # Or use layer shell command
        hyprctl keyword layerrule "animation slide up, waybar" 2>/dev/null
        hyprctl keyword layerrule "noanim 1, waybar" 2>/dev/null
    fi
}

# Check if active window is fullscreen or maximized
check_window_state() {
    local active_window=$(hyprctl activewindow -j 2>/dev/null)

    if [ -z "$active_window" ]; then
        FULLSCREEN_MODE=false
        show_waybar
        return
    fi

    local fullscreen=$(echo "$active_window" | jq -r '.fullscreen')
    local fullscreenClient=$(echo "$active_window" | jq -r '.fullscreenClient')

    # fullscreen: 0 = fullscreen, 1 = maximize, 2 = fullscreen (alternative), -1 = none
    if [ "$fullscreen" = "0" ] || [ "$fullscreen" = "2" ] || [ "$fullscreenClient" = "0" ]; then
        # True fullscreen mode
        FULLSCREEN_MODE=true
        # Hide waybar after delay
        if [ -n "$HOVER_TIMER_PID" ]; then
            kill $HOVER_TIMER_PID 2>/dev/null || true
        fi
        (sleep $HIDE_DELAY && hide_waybar) &
        HOVER_TIMER_PID=$!
    elif [ "$fullscreen" = "1" ]; then
        # Maximized mode - keep waybar visible
        FULLSCREEN_MODE=false
        show_waybar
    else
        # Normal window
        FULLSCREEN_MODE=false
        show_waybar
    fi
}

# Monitor cursor position for hover detection
monitor_cursor() {
    while true; do
        if [ "$FULLSCREEN_MODE" = true ]; then
            # Get cursor position
            local cursor_info=$(hyprctl cursorpos -j 2>/dev/null)
            if [ -n "$cursor_info" ]; then
                local cursor_y=$(echo "$cursor_info" | jq -r '.y')

                # Check if cursor is in hover zone at top of screen
                if [ "$cursor_y" -le "$HOVER_ZONE" ] && [ "$cursor_y" -ge 0 ]; then
                    if [ "$WAYBAR_VISIBLE" = false ]; then
                        show_waybar
                        # Set auto-hide timer
                        if [ -n "$HOVER_TIMER_PID" ]; then
                            kill $HOVER_TIMER_PID 2>/dev/null || true
                        fi
                        (
                            # Wait for cursor to leave
                            while true; do
                                sleep 0.5
                                local check_cursor=$(hyprctl cursorpos -j 2>/dev/null | jq -r '.y')
                                if [ "$check_cursor" -gt "$WAYBAR_HEIGHT" ]; then
                                    sleep $HIDE_DELAY
                                    hide_waybar
                                    break
                                fi
                            done
                        ) &
                        HOVER_TIMER_PID=$!
                    fi
                fi
            fi
        fi
        sleep 0.2
    done
}

# Handle Hyprland events
handle_events() {
    # Initial check
    check_window_state

    # Monitor for changes
    socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r event; do
        case "$event" in
            fullscreen*|activewindow*|activewindowv2*|workspace*)
                check_window_state
                ;;
        esac
    done
}

# Cleanup on exit
cleanup() {
    show_waybar
    if [ -n "$HOVER_TIMER_PID" ]; then
        kill $HOVER_TIMER_PID 2>/dev/null || true
    fi
    exit 0
}

trap cleanup EXIT INT TERM

# Main execution
main() {
    # Wait for Hyprland to be ready (uwsm compatibility)
    while [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; do
        sleep 0.5
        # Source uwsm environment if available
        if [ -f "${XDG_RUNTIME_DIR}/uwsm/hyprland-env" ]; then
            source "${XDG_RUNTIME_DIR}/uwsm/hyprland-env" 2>/dev/null || true
        fi
    done

    # Check if waybar is running
    if ! get_waybar_pid >/dev/null; then
        echo "Waybar is not running. Waiting..."
        sleep 2
    fi

    # Start cursor monitoring in background
    monitor_cursor &
    CURSOR_MONITOR_PID=$!

    # Start event handling (blocks)
    handle_events
}

# Run the script
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo "Error: Not running in Hyprland session"
    exit 1
fi

main
