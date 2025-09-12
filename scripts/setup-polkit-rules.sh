#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃           Setup PolicyKit Rules for Thunar Mounting         ┃
# ┃                    CachyOS Configuration                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run with sudo"
        log_info "Run: sudo $0"
        exit 1
    fi
}

# Create polkit rules for mounting
create_polkit_rules() {
    log_info "Creating PolicyKit rules for mounting..."

    # Create the rules directory if it doesn't exist
    mkdir -p /etc/polkit-1/rules.d

    # Create the rule file
    cat > /etc/polkit-1/rules.d/50-thunar-mount.rules << 'EOF'
// ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
// ┃         PolicyKit Rules for Thunar Drive Mounting           ┃
// ┃              Allow wheel group members to mount              ┃
// ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

// Allow members of the wheel group to mount filesystems without authentication
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.filesystem-mount" ||
         action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
         action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" ||
         action.id == "org.freedesktop.udisks2.filesystem-unmount" ||
         action.id == "org.freedesktop.udisks2.filesystem-unmount-others" ||
         action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
         action.id == "org.freedesktop.udisks2.encrypted-unlock-system" ||
         action.id == "org.freedesktop.udisks2.encrypted-unlock-other-seat" ||
         action.id == "org.freedesktop.udisks2.encrypted-lock-others") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});

// Allow members of the wheel group to modify devices (partitioning, formatting)
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.modify-device" ||
         action.id == "org.freedesktop.udisks2.modify-device-system" ||
         action.id == "org.freedesktop.udisks2.modify-device-other-seat") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN;
    }
});

// Allow members of the wheel group to power off drives
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.power-off-drive" ||
         action.id == "org.freedesktop.udisks2.power-off-drive-system" ||
         action.id == "org.freedesktop.udisks2.power-off-drive-other-seat" ||
         action.id == "org.freedesktop.udisks2.eject-media" ||
         action.id == "org.freedesktop.udisks2.eject-media-system" ||
         action.id == "org.freedesktop.udisks2.eject-media-other-seat") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});

// Allow members of the wheel group to manage loop devices
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.loop-setup" ||
         action.id == "org.freedesktop.udisks2.loop-delete") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});

// Allow members of the wheel group to access SMART data
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.ata-smart-update" ||
         action.id == "org.freedesktop.udisks2.ata-smart-simulate" ||
         action.id == "org.freedesktop.udisks2.ata-smart-selftest") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});

// Allow members of the wheel group to change filesystem labels
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.filesystem-set-label" ||
         action.id == "org.freedesktop.udisks2.filesystem-change-passphrase") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF

    log_success "PolicyKit rules created at /etc/polkit-1/rules.d/50-thunar-mount.rules"
}

# Create additional rules for gvfs operations
create_gvfs_rules() {
    log_info "Creating additional GVFS PolicyKit rules..."

    cat > /etc/polkit-1/rules.d/51-gvfs-admin.rules << 'EOF'
// ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
// ┃           PolicyKit Rules for GVFS Admin Access             ┃
// ┃              Allow wheel group admin:// access               ┃
// ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

// Allow members of wheel group to use admin:// backend in file managers
polkit.addRule(function(action, subject) {
    if ((action.id == "org.gtk.vfs.file-operations-helper") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN_KEEP;
    }
});
EOF

    log_success "GVFS PolicyKit rules created at /etc/polkit-1/rules.d/51-gvfs-admin.rules"
}

# Restart PolicyKit
restart_polkit() {
    log_info "Restarting PolicyKit daemon..."

    if systemctl restart polkit.service; then
        log_success "PolicyKit daemon restarted"
    else
        log_warning "Could not restart PolicyKit daemon, you may need to logout/login"
    fi
}

# Verify user is in wheel group
verify_user_groups() {
    local username="${SUDO_USER:-$USER}"
    log_info "Checking groups for user: $username"

    if groups "$username" | grep -q wheel; then
        log_success "User $username is in wheel group"
    else
        log_warning "User $username is NOT in wheel group!"
        log_info "Add user to wheel group with: sudo usermod -aG wheel $username"
    fi

    if groups "$username" | grep -q storage; then
        log_success "User $username is in storage group"
    else
        log_warning "User $username is NOT in storage group!"
        log_info "Add user to storage group with: sudo usermod -aG storage $username"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}        PolicyKit Rules Setup for Thunar Drive Mounting         ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    check_sudo
    verify_user_groups
    echo

    create_polkit_rules
    create_gvfs_rules
    echo

    restart_polkit
    echo

    log_success "Setup complete!"
    log_info "You should now be able to:"
    log_info "  • Mount/unmount drives without password"
    log_info "  • Unlock encrypted drives (will ask for encryption password only)"
    log_info "  • Access admin:// locations with authentication"
    log_info "  • Manage loop devices for disk images"

    echo
    echo -e "${YELLOW}Note:${NC} If mounting still requires authentication:"
    echo "  1. Logout and login again"
    echo "  2. Or restart your session"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

main "$@"
