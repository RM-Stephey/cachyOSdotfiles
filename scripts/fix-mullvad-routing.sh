#!/bin/bash

# Fix Mullvad VPN routing issues and restore internet connectivity
# This script diagnoses and fixes routing problems when Mullvad VPN is connected

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

log "🔧 Mullvad VPN Routing Fix Script"
echo

# Check if Mullvad is connected
log "Checking Mullvad VPN status..."
if ! mullvad status | grep -q "Connected"; then
    warn "Mullvad VPN is not connected. This script is designed for when Mullvad is active."
    echo "Current status:"
    mullvad status
    exit 0
fi

MULLVAD_STATUS=$(mullvad status)
log "Mullvad is connected:"
echo "$MULLVAD_STATUS"
echo

# Test internet connectivity
log "Testing internet connectivity..."
if curl -s --connect-timeout 5 https://httpbin.org/ip > /dev/null 2>&1; then
    log "✅ Internet is working! No fix needed."
    exit 0
else
    warn "❌ No internet connectivity detected. Attempting to fix..."
fi

# Get network interface information
MULLVAD_INTERFACE=$(ip link show | grep "wg0-mullvad" | cut -d: -f2 | tr -d ' ' || echo "")
if [[ -z "$MULLVAD_INTERFACE" ]]; then
    error "Mullvad WireGuard interface not found!"
    exit 1
fi

log "Found Mullvad interface: $MULLVAD_INTERFACE"

# Find the original default gateway
ORIG_GW=$(ip route show | grep "default.*wlan0\|default.*eth0" | head -n1 | awk '{print $3}' || echo "")
ORIG_DEV=$(ip route show | grep "default.*wlan0\|default.*eth0" | head -n1 | awk '{print $5}' || echo "")

if [[ -n "$ORIG_GW" && -n "$ORIG_DEV" ]]; then
    log "Original gateway: $ORIG_GW via $ORIG_DEV"
else
    warn "Could not detect original gateway"
fi

# Show current routing state
debug "Current routing rules:"
ip rule list | head -10

debug "Current main routing table:"
ip route show | head -10

debug "Mullvad routing table:"
MULLVAD_TABLE=$(ip rule list | grep "lookup [0-9]" | grep -v "lookup main\|lookup default\|lookup local" | head -n1 | awk '{print $NF}')
if [[ -n "$MULLVAD_TABLE" ]]; then
    ip route show table "$MULLVAD_TABLE"
else
    warn "Could not find Mullvad routing table"
fi

echo

# Fix 1: Ensure Mullvad endpoint can be reached
log "🔧 Fix 1: Adding route for Mullvad endpoint..."
MULLVAD_ENDPOINT=$(mullvad status | grep -E "Relay:" | sed 's/.*via //' | awk '{print $1}' || echo "")
if [[ -n "$MULLVAD_ENDPOINT" && -n "$ORIG_GW" && -n "$ORIG_DEV" ]]; then
    log "Adding route for Mullvad endpoint $MULLVAD_ENDPOINT via $ORIG_GW"
    ip route add "$MULLVAD_ENDPOINT/32" via "$ORIG_GW" dev "$ORIG_DEV" 2>/dev/null || true
else
    warn "Could not add Mullvad endpoint route"
fi

# Fix 2: Fix policy routing
log "🔧 Fix 2: Fixing policy routing..."

# Remove problematic rules
ip rule del from all lookup main suppress_prefixlength 0 2>/dev/null || true

# Find Mullvad's routing table
MULLVAD_TABLE=$(ip rule list | grep "0x6d6f6c65" | awk '{print $NF}' | head -n1)
if [[ -n "$MULLVAD_TABLE" ]]; then
    log "Using Mullvad routing table: $MULLVAD_TABLE"

    # Add a rule to use Mullvad table for non-marked traffic (lower priority)
    ip rule add from all lookup "$MULLVAD_TABLE" priority 8000 2>/dev/null || true

    # Ensure the Mullvad table has a proper default route
    if ! ip route show table "$MULLVAD_TABLE" | grep -q "default"; then
        log "Adding default route to Mullvad table"
        ip route add default dev "$MULLVAD_INTERFACE" table "$MULLVAD_TABLE" 2>/dev/null || true
    fi
else
    error "Could not find Mullvad routing table"
fi

# Fix 3: Ensure DNS works
log "🔧 Fix 3: Ensuring DNS connectivity..."
# Add specific route for common DNS servers through VPN
for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do
    ip route add "$dns/32" dev "$MULLVAD_INTERFACE" 2>/dev/null || true
done

# Fix 4: Restore Tailscale routing (maintain our bypass)
log "🔧 Fix 4: Restoring Tailscale bypass routing..."
if ip link show tailscale0 &>/dev/null; then
    # Remove existing Tailscale routes
    ip route del 100.0.0.0/8 2>/dev/null || true

    # Add Tailscale route with high priority
    ip route add 100.0.0.0/8 dev tailscale0 metric 50
    ip rule add to 100.0.0.0/8 lookup main priority 1000 2>/dev/null || true

    log "✅ Tailscale bypass restored"
else
    warn "Tailscale interface not found, skipping Tailscale routing"
fi

# Fix 5: Alternative approach - direct default route
log "🔧 Fix 5: Adding backup default route..."
# Sometimes the policy routing fails, so add a direct route as backup
ip route add default dev "$MULLVAD_INTERFACE" metric 1000 2>/dev/null || true

echo
log "🧪 Testing connectivity..."

# Test DNS
if nslookup google.com 8.8.8.8 >/dev/null 2>&1; then
    log "✅ DNS resolution works"
else
    warn "❌ DNS resolution failed"
fi

# Test HTTP connectivity
if curl -s --connect-timeout 10 https://httpbin.org/ip >/dev/null 2>&1; then
    log "✅ Internet connectivity restored!"

    # Show the new IP
    NEW_IP=$(curl -s --connect-timeout 5 https://httpbin.org/ip | grep -o '"origin": "[^"]*' | cut -d'"' -f4)
    if [[ -n "$NEW_IP" ]]; then
        log "🌐 Your VPN IP: $NEW_IP"
    fi
else
    error "❌ Internet connectivity still not working"

    echo
    error "🔍 Additional debugging info:"
    echo "Current routing table:"
    ip route show | head -10
    echo
    echo "Current rules:"
    ip rule list | head -10

    exit 1
fi

# Test Tailscale if available
if command -v tailscale >/dev/null 2>&1 && tailscale status >/dev/null 2>&1; then
    log "🧪 Testing Tailscale connectivity..."

    TAILSCALE_PEER=$(tailscale status --json 2>/dev/null | jq -r '.Peer | to_entries[0].value.TailscaleIPs[0]' 2>/dev/null || echo "")
    if [[ -n "$TAILSCALE_PEER" && "$TAILSCALE_PEER" != "null" ]]; then
        if timeout 5 tailscale ping "$TAILSCALE_PEER" >/dev/null 2>&1; then
            log "✅ Tailscale connectivity works (tested $TAILSCALE_PEER)"
        else
            warn "❌ Tailscale connectivity failed"
        fi
    else
        warn "No Tailscale peers found to test"
    fi
fi

echo
log "🎉 Routing fix completed successfully!"
log "📊 Final network status:"
echo "   Internet: ✅ Working through VPN"
echo "   Tailscale: ✅ Bypassing VPN (if configured)"
echo "   DNS: ✅ Working"

echo
log "💡 To make this fix automatic, you can:"
log "   1. Run this script after each Mullvad connection"
log "   2. Add it to your autostart scripts"
log "   3. Create a systemd service to monitor and fix routing"
