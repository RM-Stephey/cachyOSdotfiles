#!/bin/bash

# Basic Mullvad VPN Fix Script
# Restores essential Mullvad routing functionality

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

log "🔧 Basic Mullvad VPN Fix"

# Check if Mullvad is connected
if ! mullvad status | grep -q "Connected"; then
    warn "Mullvad is not connected. Connecting first..."
    mullvad connect
    sleep 8
fi

# Check if Mullvad says it's connected but we have no internet
if ! curl -s --connect-timeout 5 https://httpbin.org/ip >/dev/null 2>&1; then
    log "Mullvad connected but no internet. Fixing routing..."

    # Get network info
    MULLVAD_IFACE="wg0-mullvad"
    ORIG_GW=$(ip route show | grep "default.*wlan0\|default.*eth0" | head -1 | awk '{print $3}' 2>/dev/null || echo "192.168.50.1")
    ORIG_DEV=$(ip route show | grep "default.*wlan0\|default.*eth0" | head -1 | awk '{print $5}' 2>/dev/null || echo "wlan0")

    log "Using original gateway: $ORIG_GW via $ORIG_DEV"

    # Get Mullvad endpoint
    MULLVAD_ENDPOINT=$(mullvad status | grep "Relay:" | sed -n 's/.*via \([^ ]*\).*/\1/p' 2>/dev/null || echo "")

    if [[ -n "$MULLVAD_ENDPOINT" ]]; then
        log "Adding route for Mullvad endpoint: $MULLVAD_ENDPOINT"
        ip route add "$MULLVAD_ENDPOINT/32" via "$ORIG_GW" dev "$ORIG_DEV" 2>/dev/null || true
    fi

    # Ensure we have routes for Mullvad's internal IPs
    ip route add 10.64.0.0/16 dev "$MULLVAD_IFACE" 2>/dev/null || true

    # Fix DNS routing - force DNS through VPN
    log "Setting up DNS routing through VPN..."
    for dns in 1.1.1.1 8.8.8.8 9.9.9.9 1.0.0.1 8.8.4.4; do
        ip route add "$dns/32" dev "$MULLVAD_IFACE" 2>/dev/null || true
    done

    # Add default route through VPN (but only if none exists)
    if ! ip route show | grep -q "^default.*$MULLVAD_IFACE"; then
        log "Adding default route through VPN"

        # Remove any existing default routes through VPN
        ip route del default dev "$MULLVAD_IFACE" 2>/dev/null || true

        # Add new default route with higher priority
        ip route add default dev "$MULLVAD_IFACE" metric 10
    fi

    # Test DNS first
    log "Testing DNS resolution..."
    if nslookup google.com 1.1.1.1 >/dev/null 2>&1; then
        log "✅ DNS works"
    else
        warn "❌ DNS still broken, trying to fix..."
        # Try adding more specific DNS routes
        ip route add 0.0.0.0/0 dev "$MULLVAD_IFACE" metric 100 2>/dev/null || true
    fi

    # Test connectivity
    log "Testing internet connectivity..."
    if curl -s --connect-timeout 10 https://httpbin.org/ip >/dev/null 2>&1; then
        NEW_IP=$(curl -s --connect-timeout 5 https://httpbin.org/ip | grep -o '"origin": "[^"]*' | cut -d'"' -f4 2>/dev/null || echo "unknown")
        log "✅ Internet restored! VPN IP: $NEW_IP"
    else
        error "❌ Still no internet. May need manual intervention."

        log "Current routes:"
        ip route show | head -8

        log "Testing DNS manually:"
        nslookup google.com 1.1.1.1 || echo "DNS failed"

        log "Try manually running:"
        log "  ip route add default dev $MULLVAD_IFACE"
        log "  ip route add 1.1.1.1/32 dev $MULLVAD_IFACE"
        exit 1
    fi

else
    # Mullvad is working
    VPN_IP=$(curl -s --connect-timeout 5 https://httpbin.org/ip | grep -o '"origin": "[^"]*' | cut -d'"' -f4 2>/dev/null || echo "unknown")
    log "✅ Mullvad is already working! VPN IP: $VPN_IP"
fi

log "🎉 Mullvad VPN is now functional!"
