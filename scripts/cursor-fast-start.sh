#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                 Cursor Fast Start Script                    ┃
# ┃         Optimized Cursor startup for Hyprland              ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Colors for neon-themed output
NEON_PINK='\033[95m'
NEON_BLUE='\033[96m'
NEON_GREEN='\033[92m'
NEON_PURPLE='\033[94m'
NC='\033[0m' # No Color

echo -e "${NEON_PINK}🚀 StepheyBot Cursor Optimizer${NC}"

# Configuration
CURSOR_CONFIG_DIR="$HOME/.config/Cursor"
MAX_LOAD_THRESHOLD=2.0
CACHE_SIZE_THRESHOLD_GB=2
CLEANUP_OLDER_THAN_DAYS=7

# Function to check system load
check_system_load() {
    local load=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')
    if (( $(echo "$load > $MAX_LOAD_THRESHOLD" | bc -l) )); then
        echo -e "${NEON_PURPLE}⏳ System load high ($load), waiting for optimal conditions...${NC}"
        sleep 3
        return 1
    fi
    return 0
}

# Function to clean excessive cache
cleanup_cursor_cache() {
    if [ ! -d "$CURSOR_CONFIG_DIR" ]; then
        return
    fi

    local cache_size=$(du -sh "$CURSOR_CONFIG_DIR" 2>/dev/null | cut -f1 | sed 's/G.*//' | sed 's/M.*/0/')

    if [ "${cache_size:-0}" -gt "$CACHE_SIZE_THRESHOLD_GB" ]; then
        echo -e "${NEON_BLUE}🧹 Cleaning Cursor cache (${cache_size}GB > ${CACHE_SIZE_THRESHOLD_GB}GB)...${NC}"

        # Stop any running Cursor instances
        pkill -f "cursor" 2>/dev/null
        sleep 2

        # Clean old cache data
        find "$CURSOR_CONFIG_DIR/CachedData" -type d -mtime +$CLEANUP_OLDER_THAN_DAYS -exec rm -rf {} + 2>/dev/null
        find "$CURSOR_CONFIG_DIR/Cache" -type f -mtime +$CLEANUP_OLDER_THAN_DAYS -delete 2>/dev/null
        find "$CURSOR_CONFIG_DIR/GPUCache" -type f -mtime +$CLEANUP_OLDER_THAN_DAYS -delete 2>/dev/null
        find "$CURSOR_CONFIG_DIR/logs" -type f -mtime +$CLEANUP_OLDER_THAN_DAYS -delete 2>/dev/null

        # Clean temporary files
        rm -rf "$CURSOR_CONFIG_DIR/CrashPad/completed" 2>/dev/null
        rm -rf "$CURSOR_CONFIG_DIR/Service Worker/CacheStorage" 2>/dev/null

        echo -e "${NEON_GREEN}✅ Cache cleanup completed${NC}"
    fi
}

# Function to optimize environment for Cursor
setup_cursor_environment() {
    # Wayland optimizations
    export ELECTRON_ENABLE_WAYLAND=1
    export ELECTRON_OZONE_PLATFORM_HINT=wayland
    export XDG_CURRENT_DESKTOP=Hyprland
    export XDG_SESSION_TYPE=wayland

    # Performance optimizations
    export ELECTRON_NO_SANDBOX=0  # Keep sandbox for security
    export ELECTRON_DISABLE_GPU_SANDBOX=1  # Disable GPU sandbox for performance
    export ELECTRON_USE_GL=angle
    export ELECTRON_ANGLE_BACKEND=swiftshader

    # Memory optimizations for 64GB system
    export NODE_OPTIONS="--max-old-space-size=8192"
    export ELECTRON_RENDERER_PROCESS_LIMIT=8

    # I/O optimizations
    export UV_THREADPOOL_SIZE=16
}

# Function to check if Waybar is consuming excessive CPU
check_waybar_performance() {
    local waybar_cpu=$(ps aux | grep -v grep | grep waybar | awk '{print $3}' | head -1)
    if [ -n "$waybar_cpu" ] && (( $(echo "$waybar_cpu > 50" | bc -l) )); then
        echo -e "${NEON_PURPLE}⚠️  Waybar high CPU usage detected (${waybar_cpu}%), considering restart...${NC}"
        # Optional: restart waybar if needed
        # killall waybar && sleep 1 && waybar > /dev/null 2>&1 &
    fi
}

