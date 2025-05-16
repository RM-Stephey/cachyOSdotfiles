#!/bin/bash
battery_info=$(acpi -b)
notify-send "Battery Status" "$battery_info" -i battery
