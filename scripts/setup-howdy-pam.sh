#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃          Setup Howdy Face Authentication for PAM            ┃
# ┃           System-wide Configuration with 1Password          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Check if Howdy is installed
check_howdy() {
    log_info "Checking Howdy installation..."

    if command -v howdy >/dev/null 2>&1; then
        local version=$(howdy version 2>/dev/null || echo "Unknown")
        log_success "Howdy is installed: $version"

        # Check if PAM module exists
        if [ -f "/lib/security/pam_howdy.so" ]; then
            log_success "Howdy PAM module found at /lib/security/pam_howdy.so"
        else
            log_error "Howdy PAM module not found!"
            log_info "Please reinstall Howdy or check your installation"
            exit 1
        fi
    else
        log_error "Howdy is not installed!"
        log_info "Install Howdy first: yay -S howdy"
        exit 1
    fi
}

# Backup PAM configuration files
backup_pam_files() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    log_info "Creating PAM configuration backups..."

    local files=("system-auth" "polkit-1" "sudo" "sddm" "login")

    for file in "${files[@]}"; do
        if [ -f "/etc/pam.d/$file" ]; then
            cp "/etc/pam.d/$file" "/etc/pam.d/${file}.backup.${timestamp}"
            log_success "Backed up /etc/pam.d/$file"
        fi
    done
}

# Configure system-auth with Howdy
configure_system_auth() {
    log_info "Configuring /etc/pam.d/system-auth for Howdy..."

    local pam_file="/etc/pam.d/system-auth"

    # Check if Howdy is already configured
    if grep -q "pam_howdy.so" "$pam_file" 2>/dev/null; then
        log_warning "Howdy already configured in system-auth, skipping..."
        return
    fi

    # Create new system-auth with Howdy
    cat > "$pam_file" << 'EOF'
#%PAM-1.0

# Howdy face authentication (sufficient means if it succeeds, skip other auth methods)
auth       sufficient                  pam_howdy.so

auth       required                    pam_faillock.so      preauth
# Optionally use requisite above if you do not want to prompt for the password
# on locked accounts.
-auth      [success=2 default=ignore]  pam_systemd_home.so
auth       [success=1 default=bad]     pam_unix.so          try_first_pass nullok
auth       [default=die]               pam_faillock.so      authfail

auth       optional                    pam_permit.so
auth       required                    pam_env.so
auth       required                    pam_faillock.so      authsucc
# If you drop the above call to pam_faillock.so the lock will be done also
# on non-consecutive authentication failures.

-account   [success=1 default=ignore]  pam_systemd_home.so
account    required                    pam_unix.so
account    optional                    pam_permit.so
account    required                    pam_time.so

-password  [success=1 default=ignore]  pam_systemd_home.so
password   required                    pam_unix.so          try_first_pass nullok shadow
password   optional                    pam_permit.so

-session   optional                    pam_systemd_home.so
session    required                    pam_limits.so
session    required                    pam_unix.so
session    optional                    pam_permit.so
EOF

    log_success "Configured system-auth with Howdy"
}

# Configure polkit-1 with Howdy
configure_polkit() {
    log_info "Configuring /etc/pam.d/polkit-1 for Howdy..."

    local pam_file="/etc/pam.d/polkit-1"

    # Check if Howdy is already configured
    if grep -q "pam_howdy.so" "$pam_file" 2>/dev/null; then
        log_warning "Howdy already configured in polkit-1, updating..."
    fi

    # Create polkit-1 configuration optimized for Howdy
    cat > "$pam_file" << 'EOF'
#%PAM-1.0

# Howdy face authentication for PolicyKit
auth       sufficient                  pam_howdy.so

# Include system-auth for fallback authentication
auth       include                     system-auth
account    include                     system-auth
session    include                     system-auth
EOF

    log_success "Configured polkit-1 with Howdy"
}

# Configure sudo with Howdy (if not already done)
configure_sudo() {
    log_info "Checking /etc/pam.d/sudo for Howdy..."

    local pam_file="/etc/pam.d/sudo"

    if grep -q "pam_howdy.so" "$pam_file" 2>/dev/null; then
        log_success "Howdy already configured in sudo"
        return
    fi

    # Add Howdy to sudo
    cat > "$pam_file" << 'EOF'
#%PAM-1.0

# Howdy face authentication for sudo
auth       sufficient                  pam_howdy.so

auth       include                     system-auth
account    include                     system-auth
session    include                     system-auth
EOF

    log_success "Configured sudo with Howdy"
}

