#!/bin/bash
# Fixed logout script for SDDM + Hyprland
# Forces SDDM to properly restart its greeter

# Exit Hyprland gracefully
hyprctl dispatch exit 2>/dev/null || true

# Give it a moment to exit
sleep 1

# If still running, force exit
if pgrep -x Hyprland >/dev/null; then
    pkill -TERM Hyprland
    sleep 1
    if pgrep -x Hyprland >/dev/null; then
        pkill -KILL Hyprland
    fi
fi

# Stop the systemd service
systemctl --user stop wayland-wm@hyprland.service 2>/dev/null || true

# Force SDDM to restart its greeter
sudo systemctl restart sddm 2>/dev/null || true

# If that doesn't work, try switching to VT1 where SDDM should be
sleep 1
sudo chvt 1 2>/dev/null || true

exit 0
