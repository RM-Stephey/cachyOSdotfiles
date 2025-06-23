#!/usr/bin/env bash

current_layout=$(hyprctl getoption general:layout | awk '/str/ {print $2}')

if [ "$current_layout" = "dwindle" ]; then
    hyprctl dispatch togglesplit
elif [ "$current_layout" = "master" ]; then
    state_file="/tmp/hypr_master_orientation"
    if [ ! -f "$state_file" ] || [ "$(cat $state_file)" = "left" ]; then
        hyprctl dispatch layoutmsg setorientation top
        echo "top" > "$state_file"
    else
        hyprctl dispatch layoutmsg setorientation left
        echo "left" > "$state_file"
    fi
fi 