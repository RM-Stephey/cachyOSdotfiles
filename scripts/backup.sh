#!/bin/bash
# system-backup-to-pcloud.sh - Automated system backup to pCloud using restic + rclone
# Author: StepheyBot

# --- USER CONFIGURATION ---
RCLONE_REMOTE="pcloud"
PCLOUD_PATH="SystemBackup"
RESTIC_PASSWORD_FILE="$HOME/.restic_system_pcloud_pass"
LOG_FILE="$HOME/.local/share/system-backup-to-pcloud.log"
EXCLUDES=(
  /proc
  /sys
  /dev
  /run
  /tmp
  /mnt
  /media
  /var/cache
  /var/tmp
  /swapfile
)
# --- END USER CONFIGURATION ---

export RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
export RESTIC_PASSWORD_FILE

# Prompt for password if file doesn't exist
if [ ! -f "$RESTIC_PASSWORD_FILE" ]; then
  echo "No restic password file found at $RESTIC_PASSWORD_FILE."
  read -s -p "Enter a new restic password (will be saved for future use): " RESTIC_PASS
  echo
  read -s -p "Confirm password: " RESTIC_PASS_CONFIRM
  echo
  if [ "$RESTIC_PASS" != "$RESTIC_PASS_CONFIRM" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
  fi
  echo "$RESTIC_PASS" > "$RESTIC_PASSWORD_FILE"
  chmod 600 "$RESTIC_PASSWORD_FILE"
  echo "Password saved to $RESTIC_PASSWORD_FILE"
fi

RESTIC_REPO="rclone:${RCLONE_REMOTE}:${PCLOUD_PATH}"

# Build exclude arguments
EXCLUDE_ARGS=()
for ex in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(--exclude "$ex")
done

# Initialize repo if needed
if ! sudo -E restic -r "$RESTIC_REPO" snapshots &>/dev/null; then
  echo "$(date): Initializing restic repository on pCloud..." | tee -a "$LOG_FILE"
  sudo -E restic -r "$RESTIC_REPO" init | tee -a "$LOG_FILE"
fi

# Run backup
echo "$(date): Starting system backup to pCloud..." | tee -a "$LOG_FILE"
sudo -E restic -r "$RESTIC_REPO" backup "${EXCLUDE_ARGS[@]}" / | tee -a "$LOG_FILE"

echo "$(date): System backup complete!" | tee -a "$LOG_FILE"
