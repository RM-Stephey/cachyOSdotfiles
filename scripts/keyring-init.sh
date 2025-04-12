#!/usr/bin/fish

# Kill any existing keyring processes
pkill -9 gnome-keyring-daemon

# Start GNOME Keyring
/usr/bin/gnome-keyring-daemon --start --components=secrets &

# Wait for keyring to be available
while not test -f /run/user/(id -u)/keyring/control
    sleep 1
end

# Configure 1Password system authentication
mkdir -p ~/.config/1Password/settings
echo '{
  "version": 1,
  "systemAuthentication": {
    "enabled": true,
    "useSecretService": true,
    "autoUnlock": true
  }
}' > ~/.config/1Password/settings/authentication.json

# Start 1Password with system authentication and Wayland support
sleep 2
/opt/1Password/1password --ozone-platform-hint=auto --silent --use-system-authentication 