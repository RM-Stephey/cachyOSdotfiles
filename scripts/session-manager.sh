#!/bin/bash
# session-manager.sh - Hyprland Session Management UI
# Author: StepheyBot
# Usage: ./session-manager.sh

# Configuration
SESSION_DIR="$HOME/.config/hypr/saved-sessions"
DEFAULT_SESSION="$SESSION_DIR/default.json"
SAVE_SCRIPT="$HOME/.config/hypr/scripts/save-session.sh"
RESTORE_SCRIPT="$HOME/.config/hypr/scripts/restore-session.sh"
LOG_FILE="/tmp/hypr-session-manager.log"

# Create session directory if it doesn't exist
mkdir -p "$SESSION_DIR"

# Initialize log file
echo "===== Session Manager Started at $(date) =====" > "$LOG_FILE"

# Function for logging
log() {
  echo "[$(date +%H:%M:%S)] $1" >> "$LOG_FILE"
}

# Determine which menu program to use
get_menu_cmd() {
  if command -v wofi &>/dev/null; then
    echo "wofi -d -p 'Session Manager'"
  elif command -v rofi &>/dev/null; then
    echo "rofi -dmenu -p 'Session Manager'"
  elif command -v bemenu &>/dev/null; then
    echo "bemenu -p 'Session Manager'"
  else
    echo "Select an option (enter the number):"
    return 1
  fi
  return 0
}

# Show a notification
notify() {
  if command -v notify-send &>/dev/null; then
    notify-send "Hyprland Session Manager" "$1"
  else
    echo "$1"
  fi
}

# Save the current session
save_session() {
  log "Saving session..."

  # Ask for session name
  SESSION_NAME=$(echo "" | $(get_menu_cmd) --prompt "Enter session name (default: auto-timestamp):")

  # If no name provided, use a timestamp
  if [ -z "$SESSION_NAME" ]; then
    SESSION_NAME="session-$(date +%Y%m%d-%H%M%S)"
  fi

  # Create a valid filename (replace spaces, etc.)
  FILENAME=$(echo "$SESSION_NAME" | tr ' ' '_' | tr -cd 'a-zA-Z0-9_-')
  SESSION_FILE="$SESSION_DIR/$FILENAME.json"

  # Use the save script to create the session file
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  WINDOWS=$(hyprctl clients -j)
  WORKSPACES=$(hyprctl workspaces -j)

  # Build the session data
  cat > "$SESSION_FILE" << EOF
{
  "name": "$SESSION_NAME",
  "timestamp": "$TIMESTAMP",
  "windows": $WINDOWS,
  "workspaces": $WORKSPACES
}
EOF

  # Check if session was saved
  if [ -f "$SESSION_FILE" ]; then
    log "Session saved to $SESSION_FILE"
    notify "Session '$SESSION_NAME' saved successfully!"
    # Also save as default session if it doesn't exist
    if [ ! -f "$DEFAULT_SESSION" ]; then
      cp "$SESSION_FILE" "$DEFAULT_SESSION"
      log "Also saved as default session"
    fi
  else
    log "ERROR: Failed to save session"
    notify "Failed to save session!"
  fi
}

# List available sessions
list_sessions() {
  find "$SESSION_DIR" -name "*.json" -printf "%f\n" | sed 's/\.json$//' | sort
}

# Get session details
get_session_info() {
  local session_file="$1"

  if [ ! -f "$session_file" ]; then
    echo "Session file not found!"
    return 1
  fi

  # Check if jq is installed
  if ! command -v jq &>/dev/null; then
    echo "Please install jq to view session details"
    return 1
  fi

  # Extract basic information
  local name=$(jq -r '.name // "Unnamed"' "$session_file")
  local timestamp=$(jq -r '.timestamp // "Unknown"' "$session_file")
  local window_count=$(jq '.windows | length' "$session_file")
  local workspace_count=$(jq '.workspaces | length' "$session_file")

  echo "Session: $name"
  echo "Saved at: $timestamp"
  echo "Windows: $window_count"
  echo "Workspaces: $workspace_count"

  # List applications by workspace
  echo -e "\nApplications by workspace:"

  for workspace in $(jq -r '.workspaces[].id' "$session_file" | sort -n); do
    echo "Workspace $workspace:"
    jq -r ".windows[] | select(.workspace.id == $workspace) | \"  - \" + .class + \": \\\"\" + .title + \"\\\"\"" "$session_file"
  done
}

