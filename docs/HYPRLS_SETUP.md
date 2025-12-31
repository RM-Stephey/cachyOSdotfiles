# HyprLS Setup Guide

## What is HyprLS?

HyprLS is a Language Server Protocol (LSP) server for Hyprland configuration files. It provides:
- Auto-completion
- Hover information
- Go-to definition
- Diagnostics (error checking)
- Formatting
- Semantic highlighting

## Installation

HyprLS is already installed on your system at `/usr/bin/hyprls`.

## Editor Setup

### For Cursor/VS Code:
1. Install the Hyprland extension pack from the marketplace
2. The extension should automatically detect and use HyprLS

### For Neovim:
Add to your `init.lua`:
```lua
vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter'}, {
    pattern = {"*.hl", "hypr*.conf"},
    callback = function(event)
        vim.lsp.start {
            name = "hyprlang",
            cmd = {"hyprls"},
            root_dir = vim.fn.getcwd(),
        }
    end
})
```

## Usage

Once configured, HyprLS will:
- Show errors in real-time as you type
- Provide auto-completion for valid options
- Show hover information for configuration options
- Validate your config syntax

## Current Status

Your config has some errors that need fixing:
- Layerrule syntax may have changed in 0.53
- Some options like `ignorezero`, `ignorealpha`, `noanim` may not be valid for layerrules in 0.53
- `misc:new_window_takes_over_fs` option needs verification

Use `hyprctl configerrors` to see all current errors.
