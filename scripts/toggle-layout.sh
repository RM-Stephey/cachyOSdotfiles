#!/usr/bin/env bash

# Toggle between master and dwindle layouts in Hyprland
current_layout=$(hyprctl getoption general:layout | grep 'str:' | awk '{print $2}')
 
if [[ "$current_layout" == "master" ]]; then
    hyprctl keyword general:layout dwindle
else
    hyprctl keyword general:layout master
fi 