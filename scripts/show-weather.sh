#!/bin/bash

# You'll need to get an API key from https://openweathermap.org/
API_KEY="7cb6ec7b11b43352ea3a3b10c46b01f3"
CITY="Sanford,NC"
LAT="35.4799"
LON="-79.1803"
UNITS="imperial" # or imperial for Fahrenheit

# Get weather data
weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/forecast?lat=$LAT&lon=$LON&units=$UNITS&appid=$API_KEY")

# Extract information
#
echo "$weather_data" | jq .


temp=$(echo "$weather_data" | jq -r '.list[0].main.temp')
feels_like=$(echo "$weather_data" | jq -r '.list[0].main.feels_like')
description=$(echo "$weather_data" | jq -r '.list[0].weather[0].description')
humidity=$(echo "$weather_data" | jq -r '.list[0].main.humidity')
wind_speed=$(echo "$weather_data" | jq -r '.list[0].wind.speed')
icon_code=$(echo "$weather_data" | jq -r '.list[0].weather[0].icon')

# Determine weather icon
case ${icon_code:0:2} in
  "01") icon="󰖙" ;; # clear sky
  "02") icon="󰖕" ;; # few clouds
  "03") icon="󰖐" ;; # scattered clouds
  "04") icon="󰖐" ;; # broken clouds
  "09") icon="󰖖" ;; # shower rain
  "10") icon="󰖗" ;; # rain
  "11") icon="󰖓" ;; # thunderstorm
  "13") icon="󰖘" ;; # snow
  "50") icon="󰖑" ;; # mist
  *) icon="󰖙" ;; # default
esac

# Format the output
weather_info="<span size='xx-large'>$icon $temp°C</span>
<span size='large'>$description</span>
Feels like: $feels_like°F
Humidity: $humidity%
Wind: $wind_speed m/s"

# Display as a notification with HTML formatting
notify-send -i weather -t 10000 "Weather in $CITY" "$weather_info" -p

# Create a persistent weather notification for the notification center
# First, remove any existing persistent weather notifications
pkill -f "swaync-client -L -p -n weather"

# Add new persistent weather notification
swaync-client -L -p -n weather "$weather_info"
