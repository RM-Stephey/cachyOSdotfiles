#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃         Nvidia RTX 4090 Optimizations for Hyprland          ┃
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

# Check if running on Nvidia
check_nvidia() {
    if ! lspci | grep -i nvidia > /dev/null; then
        log_error "No Nvidia GPU detected!"
        exit 1
    fi

    local gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "Unknown")
    log_info "Detected GPU: $gpu_info"

    if [[ "$gpu_info" == *"4090"* ]]; then
        log_success "RTX 4090 detected - applying optimized settings"
    else
        log_warning "GPU is not RTX 4090, but continuing with Nvidia optimizations"
    fi
}

# Check kernel modules
check_kernel_modules() {
    log_info "Checking Nvidia kernel modules..."

    local modules=("nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm")
    local all_loaded=true

    for module in "${modules[@]}"; do
        if lsmod | grep -q "^$module"; then
            log_success "$module module loaded"
        else
            log_error "$module module not loaded"
            all_loaded=false
        fi
    done

    # Check DRM modeset
    if [ -f /sys/module/nvidia_drm/parameters/modeset ]; then
        local modeset=$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo "N")
        if [ "$modeset" = "Y" ]; then
            log_success "DRM modeset enabled"
        else
            log_error "DRM modeset not enabled! Add 'nvidia_drm.modeset=1' to kernel parameters"
        fi
    fi

    # Check fbdev
    if [ -f /sys/module/nvidia_drm/parameters/fbdev ]; then
        local fbdev=$(cat /sys/module/nvidia_drm/parameters/fbdev 2>/dev/null || echo "N")
        if [ "$fbdev" = "Y" ]; then
            log_success "Fbdev enabled (good for 570.86.16+)"
        else
            log_warning "Fbdev not enabled (normal for older drivers)"
        fi
    fi

    return $([ "$all_loaded" = true ] && echo 0 || echo 1)
}

# Check required packages
check_packages() {
    log_info "Checking required packages..."

    local packages=("nvidia-dkms" "nvidia-utils" "egl-wayland" "libva-nvidia-driver")
    local missing_packages=()

    for pkg in "${packages[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            log_success "$pkg installed"
        else
            # Check for alternatives
            case "$pkg" in
                "nvidia-dkms")
                    if pacman -Qi "nvidia" &>/dev/null; then
                        log_success "nvidia installed (alternative to nvidia-dkms)"
                    else
                        log_warning "$pkg not installed"
                        missing_packages+=("$pkg")
                    fi
                    ;;
                "libva-nvidia-driver")
                    if [ -f /usr/lib/dri/nvidia_drv_video.so ]; then
                        log_success "VA-API driver present"
                    else
                        log_warning "$pkg not installed (optional for hardware video acceleration)"
                        missing_packages+=("$pkg")
                    fi
                    ;;
                *)
                    log_warning "$pkg not installed"
                    missing_packages+=("$pkg")
                    ;;
            esac
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_warning "Missing packages: ${missing_packages[*]}"
        log_info "Install with: sudo pacman -S ${missing_packages[*]}"
    fi
}

# Generate Hyprland environment configuration
generate_env_config() {
    log_info "Generating Hyprland environment configuration..."

    local env_file="$HOME/.config/hypr/config/nvidia-env.conf"

    cat > "$env_file" << 'EOF'
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃            Nvidia RTX 4090 Environment Variables            ┃
# ┃                  Auto-generated Configuration               ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Core Nvidia Wayland Support
env = LIBVA_DRIVER_NAME, nvidia
env = __GLX_VENDOR_LIBRARY_NAME, nvidia
env = GBM_BACKEND, nvidia-drm

# RTX 4090 Performance Optimizations
env = __GL_GSYNC_ALLOWED, 1
env = __GL_VRR_ALLOWED, 0
env = WLR_DRM_NO_ATOMIC, 1
env = __GL_MaxFramesAllowed, 1
env = __GL_THREADED_OPTIMIZATIONS, 1

# VA-API Hardware Acceleration
env = NVD_BACKEND, direct
env = MOZ_DISABLE_RDD_SANDBOX, 1

# Nvidia Memory Management
env = NVIDIA_PRESERVE_VIDEO_MEMORY_ALLOCATIONS, 1

# Electron/CEF App Fixes
env = ELECTRON_OZONE_PLATFORM_HINT, auto

# XWayland Improvements
env = XWAYLAND_NO_GLAMOR, 0

# Vulkan Support
env = WLR_RENDERER, vulkan

# Cursor Fixes
env = WLR_NO_HARDWARE_CURSORS, 0
env = XCURSOR_SIZE, 24
EOF

    log_success "Environment configuration written to $env_file"
    log_info "Add 'source = ~/.config/hypr/config/nvidia-env.conf' to your hyprland.conf"
}

