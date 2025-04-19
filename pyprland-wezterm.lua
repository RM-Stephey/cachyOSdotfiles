-- Config for wezterm in scratchpad mode
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- For scratchpad, set a specific window style
config.window_decorations = "RESIZE"
config.initial_cols = 120
config.initial_rows = 30
config.allow_win_class_override = true
config.window_padding = {
    left = 8,
    right = 8,
    top = 8,
    bottom = 8,
}

-- Optional: Set opacity for scratchpad
config.window_background_opacity = 0.95

return config
