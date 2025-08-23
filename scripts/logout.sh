#!/bin/bash
# Hyprland logout script for UWSM and SDDM
# Place in ~/.config/hypr/scripts/ and make executable with:
# chmod +x ~/.config/hypr/scripts/logout.sh

# Setup logging
LOG_FILE="/tmp/hyprland-logout-$USER.log"
echo "===== Starting Hyprland logout at $(date) =====" > "$LOG_FILE"

# Session save configuration
SESSION_DIR="$HOME/.config/hypr/saved-sessions"
DEFAULT_SESSION="$SESSION_DIR/auto-logout.json"
mkdir -p "$SESSION_DIR"

log() {
  echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Function to save current session before logout
save_session_before_exit() {
  log "Saving session before logout..."

  # Create the session file
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  WINDOWS=$(hyprctl clients -j)
  WORKSPACES=$(hyprctl workspaces -j)

  # Build the session data
  cat > "$DEFAULT_SESSION" << EOF
{
  "name": "Auto-saved on logout",
  "timestamp": "$TIMESTAMP",
  "windows": $WINDOWS,
  "workspaces": $WORKSPACES
}
EOF

  if [ -f "$DEFAULT_SESSION" ]; then
    log "Session saved to $DEFAULT_SESSION"
  else
    log "WARNING: Failed to save session"
  fi
}

# Get current session ID
get_session_id() {
  if [ -n "$XDG_SESSION_ID" ]; then
    echo "$XDG_SESSION_ID"
  else
    loginctl list-sessions | grep $(whoami) | awk '{print $1}' | head -n1
  fi
}

SESSION_ID=$(get_session_id)
log "Session ID: $SESSION_ID"

# Save the current session before proceeding with logout
save_session_before_exit

# Try UWSM logout first if available
if command -v uwsmctl &>/dev/null; then
  log "Attempting UWSM logout..."
  uwsmctl logout &>/dev/null
  sleep 1

  # If we're still running, UWSM didn't work
  if pgrep -f Hyprland >/dev/null; then
    log "UWSM logout didn't terminate session, trying alternatives..."
  else
    log "UWSM logout successful"
    exit 0
  fi
else
  log "UWSM not found, using direct methods"
fi

# Stop desktop portals
log "Stopping desktop portals..."
systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk 2>/dev/null || true

# Stop UI components
log "Stopping UI components..."
pkill -15 -f "waybar|swayosd|eww|mako|dunst|swaync" 2>/dev/null || true

# Try to gracefully exit Hyprland
log "Attempting graceful Hyprland exit..."
hyprctl dispatch exit 2>/dev/null || true

# Give Hyprland a moment to exit gracefully
for i in {1..5}; do
  if ! pgrep -f Hyprland >/dev/null; then
    log "Hyprland exited cleanly."
    break
  fi
  log "Waiting for Hyprland to exit ($i/5)..."
  sleep 0.5
done

# If Hyprland is still running, try SIGTERM
if pgrep -f Hyprland >/dev/null; then
  log "Hyprland still running. Sending SIGTERM..."
  pkill -15 -f Hyprland
  sleep 1

  # Last resort: SIGKILL
  if pgrep -f Hyprland >/dev/null; then
    log "Forcing Hyprland termination with SIGKILL..."
    pkill -9 -f Hyprland
  fi
fi

# Terminate the session through loginctl
if [ -n "$SESSION_ID" ]; then
  log "Terminating session through loginctl..."
  loginctl terminate-session "$SESSION_ID" || true
else
  log "No session ID found, attempting to terminate current session..."
  loginctl terminate-user $(whoami) || true
fi

log "Logout script completed at $(date)"
exit 0
