#!/bin/bash

# Fix Tailscale routing when Mullvad VPN is connected
# This script ensures Tailscale traffic bypasses the VPN tunnel

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root for route modifications
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if Tailscale is running
if ! systemctl is-active --quiet tailscaled; then
    error "Tailscale daemon is not running"
    exit 1
fi

# Check if tailscale0 interface exists
if ! ip link show tailscale0 &>/dev/null; then
    error "Tailscale interface (tailscale0) not found"
    exit 1
fi

# Check if Mullvad is connected
if ! mullvad status | grep -q "Connected"; then
    warn "Mullvad VPN is not connected. Script may not be needed."
fi

# Get the current default gateway before VPN (usually your router)
DEFAULT_GW=$(ip route show | grep "^default" | grep -v "dev wg0-mullvad" | head -n1 | awk '{print $3}' || echo "")
DEFAULT_DEV=$(ip route show | grep "^default" | grep -v "dev wg0-mullvad" | head -n1 | awk '{print $5}' || echo "")

log "Detected default gateway: $DEFAULT_GW via $DEFAULT_DEV"

# Add route for Tailscale network to bypass VPN
log "Adding route for Tailscale network (100.0.0.0/8) to use tailscale0 interface..."

# Remove existing route if it exists
ip route del 100.0.0.0/8 &>/dev/null || true

# Add the route with higher priority (lower metric)
if ip route add 100.0.0.0/8 dev tailscale0 metric 50; then
    log "Successfully added Tailscale bypass route"
else
    error "Failed to add Tailscale bypass route"
    exit 1
fi

# Verify the route was added
if ip route show | grep -q "100.0.0.0/8 dev tailscale0"; then
    log "Route verification successful"
    echo
    log "Current Tailscale routes:"
    ip route show | grep "100\." || echo "No 100.x routes found"
else
    warn "Route verification failed"
fi

# Test Tailscale connectivity
log "Testing Tailscale connectivity..."
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
if [[ -n "$TAILSCALE_IP" ]]; then
    log "Your Tailscale IP: $TAILSCALE_IP"

    # Try to ping another Tailscale node if available
    OTHER_NODE=$(tailscale status --json 2>/dev/null | jq -r '.Peer | to_entries | .[0].value.TailscaleIPs[0]' 2>/dev/null || echo "")
    if [[ -n "$OTHER_NODE" && "$OTHER_NODE" != "null" ]]; then
        log "Testing connectivity to Tailscale peer $OTHER_NODE..."
        if timeout 5 ping -c 1 "$OTHER_NODE" &>/dev/null; then
            log "✅ Tailscale connectivity test successful!"
        else
            warn "❌ Tailscale connectivity test failed"
        fi
    fi
else
    warn "Could not determine Tailscale IP"
fi

# Show current routing table for verification
echo
log "Current routing table (relevant entries):"
echo "Default routes:"
ip route show | grep "^default" | head -3
echo "Tailscale routes:"
ip route show | grep "100\." || echo "No 100.x routes found"

echo
log "✅ Tailscale routing fix completed!"
log "Your Tailscale traffic should now bypass the Mullvad VPN tunnel."
log ""
log "💡 To make this persistent, you can:"
log "   1. Add this script to Mullvad's post-connect hooks (if available)"
log "   2. Run it manually after connecting to Mullvad"
log "   3. Create a systemd service to monitor and fix routing automatically"
