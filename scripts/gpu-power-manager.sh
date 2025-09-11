#!/bin/bash
# GPU Power Management and Balancing Script for Hyprland
# Manages Intel iGPU and NVIDIA RTX 4090 power consumption

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root for some operations
check_root() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Get current GPU usage
get_gpu_status() {
    print_info "Current GPU Status:"

    # Intel GPU status
    if command -v intel_gpu_top &> /dev/null; then
        echo -e "\n${BLUE}Intel iGPU:${NC}"
        timeout 1s intel_gpu_top -l | head -n 20 || true
    else
        print_warning "intel_gpu_top not installed. Install intel-gpu-tools for iGPU monitoring."
    fi

    # NVIDIA GPU status
    echo -e "\n${BLUE}NVIDIA RTX 4090:${NC}"
    nvidia-smi --query-gpu=name,temperature.gpu,power.draw,power.limit,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits
}

# Set NVIDIA power limit
set_nvidia_power_limit() {
    local power_limit=$1

    if ! check_root; then
        print_info "Setting NVIDIA power limit to ${power_limit}W (requires sudo)..."
        sudo nvidia-smi -pl "$power_limit"
    else
        nvidia-smi -pl "$power_limit"
    fi

    print_success "NVIDIA power limit set to ${power_limit}W"
}

# Configure PRIME offloading
configure_prime_offload() {
    print_info "Configuring PRIME render offload..."

    # Set environment variables for PRIME offload
    cat > ~/.config/environment.d/51-prime-offload.conf << EOF
# PRIME Render Offload Configuration
# Use Intel iGPU by default, NVIDIA for specific apps
__NV_PRIME_RENDER_OFFLOAD=1
__GLX_VENDOR_LIBRARY_NAME=mesa
__VK_LAYER_NV_optimus=NVIDIA_only
DRI_PRIME=0
EOF

    print_success "PRIME offload configured. Use 'prime-run' to run apps on NVIDIA GPU."
}

# Create prime-run wrapper
create_prime_run() {
    print_info "Creating prime-run wrapper..."

    cat > ~/.local/bin/prime-run << 'EOF'
#!/bin/bash
# Run application with NVIDIA GPU
export __NV_PRIME_RENDER_OFFLOAD=1
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
exec "$@"
EOF

    chmod +x ~/.local/bin/prime-run
    print_success "prime-run wrapper created at ~/.local/bin/prime-run"
}

# Set Intel GPU power profile
set_intel_power_profile() {
    local profile=$1

    # Check if i915 module parameters are available
    if [[ -d /sys/module/i915/parameters ]]; then
        case $profile in
            "powersave")
                # Enable power saving features
                echo 1 | sudo tee /sys/module/i915/parameters/enable_rc6 > /dev/null
                echo 1 | sudo tee /sys/module/i915/parameters/enable_fbc > /dev/null
                echo 1 | sudo tee /sys/module/i915/parameters/enable_psr > /dev/null
                print_success "Intel iGPU set to powersave mode"
                ;;
            "balanced")
                echo 1 | sudo tee /sys/module/i915/parameters/enable_rc6 > /dev/null
                echo 0 | sudo tee /sys/module/i915/parameters/enable_fbc > /dev/null
                echo 0 | sudo tee /sys/module/i915/parameters/enable_psr > /dev/null
                print_success "Intel iGPU set to balanced mode"
                ;;
            "performance")
                echo 0 | sudo tee /sys/module/i915/parameters/enable_rc6 > /dev/null
                echo 0 | sudo tee /sys/module/i915/parameters/enable_fbc > /dev/null
                echo 0 | sudo tee /sys/module/i915/parameters/enable_psr > /dev/null
                print_success "Intel iGPU set to performance mode"
                ;;
            *)
                print_error "Invalid profile. Use: powersave, balanced, or performance"
                return 1
                ;;
        esac
    else
        print_error "Intel GPU parameters not accessible"
    fi
}

