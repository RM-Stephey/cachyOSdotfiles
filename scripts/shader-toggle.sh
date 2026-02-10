#!/bin/bash
# Shader Toggle - Switch between cyberpunk eye-candy and clean work mode
# Usage: bind to a keybind (e.g. Super+Shift+G)

SHADER="$HOME/.config/hypr/shaders/cyberpunk-composite.frag"

# Get current shader (returns "[[EMPTY]]" when none is set)
current=$(hyprctl getoption decoration:screen_shader -j 2>/dev/null | grep -oP '"str"\s*:\s*"\K[^"]+')

if [ -z "$current" ] || [ "$current" = "[[EMPTY]]" ]; then
    # No shader active -> enable cyberpunk composite
    hyprctl keyword decoration:screen_shader "$SHADER" >/dev/null 2>&1
    notify-send -a "Hyprland" -i video-display "Shader ON" "Cyberpunk composite enabled" -t 2000
else
    # Shader active -> disable
    hyprctl keyword decoration:screen_shader "[[EMPTY]]" >/dev/null 2>&1
    notify-send -a "Hyprland" -i video-display "Shader OFF" "Clean mode" -t 2000
fi
