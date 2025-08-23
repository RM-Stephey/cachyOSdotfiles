#!/bin/bash
# restore-session.sh - Restore saved applications in Hyprland session
# Author: StepheyBot
# Usage: bash restore-session.sh

# Configuration
SESSION_FILE="$HOME/.config/hypr/saved-session.json"
LOG_FILE="/tmp/hypr-session-restore.log"

# Setup logging
echo "===== Starting session restore at $(date) =====" > "$LOG_FILE"

log() {
  echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Check if the session file exists
if [ ! -f "$SESSION_FILE" ]; then
  log "ERROR: Session file not found at $SESSION_FILE"
  echo "No saved session found!"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  log "ERROR: jq is required but not installed"
  echo "Please install jq: sudo pacman -S jq"
  exit 1
fi

# Check if we're running in Hyprland
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  log "ERROR: Not running in Hyprland"
  echo "This script must be run from within Hyprland."
  exit 1
fi

# Parse the session file
log "Parsing session file..."
SESSION_TIMESTAMP=$(jq -r '.timestamp' "$SESSION_FILE")
log "Session was saved at: $SESSION_TIMESTAMP"

# Function to launch an application on a specific workspace
launch_on_workspace() {
  local class="$1"
  local exec_cmd="$2"
  local workspace="$3"
  local title="$4"

  log "Launching $exec_cmd on workspace $workspace"

  # Switch to the target workspace
  hyprctl dispatch workspace "$workspace"
  sleep 0.5

  # Launch the application
  if [ -n "$exec_cmd" ]; then
    eval "$exec_cmd &"
    log "Launched: $exec_cmd"
  else
    log "WARNING: No command found for $class, attempting generic launch"
    # Try to launch using the class name (lowercase) as a command
    ${class,,} &>/dev/null &
  fi
}

# Function to map window class to executable command
get_exec_cmd() {
  local class="$1"
  local title="$2"

  # Map common applications to their launch commands
  case "${class,,}" in
    "firefox") echo "firefox" ;;
    "chromium") echo "chromium" ;;
    "code") echo "code" ;;
    "code-oss") echo "code-oss" ;;
    "kitty") echo "kitty" ;;
    "alacritty") echo "alacritty" ;;
    "wezterm") echo "wezterm" ;;
    "thunar") echo "thunar" ;;
    "dolphin") echo "dolphin" ;;
    "nautilus") echo "nautilus" ;;
    "telegram-desktop") echo "telegram-desktop" ;;
    "discord") echo "discord" ;;
    "spotify") echo "spotify" ;;
    # Add more mappings as needed
    *)
      # Try to guess based on common patterns
      if [[ "$class" == *"-"* ]]; then
        echo "${class,,}"
      else
        echo "${class,,}"
      fi
      ;;
  esac
}

# Restore windows
log "Restoring windows from saved session..."
echo "Restoring session from $SESSION_TIMESTAMP..."

# Get the total count of windows
WINDOW_COUNT=$(jq '.windows | length' "$SESSION_FILE")
log "Found $WINDOW_COUNT windows to restore"

# Iterate through each window and launch it
for i in $(seq 0 $((WINDOW_COUNT-1))); do
  WINDOW_CLASS=$(jq -r ".windows[$i].class" "$SESSION_FILE")
  WINDOW_TITLE=$(jq -r ".windows[$i].title" "$SESSION_FILE")
  WINDOW_WORKSPACE=$(jq -r ".windows[$i].workspace.id" "$SESSION_FILE")

  # Skip Hyprland-specific windows or system components
  if [[ "$WINDOW_CLASS" == "Hyprland" || "$WINDOW_CLASS" == "waybar" || "$WINDOW_CLASS" == "." ]]; then
    log "Skipping system component: $WINDOW_CLASS"
    continue
  fi

  log "Restoring: $WINDOW_CLASS - \"$WINDOW_TITLE\" on workspace $WINDOW_WORKSPACE"

  # Get the command to launch this application
  EXEC_CMD=$(get_exec_cmd "$WINDOW_CLASS" "$WINDOW_TITLE")

  # Launch the application on its workspace
  launch_on_workspace "$WINDOW_CLASS" "$EXEC_CMD" "$WINDOW_WORKSPACE" "$WINDOW_TITLE"

  # Brief pause to avoid overwhelming the system
  sleep 0.5
done

log "Session restore completed"
echo "Session restore completed!"
exit 0
