#!/bin/bash

# Nuclear Network Reset Script
# This script performs a complete network reset to restore clean networking state

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

log "☢️  NUCLEAR NETWORK RESET"
log "This will completely reset your network configuration"
echo

# Step 1: Stop all VPN services
log "🛑 Stopping all VPN services..."
mullvad disconnect 2>/dev/null || true
systemctl stop mullvad-daemon 2>/dev/null || true
sleep 3

# Kill any remaining Mullvad processes
pkill -f mullvad 2>/dev/null || true
sleep 2

# Step 2: Remove Mullvad interface if it exists
if ip link show wg0-mullvad 2>/dev/null; then
    log "🗑️  Removing Mullvad interface..."
    ip link delete wg0-mullvad 2>/dev/null || true
fi

# Step 3: Nuclear route table cleanup
log "💥 Nuclear route table cleanup..."

# Save original main table routes we want to keep
ORIGINAL_ROUTES=$(ip route show | grep -E "192\.168\.|10\.|172\.|wlan0|eth0" | grep -v "100\." || true)

# Flush all routing tables
for table in main default local 1836018789 52; do
    ip route flush table $table 2>/dev/null || true
done

# Step 4: Nuclear rule cleanup
log "🧨 Nuclear policy routing cleanup..."

# Remove ALL custom rules (keep only essential system rules 0, 32766, 32767)
ip rule show | grep -v "0:.*lookup local" | grep -v "32766:.*lookup main" | grep -v "32767:.*lookup default" | while read -r rule; do
    priority=$(echo "$rule" | sed 's/:.*//g')
    if [[ "$priority" =~ ^[0-9]+$ ]] && [[ "$priority" -ne 0 ]] && [[ "$priority" -ne 32766 ]] && [[ "$priority" -ne 32767 ]]; then
        ip rule del priority "$priority" 2>/dev/null || true
    fi
done

# Specific cleanup for known problematic rules
for fwmark in 0x6d6f6c65 0x80000/0xff0000; do
    while ip rule show | grep -q "$fwmark"; do
        ip rule del fwmark "$fwmark" 2>/dev/null || break
    done
done

# Step 5: Restore basic routing
log "🔧 Restoring basic network routes..."

# Restore saved routes
if [[ -n "$ORIGINAL_ROUTES" ]]; then
    echo "$ORIGINAL_ROUTES" | while read -r route; do
        ip route add $route 2>/dev/null || true
    done
fi

# Ensure we have a default route
DEFAULT_GW=$(ip route show | grep "default" | head -1 | awk '{print $3}' 2>/dev/null || echo "")
DEFAULT_DEV=$(ip route show | grep "default" | head -1 | awk '{print $5}' 2>/dev/null || echo "")

if [[ -z "$DEFAULT_GW" || -z "$DEFAULT_DEV" ]]; then
    # Try to detect gateway from DHCP
    if command -v dhcpcd >/dev/null; then
        dhcpcd -k wlan0 2>/dev/null || true
        dhcpcd wlan0 2>/dev/null || true
    elif command -v dhclient >/dev/null; then
        dhclient -r wlan0 2>/dev/null || true
        dhclient wlan0 2>/dev/null || true
    fi
fi

# Step 6: Reset network interfaces
log "🔌 Resetting network interfaces..."

# Restart NetworkManager if running
if systemctl is-active NetworkManager >/dev/null 2>&1; then
    systemctl restart NetworkManager
    sleep 5
fi

# Restart systemd networking if available
if systemctl is-active systemd-networkd >/dev/null 2>&1; then
    systemctl restart systemd-networkd
    sleep 3
fi

# Step 7: Clear any iptables rules that might interfere
log "🔥 Clearing firewall rules..."
iptables -t mangle -F 2>/dev/null || true
iptables -t mangle -X 2>/dev/null || true

# Step 8: Restart Mullvad daemon cleanly
log "🔄 Restarting Mullvad daemon..."
systemctl start mullvad-daemon
sleep 5

