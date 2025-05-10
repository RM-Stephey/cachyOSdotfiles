#!/usr/bin/env fish

# Ensure GNOME Keyring is running and unlocked
if pgrep -x "gnome-keyring-d" > /dev/null
    # Try to unlock the keyring 
    echo "Unlocking keyring..."
    echo $PASSWORD | gnome-keyring-daemon --unlock
    
    # Test if it worked
    if begin; echo "Test" | secret-tool store --label="Test" service test key test 2>/dev/null; end
        echo "Keyring unlocked successfully!"
        secret-tool lookup service test key test
        secret-tool clear service test key test
    else
        echo "Keyring unlock failed or already unlocked"
    end
else
    echo "GNOME Keyring daemon not running"
end