# Configure Electron apps
configure_electron_apps() {
    log_info "Configuring Electron applications..."

    # VSCodium/VSCode
    local codium_flags="$HOME/.config/codium-flags.conf"
    local code_flags="$HOME/.config/code-flags.conf"

    for flags_file in "$codium_flags" "$code_flags"; do
        if [ -f "$flags_file" ] || [ ! -f "$flags_file" ]; then
            cat > "$flags_file" << 'EOF'
--enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj
--ozone-platform=wayland
--enable-wayland-ime
EOF
            log_success "$(basename $flags_file) configured"
        fi
    done

    # Spotify
    local spotify_conf="$HOME/.config/spotify-launcher.conf"
    if command -v spotify-launcher &>/dev/null || [ ! -f "$spotify_conf" ]; then
        cat > "$spotify_conf" << 'EOF'
[spotify]
extra_arguments = ["--enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj", "--ozone-platform=wayland"]
EOF
        log_success "Spotify launcher configured"
    fi

    # Obsidian
    local obsidian_flags="$HOME/.config/obsidian/user-flags.conf"
    if [ -d "$HOME/.config/obsidian" ] || mkdir -p "$HOME/.config/obsidian" 2>/dev/null; then
        cat > "$obsidian_flags" << 'EOF'
--enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj
--ozone-platform=wayland
EOF
        log_success "Obsidian configured"
    fi
}

# Check suspend/resume services
check_suspend_services() {
    log_info "Checking Nvidia suspend/resume services..."

    local services=("nvidia-suspend" "nvidia-hibernate" "nvidia-resume")

    for service in "${services[@]}"; do
        if systemctl is-enabled "${service}.service" &>/dev/null; then
            log_success "${service}.service enabled"
        else
            log_warning "${service}.service not enabled"
            log_info "Enable with: sudo systemctl enable ${service}.service"
        fi
    done
}

# Apply runtime optimizations
apply_runtime_optimizations() {
    log_info "Applying runtime optimizations..."

    # Set GPU to prefer maximum performance (optional - uses more power)
    if command -v nvidia-settings &>/dev/null; then
        # Set to Adaptive mode (1) instead of Max Performance (2) for better thermals
        nvidia-settings -a '[gpu:0]/GpuPowerMizerMode=1' &>/dev/null && \
            log_success "GPU power mode set to Adaptive" || \
            log_warning "Could not set GPU power mode"
    fi

    # Enable GPU boost if available
    if command -v nvidia-smi &>/dev/null; then
        # Check current power limit
        local current_power=$(nvidia-smi -q -d POWER | grep "Power Limit" | head -1 | awk '{print $4}')
        log_info "Current GPU power limit: ${current_power}W"

        # RTX 4090 can go up to 450W or higher
        # Uncomment to set higher power limit (requires root):
        # sudo nvidia-smi -pl 450
    fi
}

# Main execution
main() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}         Nvidia RTX 4090 Optimization Check for Hyprland        ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    check_nvidia
    echo

    check_kernel_modules
    echo

    check_packages
    echo

    check_suspend_services
    echo

    if [ "${1:-}" = "--generate" ]; then
        generate_env_config
        echo

        configure_electron_apps
        echo

        apply_runtime_optimizations
        echo

        log_success "Optimization complete! Restart Hyprland to apply all changes."
        log_info "Use 'hyprctl reload' for a quick reload or logout/login for full effect."
    else
        log_info "Run with '--generate' to create configuration files:"
        log_info "  $0 --generate"
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

main "$@"
