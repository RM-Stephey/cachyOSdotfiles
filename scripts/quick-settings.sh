#!/bin/bash

# Function to get current volume
function get_volume {
  pamixer --get-volume
}

# Function to get brightness
function get_brightness {
  brightnessctl -m | cut -d',' -f4 | tr -d '%'
}

# Create a notification with controls
notify-send -t 10000 "Quick Settings" "$(printf "Volume: %s%%\nBrightness: %s%%" "$(get_volume)" "$(get_brightness)")" \
  -A "vol_up:Volume Up" \
  -A "vol_down:Volume Down" \
  -A "bright_up:Brightness Up" \
  -A "bright_down:Brightness Down"

# Handle action based on response
case $? in
  10) pamixer -i 5 ;; # Volume up
  11) pamixer -d 5 ;; # Volume down
  12) brightnessctl set +10% ;; # Brightness up
  13) brightnessctl set 10%- ;; # Brightness down
esac
