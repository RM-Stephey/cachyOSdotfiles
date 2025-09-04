#!/usr/bin/env bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                      StepheyBot Theme Manager                ┃
# ┃                   Safe Hyprland Customization                ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

set -euo pipefail

# Configuration paths
HYPR_DIR="$HOME/.config/hypr"
USER_CONFIG="$HYPR_DIR/config/user-config.conf"
STEPHEYBOT_DIR="$HYPR_DIR/stepheybot"
BACKUP_DIR="$STEPHEYBOT_DIR/backups"

# Theme presets
NEON_INTENSE="neon-intense"
NEON_BALANCED="neon-balanced"
PERFORMANCE="performance"
MINIMAL="minimal"
CYBERPUNK="cyberpunk"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# StepheyBot ASCII
print_logo() {
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║  ███████╗████████╗███████╗██████╗ ██╗  ██╗███████╗██╗   ██╗  ║
    ║  ██╔════╝╚══██╔══╝██╔════╝██╔══██╗██║  ██║██╔════╝╚██╗ ██╔╝  ║
    ║  ███████╗   ██║   █████╗  ██████╔╝███████║█████╗   ╚████╔╝   ║
    ║  ╚════██║   ██║   ██╔══╝  ██╔═══╝ ██╔══██║██╔══╝    ╚██╔╝    ║
    ║  ███████║   ██║   ███████╗██║     ██║  ██║███████╗   ██║     ║
    ║  ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝     ║
    ║                                                               ║
    ║                   🤖 THEME MANAGER 🎨                         ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Utility functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Safety checks
check_dependencies() {
    local deps=("hyprctl" "notify-send")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Required dependency '$dep' not found!"
            exit 1
        fi
    done
}

# Backup current config
create_backup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    mkdir -p "$BACKUP_DIR"

    if [[ -f "$USER_CONFIG" ]]; then
        cp "$USER_CONFIG" "$BACKUP_DIR/user-config_$timestamp.conf.bak"
        log_info "Backup created: user-config_$timestamp.conf.bak"
    fi
}

# Theme generators
generate_neon_intense() {
    cat > "$USER_CONFIG" << 'EOF'
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                StepheyBot NEON INTENSE Theme                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Maximum neon glow bezier curves
bezier = neonBlast, 0.1, 1.5, 0.1, 1.5
bezier = cyberShock, 0.68, -0.8, 0.265, 2.0
bezier = synthMax, 0.23, 1.5, 0.32, 1.5

# Intense animations
animation = windowsIn, 1, 5, cyberShock, popin 75%
animation = windowsOut, 1, 4, synthMax, slide
animation = fadeIn, 1, 8, neonBlast
animation = fadeOut, 1, 6, synthMax
animation = borderangle, 1, 20, neonBlast, loop
animation = workspaces, 1, 6, cyberShock, slidefade 25%

# Maximum glow decorations
decoration {
    shadow {
        range = 40
        render_power = 4
    }
    blur {
        passes = 4
        size = 6
        vibrancy = 0.5
        vibrancy_darkness = 0.2
        noise = 0.02
    }
}

# Intense window rules
windowrulev2 = bordercolor $neon_pink $neon_blue, focus:1
windowrulev2 = bordercolor $neon_purple_glow $neon_green_glow, focus:0
# Enhanced floating windows get shadow from decoration settings

layerrule = blur, ^(.*)$
layerrule = ignorealpha 0.1, ^(.*)$
EOF
}

generate_neon_balanced() {
    cat > "$USER_CONFIG" << 'EOF'
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃               StepheyBot NEON BALANCED Theme                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Balanced neon curves
bezier = neonFlow, 0.25, 0.46, 0.45, 0.94
bezier = cyberSmooth, 0.68, -0.3, 0.265, 1.2
bezier = synthWave, 0.23, 1, 0.32, 1

# Smooth animations
animation = windowsIn, 1, 4, cyberSmooth, popin 85%
animation = windowsOut, 1, 3, synthWave, slide
animation = fadeIn, 1, 6, neonFlow
animation = fadeOut, 1, 4, synthWave
animation = borderangle, 1, 30, neonFlow, once
animation = workspaces, 1, 5, cyberSmooth, slidefade 15%

# Balanced decorations
decoration {
    shadow {
        range = 24
        render_power = 3
    }
    blur {
        passes = 3
        size = 4
        vibrancy = 0.3
        vibrancy_darkness = 0.1
        noise = 0.0117
    }
}

# Balanced window rules
windowrulev2 = bordercolor $neon_pink_glow $neon_blue_glow, focus:1
windowrulev2 = bordercolor $neon_purple_dim $neon_blue_dim, focus:0

layerrule = blur, ^(waybar|rofi|wofi)$
layerrule = ignorealpha 0.3, ^(waybar)$
EOF
}

