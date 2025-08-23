#!/bin/bash

# XDG Autostart handler for Hyprland
# This script processes XDG autostart .desktop files when not using uwsm

# Set up logging
LOG_FILE="$HOME/.local/share/hyprland-autostart.log"
echo "=== XDG Autostart Handler - $(date) ===" >> "$LOG_FILE"

# Function to log messages
log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if a desktop file should be executed
should_execute() {
    local desktop_file="$1"

    # Check if file exists
    [ ! -f "$desktop_file" ] && return 1

    # Check Hidden key
    if grep -q "^Hidden=true" "$desktop_file"; then
        log "Skipping $desktop_file: Hidden=true"
        return 1
    fi

    # Check X-GNOME-Autostart-enabled
    if grep -q "^X-GNOME-Autostart-enabled=false" "$desktop_file"; then
        log "Skipping $desktop_file: X-GNOME-Autostart-enabled=false"
        return 1
    fi

    # Check OnlyShowIn
    if grep -q "^OnlyShowIn=" "$desktop_file"; then
        local only_show_in=$(grep "^OnlyShowIn=" "$desktop_file" | cut -d= -f2)
        if ! echo "$only_show_in" | grep -qE "(Hyprland|sway|wlroots|all)" && [ -n "$only_show_in" ]; then
            log "Skipping $desktop_file: OnlyShowIn doesn't match"
            return 1
        fi
    fi

    # Check NotShowIn
    if grep -q "^NotShowIn=" "$desktop_file"; then
        local not_show_in=$(grep "^NotShowIn=" "$desktop_file" | cut -d= -f2)
        if echo "$not_show_in" | grep -qE "(Hyprland|sway|wlroots)"; then
            log "Skipping $desktop_file: NotShowIn matches"
            return 1
        fi
    fi

    return 0
}

# Function to extract and execute command from desktop file
execute_desktop_file() {
    local desktop_file="$1"
    local name=$(grep "^Name=" "$desktop_file" | head -1 | cut -d= -f2-)
    local exec_line=$(grep "^Exec=" "$desktop_file" | head -1 | cut -d= -f2-)

    if [ -z "$exec_line" ]; then
        log "ERROR: No Exec line in $desktop_file"
        return 1
    fi

    # Remove field codes (%f, %F, %u, %U, etc.)
    exec_line=$(echo "$exec_line" | sed 's/%[fFuUdDnNickvm]//g')

    log "Starting: $name ($desktop_file)"
    log "Command: $exec_line"

    # Execute in background
    (
        eval "$exec_line" >> "$LOG_FILE" 2>&1 &
        local pid=$!
        log "Started with PID: $pid"
    )
}

# Main execution
log "Starting XDG autostart processing"

# Process system-wide autostart files first
if [ -d /etc/xdg/autostart ]; then
    log "Processing system autostart files from /etc/xdg/autostart"
    for desktop_file in /etc/xdg/autostart/*.desktop; do
        if should_execute "$desktop_file"; then
            execute_desktop_file "$desktop_file"
        fi
    done
fi

# Process user autostart files (these can override system ones)
if [ -d "$HOME/.config/autostart" ]; then
    log "Processing user autostart files from $HOME/.config/autostart"
    for desktop_file in "$HOME/.config/autostart"/*.desktop; do
        if should_execute "$desktop_file"; then
            # Check if this overrides a system file
            basename_file=$(basename "$desktop_file")
            if [ -f "/etc/xdg/autostart/$basename_file" ]; then
                log "User file overrides system file: $basename_file"
            fi
            execute_desktop_file "$desktop_file"
        fi
    done
fi

log "XDG autostart processing completed"

# Wait a moment to ensure all processes have started
sleep 2

# List running autostart processes
log "Currently running autostart processes:"
ps aux | grep -E "($(cat "$LOG_FILE" | grep "Started with PID:" | awk '{print $NF}' | tr '\n' '|' | sed 's/|$//'))" | grep -v grep >> "$LOG_FILE" 2>&1 || true

log "=== XDG Autostart Handler Finished ==="
