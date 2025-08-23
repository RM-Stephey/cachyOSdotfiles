#!/bin/bash
# save-session.sh - Save running applications in Hyprland session
# Author: StepheyBot
# Usage: bash save-session.sh

# Configuration
SESSION_FILE="$HOME/.config/hypr/saved-session.json"
LOG_FILE="/tmp/hypr-session-save.log"

# Setup logging
echo "===== Starting session save at $(date) =====" > "$LOG_FILE"

log() {
  echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Get information about all windows
get_windows_info() {
  hyprctl clients -j
}

# Get workspace information
get_workspaces_info() {
  hyprctl workspaces -j
}

# Main function to save the session
save_session() {
  log "Saving Hyprland session..."

  # Create JSON structure with timestamp
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  WINDOWS=$(get_windows_info)
  WORKSPACES=$(get_workspaces_info)

  # Build the session data
  cat > "$SESSION_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "windows": $WINDOWS,
  "workspaces": $WORKSPACES
}
EOF

  # Verify the file was created
  if [ -f "$SESSION_FILE" ]; then
    log "Session saved to $SESSION_FILE"
    echo "Session saved successfully!"
  else
    log "ERROR: Failed to save session"
    echo "Failed to save session!"
    return 1
  fi

  return 0
}

# Make sure we're running in Hyprland
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  log "ERROR: Not running in Hyprland"
  echo "This script must be run from within Hyprland."
  exit 1
fi

# Save the session
save_session
exit $?
