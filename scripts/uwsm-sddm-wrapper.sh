#!/bin/bash
#
# UWSM wrapper for SDDM - ensures proper environment setup
# This wrapper fixes environment issues when SDDM launches UWSM
#

# Essential variables that might be missing from SDDM
export USER="${USER:-$(whoami)}"
export HOME="${HOME:-/home/$USER}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Session type
export XDG_SESSION_TYPE="wayland"
export XDG_SESSION_CLASS="user"

# Ensure PATH includes essential directories
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:$HOME/.local/bin:$PATH"

# D-Bus session (required for many desktop services)
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi

# Log for debugging
LOG_FILE="${XDG_RUNTIME_DIR}/uwsm-wrapper.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting UWSM wrapper" > "$LOG_FILE"
echo "USER=$USER" >> "$LOG_FILE"
echo "HOME=$HOME" >> "$LOG_FILE"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" >> "$LOG_FILE"
echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME" >> "$LOG_FILE"
echo "PATH=$PATH" >> "$LOG_FILE"
echo "Arguments: $@" >> "$LOG_FILE"

# Ensure runtime directory exists
mkdir -p "$XDG_RUNTIME_DIR"

# Source user's environment if it exists
if [ -f "$HOME/.config/uwsm/env" ]; then
    . "$HOME/.config/uwsm/env"
fi

# Launch UWSM with all arguments passed through
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing: uwsm start -- hyprland" >> "$LOG_FILE"
exec uwsm start -- hyprland 2>&1 | tee -a "$LOG_FILE"
