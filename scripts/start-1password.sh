#!/bin/bash

# Ensure environment variables are set
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"

/opt/1Password/1password --silent --use-system-authentication --on-system-unlock
