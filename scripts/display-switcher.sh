CONFIG="$HOME/.config/hypr/config/monitor.conf"
STATE_FILE="/tmp/hyprland_display_mode"
MODES=("laptop" "tv" "mirror" "extend")

# Find current mode
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_MODE=$(cat "$STATE_FILE")
else
    CURRENT_MODE="laptop"
fi

for i in "${!MODES[@]}"; do
    if [[ "${MODES[$i]}" == "$CURRENT_MODE" ]]; then
        NEXT_INDEX=$(( (i + 1) % ${#MODES[@]} ))
        NEXT_MODE="${MODES[$NEXT_INDEX]}"
        break
    fi
done

# Prepare monitor configs
case "$NEXT_MODE" in
    "laptop")
        MONITOR_BLOCK="monitor=eDP-2,preferred,0x0,1
monitor=HDMI-A-1,disable"
        ;;
    "tv")
        MONITOR_BLOCK="monitor=eDP-2,disable
monitor=HDMI-A-1,preferred,0x0,1.5"
        ;;
    "mirror")
        MONITOR_BLOCK="monitor=eDP-2,1920x1080@60,0x0,1
monitor=HDMI-A-1,1920x1080@60,0x0,1.5"
        ;;
    "extend")
        MONITOR_BLOCK="monitor=eDP-2,preferred,0x0,1
monitor=HDMI-A-1,preferred,2560x0,1.5"
        ;;
esac

# Replace monitor lines in config
awk '/^monitor=/{next} {print}' "$CONFIG" > "$CONFIG.tmp"
echo "$MONITOR_BLOCK" >> "$CONFIG.tmp"
mv "$CONFIG.tmp" "$CONFIG"

# Reload Hyprland
hyprctl reload

# Notify
notify-send "Display Mode" "Switched to $NEXT_MODE"

# Save new mode
echo "$NEXT_MODE" > "$STATE_FILE"