# Step 9: Restore Tailscale basic routing
if ip link show tailscale0 >/dev/null 2>&1; then
    log "🔗 Restoring Tailscale routing..."
    ip route add 100.0.0.0/8 dev tailscale0 metric 50 2>/dev/null || true

    # Restart Tailscale if needed
    if ! tailscale status >/dev/null 2>&1; then
        systemctl restart tailscaled 2>/dev/null || true
        sleep 3
    fi
fi

# Step 10: Test basic connectivity
log "🧪 Testing network connectivity..."

# Test 1: Basic internet without VPN
INTERNET_IP=$(curl -s --connect-timeout 10 https://httpbin.org/ip | jq -r '.origin' 2>/dev/null || echo "FAILED")
if [[ "$INTERNET_IP" == "FAILED" ]]; then
    warn "❌ Basic internet connectivity failed"

    # Emergency DHCP renewal
    log "🚨 Attempting emergency network recovery..."
    for interface in wlan0 eth0 enp*; do
        if ip link show "$interface" >/dev/null 2>&1; then
            dhcpcd "$interface" 2>/dev/null || dhclient "$interface" 2>/dev/null || true
        fi
    done

    sleep 5
    INTERNET_IP=$(curl -s --connect-timeout 10 https://httpbin.org/ip | jq -r '.origin' 2>/dev/null || echo "STILL_FAILED")
fi

if [[ "$INTERNET_IP" != "FAILED" && "$INTERNET_IP" != "STILL_FAILED" ]]; then
    log "✅ Basic internet works! Your IP: $INTERNET_IP"
else
    error "❌ Basic internet still not working"
    error "You may need to manually restart your network interface"
    exit 1
fi

# Test 2: Test Mullvad connection
log "🧪 Testing Mullvad VPN..."
mullvad connect >/dev/null 2>&1 || true
sleep 8

VPN_IP=$(curl -s --connect-timeout 15 https://httpbin.org/ip | jq -r '.origin' 2>/dev/null || echo "FAILED")
if [[ "$VPN_IP" != "FAILED" && "$VPN_IP" != "$INTERNET_IP" ]]; then
    log "✅ Mullvad VPN works! VPN IP: $VPN_IP"
    VPN_WORKING=true
else
    warn "❌ Mullvad VPN not working properly"
    VPN_WORKING=false
    mullvad disconnect >/dev/null 2>&1 || true
fi

# Test 3: Test Tailscale
if command -v tailscale >/dev/null && ip link show tailscale0 >/dev/null 2>&1; then
    log "🧪 Testing Tailscale..."

    if tailscale status >/dev/null 2>&1; then
        TAILSCALE_PEER=$(tailscale status | grep -E "100\.[0-9]+\.[0-9]+\.[0-9]+" | head -1 | awk '{print $1}' || echo "")
        if [[ -n "$TAILSCALE_PEER" ]] && timeout 10 tailscale ping "$TAILSCALE_PEER" >/dev/null 2>&1; then
            log "✅ Tailscale connectivity works!"
        else
            warn "❌ Tailscale connectivity issues"
        fi
    else
        warn "❌ Tailscale service not responding"
    fi
fi

echo
log "🎉 NUCLEAR RESET COMPLETE!"
echo
log "📊 Final Status:"
echo "   Internet (no VPN): ✅ $INTERNET_IP"
if [[ "$VPN_WORKING" == "true" ]]; then
    echo "   Mullvad VPN: ✅ $VPN_IP"
else
    echo "   Mullvad VPN: ❌ Not working"
fi

if ip link show tailscale0 >/dev/null 2>&1; then
    echo "   Tailscale: $(tailscale status >/dev/null 2>&1 && echo "✅ Running" || echo "❌ Issues")"
fi

echo
log "📋 Current routing table:"
ip route show | head -8

echo
log "📋 Current policy rules:"
ip rule show | head -5

if [[ "$VPN_WORKING" == "true" ]]; then
    echo
    log "🎯 SUCCESS: Your system is now in a clean working state!"
    log "Both internet and VPN work. We can now safely work on Tailscale bypass."
else
    echo
    warn "⚠️  Mullvad VPN still has issues. This might be a Mullvad configuration problem."
    log "But at least basic internet is restored!"
fi