generate_performance() {
    cat > "$USER_CONFIG" << 'EOF'
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃               StepheyBot PERFORMANCE Theme                   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Minimal performance curves
bezier = fast, 0.4, 0, 0.6, 1
bezier = instant, 1, 1, 1, 1

# Fast animations
animation = windowsIn, 1, 2, fast
animation = windowsOut, 1, 2, fast
animation = fade, 1, 3, fast
animation = workspaces, 1, 3, fast

# Performance decorations
decoration {
    shadow {
        enabled = false
    }
    blur {
        enabled = false
    }
}

# Gaming optimizations
windowrulev2 = noblur, class:^(.*)$
windowrulev2 = noshadow, class:^(.*)$
windowrulev2 = bordercolor $neon_blue_dim, focus:1

misc {
    vfr = true
    no_direct_scanout = false
}
EOF
}

generate_minimal() {
    cat > "$USER_CONFIG" << 'EOF'
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                StepheyBot MINIMAL Theme                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Disable most animations
animation = windows, 0
animation = fade, 0
animation = workspaces, 1, 2, default
animation = border, 0

# Minimal decorations
decoration {
    rounding = 0
    shadow {
        enabled = false
    }
    blur {
        enabled = false
    }
}

# Clean borders only
windowrulev2 = bordercolor $cachylblue, focus:1
windowrulev2 = bordercolor $cachygray, focus:0
EOF
}

generate_cyberpunk() {
    cat > "$USER_CONFIG" << 'EOF'
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃               StepheyBot CYBERPUNK Theme                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Cyberpunk glitch curves
bezier = glitch, 0.1, -0.6, 0.2, 1.5
bezier = neonPulse, 0.7, -0.4, 0.2, 1.6
bezier = hackMatrix, 0.4, -0.4, 0.2, 1.4

# Cyberpunk animations
animation = windowsIn, 1, 4, glitch, popin 70%
animation = windowsOut, 1, 3, hackMatrix, slide right
animation = fadeIn, 1, 8, neonPulse
animation = fadeOut, 1, 5, hackMatrix
animation = borderangle, 1, 25, neonPulse, loop
animation = workspaces, 1, 6, glitch, slidefade 30%

# Maximum cyberpunk glow
decoration {
    shadow {
        range = 35
        render_power = 4
        sharp = true
    }
    blur {
        passes = 4
        size = 5
        vibrancy = 0.8
        vibrancy_darkness = 0.3
        noise = 0.05
    }
}

# Cyberpunk window rules
windowrulev2 = bordercolor $neon_pink $neon_green, focus:1
windowrulev2 = bordercolor $neon_purple_glow $neon_pink_glow, focus:0
windowrulev2 = animation glitch, class:^(terminal|kitty|wezterm)$
windowrulev2 = animation hackMatrix, class:^(code|nvim)$

layerrule = blur, ^(.*)$
layerrule = ignorealpha 0.05, ^(.*)$
EOF
}

# Apply theme function
apply_theme() {
    local theme="$1"

    create_backup

    case "$theme" in
        "$NEON_INTENSE")
            log_info "Applying NEON INTENSE theme..."
            generate_neon_intense
            ;;
        "$NEON_BALANCED")
            log_info "Applying NEON BALANCED theme..."
            generate_neon_balanced
            ;;
        "$PERFORMANCE")
            log_info "Applying PERFORMANCE theme..."
            generate_performance
            ;;
        "$MINIMAL")
            log_info "Applying MINIMAL theme..."
            generate_minimal
            ;;
        "$CYBERPUNK")
            log_info "Applying CYBERPUNK theme..."
            generate_cyberpunk
            ;;
        *)
            log_error "Unknown theme: $theme"
            exit 1
            ;;
    esac

    # Reload Hyprland config
    if hyprctl reload &> /dev/null; then
        log_success "Theme '$theme' applied successfully!"
        notify-send "StepheyBot" "Theme switched to: $theme" -i preferences-desktop-theme
    else
        log_error "Failed to reload Hyprland config"
        exit 1
    fi
}

