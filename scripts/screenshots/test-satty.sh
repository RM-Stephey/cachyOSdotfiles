#!/bin/bash
# Test script for satty functionality

echo "Testing satty screenshot functionality..."
echo "This will take a fullscreen screenshot and open it in satty."
echo "Press Ctrl+C to cancel."
echo

# Take a fullscreen screenshot
TEMP_FILE="/tmp/satty_test_$(date +%s).png"
echo "Capturing screenshot to $TEMP_FILE..."
grim -t ppm "$TEMP_FILE"

# Check if the file exists and has content
if [ ! -s "$TEMP_FILE" ]; then
    echo "ERROR: Screenshot file is empty or not created!"
    exit 1
fi

echo "Screenshot captured successfully."
echo "File size: $(du -h "$TEMP_FILE" | cut -f1)"
echo "Opening in satty..."

# Open with satty - using correct options from documentation
satty --filename "$TEMP_FILE" --copy-command wl-copy

echo "Test complete."
echo "If satty opened with your screenshot, the basic functionality works."
echo "If not, there may be an issue with satty or its dependencies."

# Clean up
rm -f "$TEMP_FILE"

exit 0