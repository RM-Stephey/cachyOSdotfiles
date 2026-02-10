#!/bin/bash
# Gap Breathing - Subtle gap size oscillation for a "living" desktop
# Cycles gaps_in between 5-7px and gaps_out between 11-13px over ~8 seconds
# Lightweight: uses sleep + hyprctl keyword, no busy loop
#
# Usage: Run in background via exec-once or systemd user service
# Kill with: pkill -f gap-breathe.sh

# Base values (should match your variables.conf)
BASE_IN=6
BASE_OUT=12
AMPLITUDE=1      # ±1px oscillation
STEPS=16         # Steps per full cycle
STEP_DELAY=0.5   # Seconds between steps (total cycle = STEPS * STEP_DELAY = 8s)

cleanup() {
    # Restore base gaps on exit
    hyprctl keyword general:gaps_in "$BASE_IN" >/dev/null 2>&1
    hyprctl keyword general:gaps_out "$BASE_OUT" >/dev/null 2>&1
    exit 0
}

trap cleanup SIGTERM SIGINT

step=0
while true; do
    # Sine wave oscillation: -1.0 to 1.0
    # Using integer math approximation with bc
    angle=$(echo "scale=4; 3.14159 * 2 * $step / $STEPS" | bc)
    sine=$(echo "scale=4; s($angle)" | bc -l)
    
    # Calculate gap values
    gap_in=$(echo "scale=0; $BASE_IN + ($AMPLITUDE * $sine + 0.5) / 1" | bc)
    gap_out=$(echo "scale=0; $BASE_OUT + ($AMPLITUDE * $sine + 0.5) / 1" | bc)
    
    # Clamp to reasonable range
    [ "$gap_in" -lt 5 ] && gap_in=5
    [ "$gap_in" -gt 7 ] && gap_in=7
    [ "$gap_out" -lt 11 ] && gap_out=11
    [ "$gap_out" -gt 13 ] && gap_out=13
    
    hyprctl keyword general:gaps_in "$gap_in" >/dev/null 2>&1
    hyprctl keyword general:gaps_out "$gap_out" >/dev/null 2>&1
    
    step=$(( (step + 1) % STEPS ))
    sleep "$STEP_DELAY"
done