# Function to wait for system readiness
wait_for_system_ready() {
    local attempts=0
    local max_attempts=5

    while [ $attempts -lt $max_attempts ]; do
        if check_system_load; then
            break
        fi
        attempts=$((attempts + 1))
        sleep 2
    done

    # Ensure essential services are running
    if ! pgrep -x "gnome-keyring-daemon" > /dev/null; then
        echo -e "${NEON_BLUE}🔑 Starting GNOME Keyring...${NC}"
        gnome-keyring-daemon --start --components=pkcs11,secrets,ssh > /dev/null 2>&1 &
    fi
}

# Function to launch Cursor with optimizations
launch_cursor() {
    local cursor_args=(
        "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,UseOzonePlatform,WebRTCPipeWireCapturer"
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
        "--disable-features=UseChromeOSDirectVideoDecoder"
        "--disable-gpu-sandbox"
        "--use-gl=angle"
        "--use-angle=swiftshader-webgl"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--disable-dev-shm-usage"
        "--memory-pressure-off"
        "--max_old_space_size=8192"
    )

    echo -e "${NEON_GREEN}🎯 Launching Cursor with optimizations...${NC}"

    # Launch in background to avoid blocking
    nohup cursor "${cursor_args[@]}" "$@" > /tmp/cursor-startup.log 2>&1 &
    local cursor_pid=$!

    echo -e "${NEON_BLUE}📝 Cursor launched (PID: $cursor_pid)${NC}"

    # Optional: Monitor startup for a few seconds
    sleep 3
    if kill -0 $cursor_pid 2>/dev/null; then
        echo -e "${NEON_GREEN}✅ Cursor startup successful!${NC}"

        # Clean up old log files to prevent accumulation
        find /tmp -name "cursor-startup*.log" -mtime +1 -delete 2>/dev/null
    else
        echo -e "${NEON_PINK}❌ Cursor startup may have failed, check /tmp/cursor-startup.log${NC}"
        return 1
    fi
}

# Function to create desktop integration
create_desktop_shortcut() {
    local desktop_file="$HOME/.local/share/applications/cursor-optimized.desktop"

    if [ ! -f "$desktop_file" ]; then
        mkdir -p "$(dirname "$desktop_file")"
        cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Cursor (Optimized)
GenericName=Code Editor
Comment=Cursor AI Code Editor - Optimized for Hyprland
Exec=$HOME/.config/hypr/scripts/cursor-fast-start.sh %F
Icon=cursor
Type=Application
StartupNotify=true
Categories=Development;TextEditor;
MimeType=text/plain;inode/directory;
Keywords=vscode;development;ide;
StartupWMClass=cursor
EOF
        echo -e "${NEON_BLUE}📱 Created optimized desktop shortcut${NC}"
    fi
}

# Main execution
main() {
    echo -e "${NEON_PINK}🔧 Initializing Cursor optimization...${NC}"

    # Performance checks and cleanup
    check_waybar_performance
    cleanup_cursor_cache

    # System readiness
    wait_for_system_ready

    # Environment setup
    setup_cursor_environment

    # Create desktop integration if needed
    create_desktop_shortcut

    # Launch Cursor
    if launch_cursor "$@"; then
        echo -e "${NEON_GREEN}🎉 Cursor optimization complete!${NC}"
    else
        echo -e "${NEON_PINK}❌ Cursor launch failed${NC}"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --clean-only)
        cleanup_cursor_cache
        exit 0
        ;;
    --check-only)
        check_system_load
        check_waybar_performance
        exit 0
        ;;
    --help)
        echo "Cursor Fast Start Script"
        echo "Usage: $0 [options] [cursor-arguments]"
        echo "Options:"
        echo "  --clean-only    Only clean cache, don't start Cursor"
        echo "  --check-only    Only check system status"
        echo "  --help          Show this help"
        exit 0
        ;;
esac

# Run main function with all arguments
main "$@"
