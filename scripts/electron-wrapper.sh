#!/usr/bin/env bash
# Electron wrapper script - adds WaylandLinuxDrmSyncobj flag to all Electron apps
# Usage: electron-wrapper.sh <electron-app-binary> [args...]

# Check if we have at least one argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <electron-app> [args...]" >&2
    exit 1
fi

# Extract the binary name and remaining arguments
ELECTRON_BIN="$1"
shift
ARGS="$@"

# Check if the binary exists
if ! command -v "$ELECTRON_BIN" >/dev/null 2>&1; then
    echo "Error: $ELECTRON_BIN not found" >&2
    exit 1
fi

# Launch Electron app with Wayland DRM sync object flag
exec "$ELECTRON_BIN" --enable-features=WaylandLinuxDrmSyncobj $ARGS
