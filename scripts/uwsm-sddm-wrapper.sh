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

# Ensure PATH includes essential directories
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:$HOME/.local/bin:$PATH"

# D-Bus session (required for many desktop services)
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi

# Log for debugging
# Source user's environment if it exists
exec uwsm start hyprland-uwsm.desktop 2>&1 | tee -a "$LOG_FILE"
