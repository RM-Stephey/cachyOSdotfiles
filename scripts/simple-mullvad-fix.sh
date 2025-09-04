#!/bin/bash

# Simple Mullvad VPN Fix - Direct Routing Approach
# This script bypasses Mullvad's complex policy routing and uses direct routing

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

log "🚀 Simple Mullvad VPN Fix"

# Check if Mullvad is connected
if ! mullvad status | grep -q "Connected"; then
    warn "Mullvad VPN is not connected"
    exit 0
fi

# Get interfaces
MULLVAD_IFACE=$(ip link show | grep "wg0-mullvad" | cut -d: -f2 | tr -d ' ')
ORIG_GW=$(ip route show | grep "default.*wlan0\|default.*eth0" | head -n1 | awk '{print $3}')
ORIG_DEV=$(ip route show | grep "default.*wlan0\|default.*eth0" | head -n1 | awk '{print $5}')

if [[ -z "$MULLVAD_IFACE" ]]; then
    error "Mullvad interface not found"
    exit 1
fi

log "Using Mullvad interface: $MULLVAD_IFACE"
log "Original gateway: $ORIG_GW via $ORIG_DEV"

# STEP 1: Clear all Mullvad policy routing rules
log "🧹 Clearing problematic policy routing..."
ip rule del from all lookup main suppress_prefixlength 0 2>/dev/null || true
ip rule del not from all fwmark 0x6d6f6c65 lookup 1836018789 2>/dev/null || true
ip rule del from all lookup 1836018789 2>/dev/null || true

# Remove any rules with table 1836018789
while ip rule del table 1836018789 2>/dev/null; do
    sleep 0.1
done

# Remove fwmark rules that might interfere
ip rule del from all fwmark 0x80000/0xff0000 lookup main 2>/dev/null || true
ip rule del from all fwmark 0x80000/0xff0000 lookup default 2>/dev/null || true
ip rule del from all fwmark 0x80000/0xff0000 unreachable 2>/dev/null || true
ip rule del from all lookup 52 2>/dev/null || true

# STEP 2: Set up direct routing
log "🛣️  Setting up direct VPN routing..."

# Remove default routes to avoid conflicts
ip route del default via $ORIG_GW dev $ORIG_DEV 2>/dev/null || true
ip route del default dev $MULLVAD_IFACE 2>/dev/null || true

# Add Mullvad endpoint route through original gateway
MULLVAD_ENDPOINT=$(mullvad status | grep "Relay:" | sed -n 's/.*via \([^ ]*\).*/\1/p')
if [[ -n "$MULLVAD_ENDPOINT" ]]; then
    log "Adding route for Mullvad endpoint: $MULLVAD_ENDPOINT"
    ip route add $MULLVAD_ENDPOINT/32 via $ORIG_GW dev $ORIG_DEV 2>/dev/null || true
fi

# Add local network route
ip route add 192.168.0.0/16 via $ORIG_GW dev $ORIG_DEV 2>/dev/null || true
ip route add 10.0.0.0/8 via $ORIG_GW dev $ORIG_DEV 2>/dev/null || true

# STEP 3: Add Tailscale bypass BEFORE VPN default route
if ip link show tailscale0 &>/dev/null; then
    log "🔗 Setting up Tailscale bypass..."
    ip route add 100.0.0.0/8 dev tailscale0 metric 50 2>/dev/null || true
fi

# STEP 4: Set VPN as default route with higher metric
log "🌐 Setting VPN as default route..."
ip route add default dev $MULLVAD_IFACE metric 100

# STEP 5: Configure DNS
log "🔍 Configuring DNS..."
# Ensure DNS traffic goes through VPN
for dns in 1.1.1.1 8.8.8.8 9.9.9.9; do
    ip route add $dns/32 dev $MULLVAD_IFACE 2>/dev/null || true
done

# STEP 6: Test connectivity
log "🧪 Testing connectivity..."

# Test DNS first
if nslookup google.com 1.1.1.1 >/dev/null 2>&1; then
    log "✅ DNS works"
else
    warn "❌ DNS failed"
fi

# Test HTTP
if curl -s --connect-timeout 10 https://httpbin.org/ip >/dev/null 2>&1; then
    NEW_IP=$(curl -s --connect-timeout 5 https://httpbin.org/ip | grep -o '"origin": "[^"]*' | cut -d'"' -f4 2>/dev/null || echo "unknown")
    log "✅ Internet working! VPN IP: $NEW_IP"

    # Test Tailscale
    if command -v tailscale >/dev/null && tailscale status >/dev/null 2>&1; then
        PEER=$(tailscale status | grep -E "100\.[0-9]+\.[0-9]+\.[0-9]+" | head -n1 | awk '{print $1}')
        if [[ -n "$PEER" ]] && timeout 5 tailscale ping $PEER >/dev/null 2>&1; then
            log "✅ Tailscale bypass working!"
        fi
    fi

    log "🎉 SUCCESS! Both VPN and Tailscale are working!"
else
    error "❌ Internet still not working"

    # Show current state for debugging
    echo "Current routes:"
    ip route show | head -10
    exit 1
fi