# Configure DRI_PRIME for specific applications
setup_app_gpu_assignments() {
    print_info "Setting up application GPU assignments..."

    # Create desktop file overrides for common apps
    mkdir -p ~/.local/share/applications

    # Example: Run browsers on iGPU
    for browser in firefox chromium google-chrome vivaldi; do
        if command -v $browser &> /dev/null; then
            desktop_file="/usr/share/applications/$browser.desktop"
            if [[ -f "$desktop_file" ]]; then
                cp "$desktop_file" ~/.local/share/applications/
                sed -i "s/^Exec=/Exec=env DRI_PRIME=0 /" ~/.local/share/applications/$browser.desktop
                print_success "$browser configured to use iGPU"
            fi
        fi
    done
}

# Create GPU monitor script for Waybar
create_gpu_monitor() {
    print_info "Creating GPU monitor script for Waybar..."

    cat > ~/.config/waybar/modules/gpu-monitor.sh << 'EOF'
#!/bin/bash
# GPU Monitor for Waybar

# Get Intel GPU usage (requires intel_gpu_top)
if command -v intel_gpu_top &> /dev/null; then
    INTEL_USAGE=$(timeout 0.5s intel_gpu_top -o - | grep -oP 'Render/3D/0:.*?(?=%)' | tail -1 | awk '{print $NF}')
    INTEL_USAGE=${INTEL_USAGE:-0}
else
    INTEL_USAGE="N/A"
fi

# Get NVIDIA GPU usage
NVIDIA_USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0")
NVIDIA_POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null || echo "0")

# Format output for Waybar
if [[ "$INTEL_USAGE" != "N/A" ]]; then
    echo "{\"text\": \"iGPU: ${INTEL_USAGE}% | RTX: ${NVIDIA_USAGE}% ${NVIDIA_POWER}W\", \"tooltip\": \"Intel: ${INTEL_USAGE}%\\nNVIDIA: ${NVIDIA_USAGE}% @ ${NVIDIA_POWER}W\"}"
else
    echo "{\"text\": \"RTX: ${NVIDIA_USAGE}% ${NVIDIA_POWER}W\", \"tooltip\": \"NVIDIA: ${NVIDIA_USAGE}% @ ${NVIDIA_POWER}W\"}"
fi
EOF

    chmod +x ~/.config/waybar/modules/gpu-monitor.sh
    print_success "GPU monitor created for Waybar integration"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}GPU Power Management Menu${NC}"
    echo "=========================="
    echo "1) Show current GPU status"
    echo "2) Set NVIDIA power limit (25W-175W)"
    echo "3) Configure PRIME render offload"
    echo "4) Set Intel GPU power profile"
    echo "5) Setup app GPU assignments"
    echo "6) Apply power-saving preset"
    echo "7) Apply balanced preset"
    echo "8) Apply performance preset"
    echo "9) Create monitoring tools"
    echo "0) Exit"
    echo -n "Select option: "
}

# Preset configurations
apply_powersave_preset() {
    print_info "Applying power-saving preset..."
    set_nvidia_power_limit 50
    set_intel_power_profile "powersave"
    configure_prime_offload
    print_success "Power-saving preset applied"
}

apply_balanced_preset() {
    print_info "Applying balanced preset..."
    set_nvidia_power_limit 100
    set_intel_power_profile "balanced"
    configure_prime_offload
    print_success "Balanced preset applied"
}

apply_performance_preset() {
    print_info "Applying performance preset..."
    set_nvidia_power_limit 175
    set_intel_power_profile "performance"
    print_success "Performance preset applied"
}

# Main execution
main() {
    print_info "GPU Power Manager for Intel iGPU + NVIDIA RTX 4090"

    while true; do
        show_menu
        read -r choice

        case $choice in
            1)
                get_gpu_status
                ;;
            2)
                read -p "Enter power limit in watts (25-175): " power_limit
                set_nvidia_power_limit "$power_limit"
                ;;
            3)
                configure_prime_offload
                create_prime_run
                ;;
            4)
                echo "Select profile: powersave, balanced, performance"
                read -p "Profile: " profile
                set_intel_power_profile "$profile"
                ;;
            5)
                setup_app_gpu_assignments
                ;;
            6)
                apply_powersave_preset
                ;;
            7)
                apply_balanced_preset
                ;;
            8)
                apply_performance_preset
                ;;
            9)
                create_gpu_monitor
                ;;
            0)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac

        echo -e "\nPress Enter to continue..."
        read -r
    done
}

# Run main function
main "$@"
