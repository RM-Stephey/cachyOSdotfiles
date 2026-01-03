#!/usr/bin/env bash
# Setup Electron desktop file overrides with WaylandLinuxDrmSyncobj flag
# This creates user desktop file overrides for Electron apps

DESKTOP_DIR="$HOME/.local/share/applications"
SYSTEM_DIRS=(
    "/usr/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
)

# Common Electron app desktop files to override
ELECTRON_APPS=(
    "discord.desktop"
    "code.desktop"
    "cursor.desktop"
    "spotify.desktop"
    "slack.desktop"
    "element-desktop.desktop"
    "signal-desktop.desktop"
    "telegram-desktop.desktop"
    "obsidian.desktop"
    "notion-app.desktop"
)

echo "Setting up Electron desktop file overrides..."
echo ""

# Create local applications directory if it doesn't exist
mkdir -p "$DESKTOP_DIR"

# Function to find desktop file
find_desktop_file() {
    local app_name="$1"
    for dir in "${SYSTEM_DIRS[@]}"; do
        if [ -f "$dir/$app_name" ]; then
            echo "$dir/$app_name"
            return 0
        fi
    done
    return 1
}

# Function to create override
create_override() {
    local source_file="$1"
    local target_file="$DESKTOP_DIR/$(basename "$source_file")"
    
    # Skip if override already exists
    if [ -f "$target_file" ]; then
        echo "⚠️  Override already exists: $target_file"
        return 1
    fi
    
    # Copy desktop file
    cp "$source_file" "$target_file"
    
    # Modify Exec line to use wrapper
    sed -i 's|^Exec=\(.*\)|Exec=/home/stephey/.config/hypr/scripts/electron-wrapper.sh \1|' "$target_file"
    
    # Also handle Exec lines with % arguments
    sed -i 's|^Exec=\([^%]*\)\(.*\)|Exec=/home/stephey/.config/hypr/scripts/electron-wrapper.sh \1\2|' "$target_file"
    
    echo "✅ Created override: $target_file"
    return 0
}

# Process each Electron app
CREATED=0
SKIPPED=0

for app in "${ELECTRON_APPS[@]}"; do
    source_file=$(find_desktop_file "$app")
    if [ -n "$source_file" ]; then
        if create_override "$source_file"; then
            CREATED=$((CREATED + 1))
        else
            SKIPPED=$((SKIPPED + 1))
        fi
    else
        echo "⚠️  Desktop file not found: $app"
    fi
done

echo ""
echo "Summary:"
echo "  Created: $CREATED overrides"
echo "  Skipped: $SKIPPED (already exist)"
echo ""
echo "To apply changes:"
echo "  1. Run: update-desktop-database ~/.local/share/applications"
echo "  2. Log out and back in, or restart your session"
echo ""
echo "To manually override a specific app:"
echo "  1. Find its desktop file: find /usr/share/applications -name '*.desktop' | grep <app-name>"
echo "  2. Copy to: ~/.local/share/applications/"
echo "  3. Edit Exec line to use: /home/stephey/.config/hypr/scripts/electron-wrapper.sh <original-exec>"
