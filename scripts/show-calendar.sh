#!/bin/bash

# Get the current month display
month_display=$(cal | head -1)
today=$(date +%-d)
calendar_output=$(cal | sed -e "s/\b$today\b/<b><span foreground='#ff00ff'>$today<\/span><\/b>/")
next_events=""

# Check if calcurse is installed
if command -v calcurse &> /dev/null; then
  # Get next 3 events from calcurse
  next_events=$(calcurse -d 7 --format-apt "• %m-%d: %S" | head -3)
  if [ -n "$next_events" ]; then
    next_events="<b><span foreground='#00d8ff'>Upcoming Events:</span></b>\n$next_events"
  fi
fi

# Combine the calendar display and events
full_calendar="<span font='JetBrainsMono Nerd Font Mono 14'><b>$month_display</b>\n$calendar_output</span>"
if [ -n "$next_events" ]; then
  full_calendar="$full_calendar\n\n$next_events"
fi

# Show as a notification
notify-send -i calendar -t 15000 "Calendar" "$full_calendar" -p

# Create a persistent calendar notification for the notification center
pkill -f "swaync-client -L -p -n calendar"
swaync-client -L -p -n calendar "$full_calendar"
