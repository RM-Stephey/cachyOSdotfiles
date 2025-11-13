#!/bin/bash
# Hyprland logout script for systemd-managed sessions (UWSM/SDDM)
# Fixes logout issues with SDDM by properly terminating systemd services

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

  # Check if Hyprland is still responsive
  if hyprctl clients -j &>/dev/null; then
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
  else
    log "Hyprland not responsive, skipping session save"
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

# Method 1: Stop the systemd user service (for UWSM-managed sessions)
if systemctl --user is-active wayland-wm@hyprland.service &>/dev/null; then
  log "Stopping systemd-managed Hyprland service..."
  systemctl --user stop wayland-wm@hyprland.service

  # Wait for service to stop
  for i in {1..10}; do
    if ! systemctl --user is-active wayland-wm@hyprland.service &>/dev/null; then
      log "Systemd service stopped successfully"
      break
    fi
    log "Waiting for service to stop ($i/10)..."
    sleep 0.5
  done
fi

# Method 2: Try graceful Hyprland exit via hyprctl
if pgrep -f Hyprland >/dev/null; then
  log "Attempting graceful Hyprland exit via hyprctl..."
  hyprctl dispatch exit 2>/dev/null || true

  # Give Hyprland a moment to exit gracefully
  for i in {1..5}; do
    if ! pgrep -f Hyprland >/dev/null; then
      log "Hyprland exited cleanly via hyprctl."
      break
    fi
    log "Waiting for Hyprland to exit ($i/5)..."
    sleep 0.5
  done
fi

# Stop related user services
log "Stopping related user services..."
systemctl --user stop --no-block \
  graphical-session.target \
  graphical-session-pre.target \
  xdg-desktop-portal-hyprland.service \
  xdg-desktop-portal-gtk.service \
  xdg-desktop-portal.service \
  pipewire.service \
  pipewire-pulse.service \
  wireplumber.service 2>/dev/null || true

# Clean up UI components
log "Stopping UI components..."
pkill -15 -f "waybar|swayosd|eww|mako|dunst|swaync|ags" 2>/dev/null || true

# If Hyprland is still running, try SIGTERM
if pgrep -f Hyprland >/dev/null; then
  log "Hyprland still running. Sending SIGTERM..."
  pkill -15 -f Hyprland
  sleep 1

  # Last resort: SIGKILL
  if pgrep -f Hyprland >/dev/null; then
    log "Forcing Hyprland termination with SIGKILL..."
    pkill -9 -f Hyprland
    sleep 0.5
  fi
fi

# Clean up any remaining compositor-related processes
log "Cleaning up remaining compositor processes..."
pkill -15 -f "hyprpaper|hyprlock|hypridle|swww|wpaperd" 2>/dev/null || true

# Reset environment variables for clean session
unset WAYLAND_DISPLAY
unset DISPLAY
unset XDG_CURRENT_DESKTOP
unset HYPRLAND_INSTANCE_SIGNATURE

# Terminate the loginctl session
if [ -n "$SESSION_ID" ]; then
  log "Terminating loginctl session $SESSION_ID..."

  # First try to terminate the specific session
  loginctl terminate-session "$SESSION_ID" 2>/dev/null || {
    # If that fails, try to kill the session
    log "terminate-session failed, trying kill-session..."
    loginctl kill-session "$SESSION_ID" 2>/dev/null || {
      # Last resort: terminate user
      log "kill-session failed, trying terminate-user..."
      loginctl terminate-user $(whoami) 2>/dev/null || true
    }
  }
else
  log "No session ID found, attempting to terminate current user sessions..."
  loginctl terminate-user $(whoami) 2>/dev/null || true
fi

# Final cleanup - ensure SDDM can restart properly
log "Performing final cleanup for SDDM..."

# Clear any locks or temp files that might interfere
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true
rm -f /run/user/$(id -u)/wayland-* 2>/dev/null || true

# If we're using SDDM autologin, signal that we want the greeter
if grep -q "^User=stephey" /etc/sddm.conf 2>/dev/null; then
  log "SDDM autologin detected, session will return to greeter"
fi

log "Logout script completed at $(date)"
log "===== End of logout ====="

# Exit cleanly
exit 0
