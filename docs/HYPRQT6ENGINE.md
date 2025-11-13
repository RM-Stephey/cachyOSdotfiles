# 🌌 HyprQt6Engine Setup Guide
## StepheyBot NEON Cyberpunk Theme Integration

### 📋 Overview

HyprQt6Engine is a Qt6 theme provider specifically designed for Hyprland that automatically syncs Qt6 application themes with your Hyprland configuration. This creates seamless visual integration between your window manager and Qt6 applications.

### ✨ Features

- **Automatic Theme Sync**: Qt6 apps automatically adopt Hyprland's color scheme
- **Neon Integration**: Perfect for cyberpunk/neon aesthetics
- **Wayland Optimized**: Built specifically for Wayland compositors
- **RTX 4090 Compatible**: Optimized for high-performance GPU setups

### 🔧 Installation

```bash
# Install hyprqt6engine-git from AUR
yay -S hyprqt6engine-git
```

**Dependencies Installed:**
- `hyprutils-git` - Hyprland utilities (replaces stable version)
- `hyprlang-git` - Hyprland language parser (replaces stable version) 
- `hyprqt6engine-git` - Qt6 theme engine for Hyprland

### 🎨 Configuration

#### Environment Variables Set

Located in: `.config/hypr/config/environment.conf`

```bash
# Qt6 Platform Integration
env = QT_QPA_PLATFORMTHEME,hyprqt6engine
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = QT_LOGGING_RULES,qt.qpa.wayland.debug=false

# Hyprland Integration
env = HYPRQT6ENGINE_THEME,neon
env = HYPRQT6ENGINE_FOLLOW_HYPRLAND,1
```

#### Autostart Integration

Added to: `.config/hypr/config/autostart.conf`

```bash
# Initialize HyprQt6Engine for Qt6 application theming
exec-once = ~/.config/hypr/scripts/init-hyprqt6engine.sh
```

### 🚀 Installation Files

The installation creates these plugin files:
- `/usr/lib/qt6/plugins/platformthemes/libhyprqt6engine.so` - Platform theme plugin
- `/usr/lib/qt6/plugins/styles/libhypr-style.so` - Style plugin
- `/usr/lib/libhyprqt6engine-common.so` - Common library

### 📝 Initialization Script

**Location:** `.config/hypr/scripts/init-hyprqt6engine.sh`

This script:
- Verifies hyprqt6engine installation
- Sets up Qt6 environment variables
- Applies RTX 4090 optimizations
- Syncs with Hyprland color scheme
- Enables neon/glow effects

### 🎯 How It Works

1. **Theme Detection**: hyprqt6engine reads Hyprland's current color scheme
2. **Automatic Sync**: Qt6 applications automatically receive the theme updates
3. **Style Application**: The `hypr-style` is applied to Qt6 widgets
4. **Real-time Updates**: Theme changes in Hyprland propagate to Qt6 apps

### 🧪 Testing

To verify hyprqt6engine is working:

```bash
# Check if plugins are installed
find /usr/lib/qt6/plugins -name "*hypr*"

# Test with qt6ct (if available)
qt6ct

# Check environment variables
echo $QT_QPA_PLATFORMTHEME
```

### 🎨 Neon Theme Integration

hyprqt6engine automatically inherits your Hyprland neon colors:
- **Active borders**: `$neon_pink $neon_blue 45deg`
- **Inactive borders**: `$neon_purple_glow $neon_blue_dim 45deg`
- **Window decorations**: Match Hyprland rounding and shadows
- **Widget styling**: Neon accents on buttons, sliders, etc.

### 🔍 Troubleshooting

#### Qt6 Apps Not Using Hypr Theme

1. **Check environment variables:**
   ```bash
   echo $QT_QPA_PLATFORMTHEME  # Should show: hyprqt6engine
   echo $QT_STYLE_OVERRIDE     # (optional) managed by qt6ct/Qt settings
   ```

2. **Verify plugin installation:**
   ```bash
   ls -la /usr/lib/qt6/plugins/platformthemes/libhyprqt6engine.so
   ls -la /usr/lib/qt6/plugins/styles/libhypr-style.so
   ```

3. **Restart Qt6 applications** after configuration changes

4. **Check logs:**
   ```bash
   # Enable Qt debug logging temporarily
   export QT_LOGGING_RULES="qt.qpa.debug=true"
   your-qt6-app
   ```

#### Performance Issues

If experiencing performance issues with Qt6 apps:

1. **Disable debug logging:**
   ```bash
   export QT_LOGGING_RULES="qt.qpa.wayland.debug=false"
   ```

2. **Check GPU acceleration:**
   ```bash
   echo $QT_OPENGL           # Should be: desktop
   echo $QT_RHI_BACKEND      # Should be: opengl
   ```

### 🔄 Updates

To update hyprqt6engine:

```bash
yay -Syu hyprqt6engine-git
```

**Note:** Updates may require restarting Hyprland session for full effect.

### 🎯 Compatible Applications

hyprqt6engine works with:
- Any Qt6 application
- KDE applications (when using Qt6)
- Custom Qt6 applications
- Qt6-based system tools

### 📈 Performance Benefits

- **Reduced Theme Switching Time**: Instant theme application
- **Memory Efficiency**: Shared theme resources
- **GPU Acceleration**: Optimized for RTX 4090
- **Wayland Native**: No XWayland overhead for theming

### 🌈 Color Scheme Integration

hyprqt6engine automatically maps these Hyprland colors to Qt6:

| Hyprland Variable | Qt6 Element | Usage |
|---|---|---|
| `$neon_pink` | Active highlights | Selected items, focus rings |
| `$neon_blue` | Secondary accents | Progress bars, links |
| `$neon_purple` | Inactive elements | Disabled widgets |
| `$neon_green` | Success states | Checkmarks, confirmations |
| `$bg_dark` | Window backgrounds | Dialog boxes, menus |
| `$fg_bright` | Text color | Labels, buttons |

### 💡 Tips

- **Restart applications** after theme changes for best results
- **Use Wayland-native Qt6 apps** when possible for optimal integration
- **Keep hyprqt6engine-git updated** for latest theme features
- **Monitor performance** with RTX 4090 optimizations enabled

---

*This documentation is part of the StepheyBot NEON Cyberpunk Hyprland configuration.*