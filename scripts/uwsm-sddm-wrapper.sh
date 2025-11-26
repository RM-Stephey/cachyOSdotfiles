#!/bin/bash
#
# UWSM wrapper for SDDM - ensures proper environment setup
# This wrapper fixes environment issues when SDDM launches UWSM
#

# Essential variables that might be missing from SDDM
# Force proper expansion of HOME - greetd may pass literal tilde
export USER="${USER:-$(whoami)}"
# Always expand HOME properly, even if set to ~
if [ "$HOME" = "~" ] || [ -z "$HOME" ]; then
    export HOME="/home/$USER"
fi
# Ensure HOME is absolute
export HOME="$(eval echo $HOME)"
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

# Clear XDG_CURRENT_DESKTOP to prevent duplication
# UWSM will set it properly based on the desktop file
unset XDG_CURRENT_DESKTOP

# Launch UWSM with all arguments passed through
# Use the desktop file as recommended in the wiki
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing: uwsm start hyprland-uwsm.desktop" >> "$LOG_FILE"
exec uwsm start hyprland-uwsm.desktop 2>&1 | tee -a "$LOG_FILE"
