#!/bin/bash

# Smart Workspace Switching Script for Hyprland
# Handles workspace navigation with auto-creation at the end
# Part of StepheyBot NEON theme configuration
#
# Features:
# - Intuitive workspace navigation (swipe right = next workspace)
# - Auto-creates new workspace when swiping right at the last workspace
# - Integrates with Hyprland gestures and keybinds
# - Neon-themed notifications
#
# Usage:
#   ./smart-workspace.sh {next|right|prev|left}
#   ./smart-workspace.sh right   # Go to next workspace, create if at end
#   ./smart-workspace.sh left    # Go to previous workspace
#
# Dependencies: hyprctl, jq

# Check dependencies
if ! command -v hyprctl &> /dev/null; then
    echo "Error: hyprctl not found. Make sure Hyprland is running."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq not found. Please install jq package."
    exit 1
fi

# Get current workspace with error handling
current_workspace=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null)
if [ -z "$current_workspace" ] || [ "$current_workspace" = "null" ]; then
    echo "Error: Could not get current workspace"
    exit 1
fi

# Get all workspaces and find the highest number
workspaces=$(hyprctl workspaces -j 2>/dev/null | jq -r '.[].id' 2>/dev/null | sort -n)
if [ -z "$workspaces" ]; then
    echo "Error: Could not get workspace list"
    exit 1
fi
highest_workspace=$(echo "$workspaces" | tail -1)

# Function to switch workspace with direction
switch_workspace() {
    local direction=$1

    case $direction in
        "next"|"right")
            if [ "$current_workspace" -eq "$highest_workspace" ]; then
                # At the last workspace - create a new one
                new_workspace=$((highest_workspace + 1))
                echo "Creating new workspace: $new_workspace"
                hyprctl dispatch workspace $new_workspace


            else
                # Normal next workspace navigation
                hyprctl dispatch workspace +1
            fi
            ;;

        "prev"|"left")
            # Normal previous workspace navigation
            hyprctl dispatch workspace -1
            ;;

        *)
            echo "❌ Invalid direction: $direction"
            echo ""
            echo "🌌 StepheyBot NEON Workspace Switcher"
            echo "Usage: $0 {next|right|prev|left}"
            echo ""
            echo "Examples:"
            echo "  $0 right   # Next workspace (auto-creates if at end)"
            echo "  $0 left    # Previous workspace"
            echo "  $0 next    # Same as 'right'"
            echo "  $0 prev    # Same as 'left'"
            exit 1
            ;;
    esac
}

# Main execution
if [ $# -eq 0 ]; then
    echo "🌌 StepheyBot NEON Workspace Switcher"
    echo "Usage: $0 {next|right|prev|left}"
    echo ""
    echo "📊 Current Status:"
    echo "  • Current workspace: $current_workspace"
    echo "  • Highest workspace: $highest_workspace"
    echo "  • Available workspaces: $(echo "$workspaces" | tr '\n' ' ')"
    echo ""
    echo "✨ Features:"
    echo "  • Swipe right creates new workspace at end"
    echo "  • Intuitive navigation (right=next, left=prev)"

    exit 1
fi

switch_workspace $1
