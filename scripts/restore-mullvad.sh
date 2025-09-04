#!/bin/bash

# Restore Mullvad VPN to Original Working State
# This script undoes all the routing changes and restores default Mullvad behavior

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

log "🔄 Restoring Mullvad VPN to Original State"

# Step 1: Disconnect Mullvad
log "🔌 Disconnecting Mullvad VPN..."
mullvad disconnect || true
sleep 3

# Step 2: Clear all custom routing rules and routes
log "🧹 Clearing all custom routing rules..."

# Remove all custom rules (keep only essential system rules)
# Remove rules by priority number to avoid conflicts
for priority in 1000 5208 5209 5210 5230 5250 5270 8000; do
    ip rule del priority $priority 2>/dev/null || true
done

# Remove any remaining rules with Mullvad table
while ip rule del table 1836018789 2>/dev/null; do
    sleep 0.1
done

# Remove fwmark rules
ip rule del from all fwmark 0x6d6f6c65 lookup 1836018789 2>/dev/null || true
ip rule del not from all fwmark 0x6d6f6c65 lookup 1836018789 2>/dev/null || true
ip rule del from all fwmark 0x80000/0xff0000 lookup main 2>/dev/null || true
ip rule del from all fwmark 0x80000/0xff0000 lookup default 2>/dev/null || true
ip rule del from all fwmark 0x80000/0xff0000 unreachable 2>/dev/null || true
ip rule del from all lookup 52 2>/dev/null || true

# Step 3: Clear custom routes
log "🛣️  Clearing custom routes..."

# Remove Mullvad interface routes
if ip link show wg0-mullvad 2>/dev/null; then
    ip route flush dev wg0-mullvad 2>/dev/null || true
fi

# Remove any custom DNS routes
for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do
    ip route del $dns/32 2>/dev/null || true
done

# Remove custom default routes
ip route del default dev wg0-mullvad 2>/dev/null || true

# Remove Mullvad endpoint routes
ip route show | grep -E "23\.234\.|10\.64\." | while read route; do
    ip route del $route 2>/dev/null || true
done

# Step 4: Clear Mullvad routing tables
log "🗂️  Clearing Mullvad routing tables..."
ip route flush table 1836018789 2>/dev/null || true

# Step 5: Restart networking to ensure clean state
log "🔄 Restarting network services..."
systemctl restart systemd-networkd 2>/dev/null || true
systemctl restart NetworkManager 2>/dev/null || true

# Wait for network to stabilize
sleep 5

# Step 6: Test basic connectivity
log "🧪 Testing basic internet connectivity..."
if curl -s --connect-timeout 10 https://httpbin.org/ip >/dev/null 2>&1; then
    CURRENT_IP=$(curl -s --connect-timeout 5 https://httpbin.org/ip | grep -o '"origin": "[^"]*' | cut -d'"' -f4 2>/dev/null || echo "unknown")
    log "✅ Internet connectivity restored! Your IP: $CURRENT_IP"
else
    warn "❌ Internet connectivity issue persists"
fi

# Step 7: Restore Tailscale if it exists
if ip link show tailscale0 &>/dev/null; then
    log "🔗 Restoring basic Tailscale routing..."
    ip route add 100.0.0.0/8 dev tailscale0 metric 50 2>/dev/null || true

    if tailscale status >/dev/null 2>&1; then
        log "✅ Tailscale service is running"
    else
        warn "Tailscale service might need to be restarted"
    fi
fi

echo
log "🎉 Restoration complete!"
log "📋 What to do next:"
log "   1. Test that your internet works WITHOUT Mullvad"
log "   2. If internet works, try: 'mullvad connect'"
log "   3. If Mullvad works normally, great! If not, we'll need a different approach."

echo
log "💡 Current network status:"
echo "   Internet: $(curl -s --connect-timeout 3 https://httpbin.org/ip | grep -o '"origin": "[^"]*' | cut -d'"' -f4 2>/dev/null || echo "Not working")"
echo "   Mullvad: $(mullvad status | head -1)"

if command -v tailscale >/dev/null && tailscale status >/dev/null 2>&1; then
    echo "   Tailscale: ✅ Running"
else
    echo "   Tailscale: ❓ Unknown"
fi
