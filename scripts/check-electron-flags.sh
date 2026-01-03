#!/usr/bin/env bash
# Check if Electron apps have WaylandLinuxDrmSyncobj flag enabled

echo "Checking for Electron processes..."
echo ""

# Find all Electron processes
ELECTRON_PROCS=$(pgrep -a electron 2>/dev/null)

if [ -z "$ELECTRON_PROCS" ]; then
    echo "❌ No Electron processes found running."
    echo "   Launch an Electron app first, then run this script again."
    exit 1
fi

echo "Found Electron processes:"
echo "$ELECTRON_PROCS"
echo ""

# Check each process for the flag
FOUND=0
while IFS= read -r line; do
    PID=$(echo "$line" | awk '{print $1}')
    CMD=$(echo "$line" | cut -d' ' -f2-)
    
    if echo "$CMD" | grep -q "WaylandLinuxDrmSyncobj"; then
        echo "✅ PID $PID: Flag ENABLED"
        echo "   Command: $CMD"
        FOUND=$((FOUND + 1))
    else
        echo "❌ PID $PID: Flag NOT found"
        echo "   Command: $CMD"
    fi
    echo ""
done <<< "$ELECTRON_PROCS"

# Summary
if [ $FOUND -gt 0 ]; then
    echo "✅ $FOUND process(es) have the flag enabled!"
else
    echo "❌ No processes found with the flag."
    echo ""
    echo "The ELECTRON_EXTRA_LAUNCH_ARGS env var may not be working."
    echo "You may need to use desktop file overrides instead."
fi