# Configure SDDM with Howdy (if exists)
configure_sddm() {
    local pam_file="/etc/pam.d/sddm"

    if [ ! -f "$pam_file" ]; then
        log_info "SDDM not found, skipping..."
        return
    fi

    log_info "Configuring /etc/pam.d/sddm for Howdy..."

    if grep -q "pam_howdy.so" "$pam_file" 2>/dev/null; then
        log_warning "Howdy already configured in SDDM"
        return
    fi

    # Add Howdy to SDDM
    cat > "$pam_file" << 'EOF'
#%PAM-1.0

# Howdy face authentication for SDDM login
auth       sufficient                  pam_howdy.so

auth       include                     system-auth
-auth      optional                    pam_gnome_keyring.so
-auth      optional                    pam_kwallet5.so

account    include                     system-auth

password   include                     system-auth
-password  optional                    pam_gnome_keyring.so use_authtok

session    include                     system-auth
-session   optional                    pam_keyinit.so revoke
-session   optional                    pam_gnome_keyring.so auto_start
-session   optional                    pam_kwallet5.so auto_start
EOF

    log_success "Configured SDDM with Howdy"
}

# Configure Howdy settings for better 1Password integration
configure_howdy_settings() {
    log_info "Optimizing Howdy settings for desktop authentication..."

    local config_file="/lib/security/howdy/config.ini"

    if [ ! -f "$config_file" ]; then
        log_warning "Howdy config file not found at $config_file"
        return
    fi

    # Backup original config
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"

    # Update Howdy configuration for better desktop experience
    # Set certainty to 4 (balanced) for better recognition
    sed -i 's/^certainty = .*/certainty = 4/' "$config_file" 2>/dev/null || true

    # Enable faster timeout for desktop use
    sed -i 's/^timeout = .*/timeout = 4/' "$config_file" 2>/dev/null || true

    # Disable "detection_notice" for cleaner experience
    sed -i 's/^detection_notice = .*/detection_notice = false/' "$config_file" 2>/dev/null || true

    # Enable "suppress_unknown" to avoid messages for unknown faces
    sed -i 's/^suppress_unknown = .*/suppress_unknown = true/' "$config_file" 2>/dev/null || true

    log_success "Optimized Howdy settings for desktop use"
}

# Test Howdy authentication
test_howdy() {
    log_info "Testing Howdy authentication..."

    echo
    log_info "Testing sudo with Howdy (look at your camera)..."

    # Run as the original user, not root
    local original_user="${SUDO_USER:-$USER}"

    su - "$original_user" -c "sudo -k && sudo echo 'Howdy authentication successful!'" && {
        log_success "Howdy is working with sudo!"
    } || {
        log_warning "Howdy test failed, but configuration is complete"
        log_info "You may need to add your face: sudo howdy add"
    }
}

# Restart authentication services
restart_services() {
    log_info "Restarting authentication services..."

    # Restart PolicyKit
    if systemctl restart polkit.service 2>/dev/null; then
        log_success "PolicyKit restarted"
    fi

    # Restart the Hyprland polkit agent if it's running
    local original_user="${SUDO_USER:-$USER}"
    if su - "$original_user" -c "systemctl --user restart hyprpolkitagent.service" 2>/dev/null; then
        log_success "Hyprpolkitagent restarted"
    fi
}

# Main execution
main() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}         Howdy Face Authentication Setup for PAM              ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    check_sudo
    check_howdy
    echo

    backup_pam_files
    echo

    configure_system_auth
    configure_polkit
    configure_sudo
    configure_sddm
    echo

    configure_howdy_settings
    echo

    restart_services
    echo

    test_howdy
    echo

    log_success "Howdy PAM configuration complete!"
    echo
    log_info "What's been configured:"
    log_info "  • System-wide authentication (system-auth)"
    log_info "  • PolicyKit authentication (for GUI apps like 1Password)"
    log_info "  • Sudo authentication"
    log_info "  • SDDM login (if applicable)"
    echo
    log_info "1Password should now:"
    log_info "  • Show the fingerprint icon"
    log_info "  • Trigger Howdy face authentication"
    log_info "  • Work with hyprpolkitagent for auth prompts"
    echo
    log_warning "Important:"
    log_warning "  • Restart 1Password for changes to take effect"
    log_warning "  • You may need to logout/login for full effect"
    log_warning "  • If face auth fails, password fallback is available"
    echo
    log_info "To add/manage faces:"
    log_info "  • Add new face: sudo howdy add"
    log_info "  • List faces: sudo howdy list"
    log_info "  • Remove face: sudo howdy remove [ID]"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

main "$@"
