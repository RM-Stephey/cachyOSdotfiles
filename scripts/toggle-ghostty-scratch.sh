#!/usr/bin/env bash
# Toggle Ghostty scratchpad on a special workspace without Pyprland.
# Behavior:
# - If scratch workspace is visible: hide it.
# - Else: ensure a Ghostty exists (launch if needed), move one to scratch if none there, then show and focus it.

set -euo pipefail

LAUNCHER="/home/stephey/.config/hypr/scripts/launch-ghostty-term.sh"
SCRATCH="special:term_ghostty"
CLASS="clipse"

scratch_visible() {
  hyprctl monitors -j | jq -e --arg ws "$SCRATCH" '.[] | select(.specialWorkspace.name == $ws)' >/dev/null 2>&1
}

first_client_on_scratch() {
  hyprctl clients -j | jq -r --arg cls "$CLASS" --arg ws "$SCRATCH" \
    'map(select(.class == $cls and .workspace.name == $ws)) | first | .address // empty'
}

first_client_anywhere() {
  hyprctl clients -j | jq -r --arg cls "$CLASS" \
    'map(select(.class == $cls)) | first | .address // empty'
}

ensure_running() {
  if ! pgrep -x ghostty >/dev/null 2>&1; then
    "$LAUNCHER" &
    sleep 0.25
  fi
}

if scratch_visible; then
  hyprctl dispatch togglespecialworkspace "$SCRATCH"
  exit 0
fi

ensure_running

addr=$(first_client_on_scratch)
if [[ -z "$addr" ]]; then
  addr=$(first_client_anywhere)
  if [[ -n "$addr" ]]; then
    hyprctl dispatch movetoworkspacesilent "$SCRATCH",address:"$addr"
  else
    # Newly launched will appear shortly; just toggle to show scratch
    :
  fi
fi

hyprctl dispatch togglespecialworkspace "$SCRATCH"

# Focus the Ghostty on scratch if present
addr=$(first_client_on_scratch)
if [[ -n "$addr" ]]; then
  hyprctl dispatch focuswindow address:"$addr"
fi