# Get current theme info
get_current_theme() {
    if [[ -f "$USER_CONFIG" ]]; then
        local theme_line=$(grep -o "StepheyBot .* Theme" "$USER_CONFIG" 2>/dev/null | head -1)
        if [[ -n "$theme_line" ]]; then
            echo "$theme_line" | sed 's/StepheyBot \(.*\) Theme/\1/'
        else
            echo "Custom"
        fi
    else
        echo "None"
    fi
}

# Interactive theme selector
interactive_mode() {
    local current_theme=$(get_current_theme)

    echo -e "${CYAN}Current theme: ${YELLOW}$current_theme${NC}"
    echo ""
    echo "Available themes:"
    echo "  1) ${PURPLE}NEON INTENSE${NC} - Maximum glow and effects"
    echo "  2) ${BLUE}NEON BALANCED${NC} - Perfect balance of style and performance"
    echo "  3) ${GREEN}PERFORMANCE${NC} - Minimal effects for maximum FPS"
    echo "  4) ${YELLOW}MINIMAL${NC} - Clean and simple"
    echo "  5) ${RED}CYBERPUNK${NC} - Glitch effects and matrix vibes"
    echo "  6) Show current config"
    echo "  7) Restore backup"
    echo "  q) Quit"
    echo ""

    while true; do
        read -p "Select theme [1-7,q]: " choice
        case $choice in
            1) apply_theme "$NEON_INTENSE"; break ;;
            2) apply_theme "$NEON_BALANCED"; break ;;
            3) apply_theme "$PERFORMANCE"; break ;;
            4) apply_theme "$MINIMAL"; break ;;
            5) apply_theme "$CYBERPUNK"; break ;;
            6) show_current_config; ;;
            7) restore_backup; break ;;
            q|Q) log_info "Goodbye, Stephey! 🤖"; exit 0 ;;
            *) log_warning "Invalid choice. Please select 1-7 or q" ;;
        esac
    done
}

show_current_config() {
    if [[ -f "$USER_CONFIG" ]]; then
        echo -e "\n${CYAN}Current user config:${NC}"
        cat "$USER_CONFIG"
    else
        log_warning "No user config found"
    fi
}

restore_backup() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "No backup directory found"
        return 1
    fi

    local backups=($(ls -t "$BACKUP_DIR"/*.bak 2>/dev/null || true))
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_error "No backups found"
        return 1
    fi

    echo "Available backups:"
    for i in "${!backups[@]}"; do
        local backup_name=$(basename "${backups[$i]}")
        echo "  $((i+1))) $backup_name"
    done

    read -p "Select backup to restore [1-${#backups[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((choice-1))]}"
        cp "$selected_backup" "$USER_CONFIG"
        hyprctl reload
        log_success "Backup restored: $(basename "$selected_backup")"
    else
        log_error "Invalid selection"
    fi
}

# Help message
show_help() {
    cat << EOF
StepheyBot Theme Manager - Safe Hyprland Customization

Usage: $(basename "$0") [OPTION] [THEME]

OPTIONS:
    -i, --interactive    Interactive theme selection mode
    -l, --list          List available themes
    -s, --status        Show current theme status
    -r, --restore       Restore from backup
    -h, --help          Show this help message

THEMES:
    neon-intense        Maximum neon glow and effects
    neon-balanced       Balanced style and performance
    performance         Minimal effects for gaming
    minimal             Clean and simple
    cyberpunk           Glitch effects and matrix vibes

EXAMPLES:
    $(basename "$0") -i                    # Interactive mode
    $(basename "$0") neon-balanced         # Apply balanced theme
    $(basename "$0") -s                    # Show current status

StepheyBot v1.0 - Making your setup more seamless! 🤖✨
EOF
}

# Main function
main() {
    # Ensure directories exist
    mkdir -p "$STEPHEYBOT_DIR" "$BACKUP_DIR"

    # Check if running in Hyprland
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        log_warning "Not running in Hyprland session"
    fi

    check_dependencies

    case "${1:-}" in
        -i|--interactive)
            print_logo
            interactive_mode
            ;;
        -l|--list)
            echo "Available themes:"
            echo "  - neon-intense"
            echo "  - neon-balanced"
            echo "  - performance"
            echo "  - minimal"
            echo "  - cyberpunk"
            ;;
        -s|--status)
            echo "Current theme: $(get_current_theme)"
            ;;
        -r|--restore)
            restore_backup
            ;;
        -h|--help)
            show_help
            ;;
        "")
            print_logo
            interactive_mode
            ;;
        *)
            if [[ "$1" =~ ^(neon-intense|neon-balanced|performance|minimal|cyberpunk)$ ]]; then
                apply_theme "$1"
            else
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"