# Restore a session
restore_session() {
  log "Restoring session..."

  # Get list of saved sessions
  SESSIONS=$(list_sessions)

  if [ -z "$SESSIONS" ]; then
    notify "No saved sessions found!"
    log "No saved sessions found"
    return 1
  fi

  # Add option for default session
  if [ -f "$DEFAULT_SESSION" ]; then
    SESSIONS="default\n$SESSIONS"
  fi

  # Let user select a session
  SELECTED=$(echo -e "$SESSIONS" | $(get_menu_cmd) --prompt "Select session to restore:")

  if [ -z "$SELECTED" ]; then
    log "No session selected"
    return 1
  fi

  log "Selected session: $SELECTED"

  # Determine session file path
  if [ "$SELECTED" = "default" ]; then
    SESSION_FILE="$DEFAULT_SESSION"
  else
    SESSION_FILE="$SESSION_DIR/$SELECTED.json"
  fi

  # Check if file exists
  if [ ! -f "$SESSION_FILE" ]; then
    notify "Session file not found!"
    log "ERROR: Session file not found: $SESSION_FILE"
    return 1
  fi

  # Confirm restoration
  CONFIRM=$(echo -e "Yes\nNo" | $(get_menu_cmd) --prompt "Restore session '$SELECTED'? Current windows will remain open.")

  if [ "$CONFIRM" != "Yes" ]; then
    log "Restoration cancelled by user"
    return 1
  fi

  # Call restore script
  export SESSION_FILE
  bash "$RESTORE_SCRIPT"

  notify "Session '$SELECTED' restored!"
  log "Session restored: $SELECTED"
}

# View session details
view_session() {
  log "Viewing session details..."

  # Get list of saved sessions
  SESSIONS=$(list_sessions)

  if [ -z "$SESSIONS" ]; then
    notify "No saved sessions found!"
    log "No saved sessions found"
    return 1
  fi

  # Add option for default session
  if [ -f "$DEFAULT_SESSION" ]; then
    SESSIONS="default\n$SESSIONS"
  fi

  # Let user select a session
  SELECTED=$(echo -e "$SESSIONS" | $(get_menu_cmd) --prompt "Select session to view:")

  if [ -z "$SELECTED" ]; then
    log "No session selected"
    return 1
  fi

  log "Selected session for viewing: $SELECTED"

  # Determine session file path
  if [ "$SELECTED" = "default" ]; then
    SESSION_FILE="$DEFAULT_SESSION"
  else
    SESSION_FILE="$SESSION_DIR/$SELECTED.json"
  fi

  # Display session info using a pager
  SESSION_INFO=$(get_session_info "$SESSION_FILE")
  echo "$SESSION_INFO" | $(get_menu_cmd) --prompt "Session Details (Press Esc to close):"
}

# Delete a session
delete_session() {
  log "Deleting session..."

  # Get list of saved sessions
  SESSIONS=$(list_sessions)

  if [ -z "$SESSIONS" ]; then
    notify "No saved sessions found!"
    log "No saved sessions found"
    return 1
  fi

  # Add option for default session
  if [ -f "$DEFAULT_SESSION" ]; then
    SESSIONS="default\n$SESSIONS"
  fi

  # Let user select a session
  SELECTED=$(echo -e "$SESSIONS" | $(get_menu_cmd) --prompt "Select session to DELETE:")

  if [ -z "$SELECTED" ]; then
    log "No session selected"
    return 1
  fi

  log "Selected session for deletion: $SELECTED"

  # Determine session file path
  if [ "$SELECTED" = "default" ]; then
    SESSION_FILE="$DEFAULT_SESSION"
  else
    SESSION_FILE="$SESSION_DIR/$SELECTED.json"
  fi

  # Confirm deletion
  CONFIRM=$(echo -e "No\nYes" | $(get_menu_cmd) --prompt "Are you sure you want to DELETE '$SELECTED'?")

  if [ "$CONFIRM" != "Yes" ]; then
    log "Deletion cancelled by user"
    return 1
  fi

  # Delete the file
  rm -f "$SESSION_FILE"
  notify "Session '$SELECTED' deleted!"
  log "Session deleted: $SELECTED"
}

# Main menu
main_menu() {
  OPTIONS="Save Current Session\nRestore Session\nView Session Details\nDelete Session\nExit"

  CHOICE=$(echo -e "$OPTIONS" | $(get_menu_cmd) --prompt "Hyprland Session Manager:")

  case "$CHOICE" in
    "Save Current Session")
      save_session
      ;;
    "Restore Session")
      restore_session
      ;;
    "View Session Details")
      view_session
      ;;
    "Delete Session")
      delete_session
      ;;
    "Exit" | "")
      log "Session manager exited"
      exit 0
      ;;
  esac
}

# Make sure we're running in Hyprland
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  log "ERROR: Not running in Hyprland"
  echo "This script must be run from within Hyprland."
  exit 1
fi

# Run the main menu
main_menu
exit 0
