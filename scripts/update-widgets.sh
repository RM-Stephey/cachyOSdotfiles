#!/bin/bash

trap "exit" SIGTERM

while true; do
  # Update weather every 30 minutes
  ~/.config/hypr/scripts/show-weather.sh

  # Update calendar daily
  ~/.config/hypr/scripts/show-calendar.sh

  # Sleep for 30 minutes
  sleep 1800
done
