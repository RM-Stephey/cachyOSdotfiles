# Layerrule 0.53 Syntax Fix Needed

## Issue
Hyprland 0.53 has changed the layerrule syntax, causing errors with:
- `layerrule = blur, <layer>`
- `layerrule = ignorezero, <layer>`
- `layerrule = ignorealpha <value>, <layer>`
- `layerrule = noanim, <layer>`

## Current Status
These layerrules have been temporarily commented out to allow the config to load.

## Next Steps
1. Check Hyprland 0.53 documentation for correct layerrule syntax
2. Use HyprLS LSP (already installed at `/usr/bin/hyprls`) to validate syntax
3. Update layerrules once correct syntax is confirmed

## HyprLS Usage
HyprLS is already installed. To use it in your editor:

**For Cursor/VSCode:**
- Install the Hyprland extension pack from the marketplace
- It should automatically use HyprLS for validation

**For Neovim:**
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

## Resources
- HyprLS GitHub: https://github.com/hyprland-community/hyprls
- Hyprland 0.53 Release Notes: https://hypr.land/news/update53/
- Hyprland Wiki: https://wiki.hyprland.org/Configuring/Window-Rules/
