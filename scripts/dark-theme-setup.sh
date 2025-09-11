#!/bin/bash
# Comprehensive Dark Theme Setup Script for Hyprland/CachyOS
# Sets dark theme as default across all toolkits and applications

echo "Setting up comprehensive dark theme..."

# Set GTK dark theme preferences
gsettings set org.gnome.desktop.interface gtk-theme 'oomox-cyberpunk-neon'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Vimix-amethyst-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'capitaine-cursors'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'

# GTK4 doesn't use this key, it uses the GTK3 settings

# Export environment variables for dark theme
export GTK_THEME="oomox-cyberpunk-neon"
export GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc"
export QT_STYLE_OVERRIDE="kvantum-dark"
export QT_QPA_PLATFORMTHEME="qt5ct"

# Create GTK-2.0 dark theme config
mkdir -p ~/.config/gtk-2.0
cat > ~/.config/gtk-2.0/gtkrc << EOF
# Dark theme for GTK2
gtk-theme-name="oomox-cyberpunk-neon"
gtk-icon-theme-name="Vimix-amethyst-dark"
gtk-font-name="Cantarell 11"
gtk-cursor-theme-name="capitaine-cursors"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintslight"
gtk-xft-rgba="rgb"
gtk-application-prefer-dark-theme=1
EOF

# Ensure GTK3 settings are correct
cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=oomox-cyberpunk-neon
gtk-icon-theme-name=Vimix-amethyst-dark
gtk-font-name=Cantarell 11
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF

# Ensure GTK4 settings are correct
cat > ~/.config/gtk-4.0/settings.ini << EOF
[Settings]
gtk-theme-name=oomox-cyberpunk-neon
gtk-icon-theme-name=Vimix-amethyst-dark
gtk-font-name=Cantarell 11
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

# Set Qt5 dark theme via qt5ct
if [ -f ~/.config/qt5ct/qt5ct.conf ]; then
    sed -i 's/^style=.*/style=kvantum-dark/' ~/.config/qt5ct/qt5ct.conf
fi

# Set Qt6 dark theme via qt6ct
if [ -f ~/.config/qt6ct/qt6ct.conf ]; then
    sed -i 's/^style=.*/style=kvantum-dark/' ~/.config/qt6ct/qt6ct.conf
fi

# Set Kvantum to dark theme
if [ -f ~/.config/Kvantum/kvantum.kvconfig ]; then
    sed -i 's/^theme=.*/theme=Xenoviolet/' ~/.config/Kvantum/kvantum.kvconfig
fi

# Set dark theme for Electron apps
if [ -d ~/.config/electron-flags.conf ]; then
    rm -rf ~/.config/electron-flags.conf
fi
echo "--enable-features=WebUIDarkMode --force-dark-mode" > ~/.config/electron-flags.conf

# Set dark theme for Chromium-based browsers
if [ -d ~/.config/chromium-flags.conf ]; then
    rm -rf ~/.config/chromium-flags.conf
fi
echo "--enable-features=WebUIDarkMode --force-dark-mode" > ~/.config/chromium-flags.conf

# Set dark theme for Firefox
if [ -d ~/.mozilla/firefox ]; then
    for profile in ~/.mozilla/firefox/*.default*; do
        if [ -d "$profile" ]; then
            user_js="$profile/user.js"
            touch "$user_js"
            grep -q "ui.systemUsesDarkTheme" "$user_js" || echo 'user_pref("ui.systemUsesDarkTheme", 1);' >> "$user_js"
            grep -q "browser.theme.dark.toolbar" "$user_js" || echo 'user_pref("browser.theme.dark.toolbar", true);' >> "$user_js"
        fi
    done
fi

# Set environment variable for future sessions
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/50-dark-theme.conf << EOF
# Dark theme environment variables
GTK_THEME=oomox-cyberpunk-neon
GTK2_RC_FILES=$HOME/.config/gtk-2.0/gtkrc
QT_STYLE_OVERRIDE=kvantum-dark
QT_QPA_PLATFORMTHEME=qt5ct
GTK_USE_DARK_THEME=1
ELECTRON_FORCE_DARK_MODE=1
EOF

# Update xsettingsd for X11 compatibility
if [ -f ~/.config/xsettingsd/xsettingsd.conf ]; then
    cat > ~/.config/xsettingsd/xsettingsd.conf << EOF
Net/ThemeName "oomox-cyberpunk-neon"
Net/IconThemeName "Vimix-amethyst-dark"
Gtk/CursorThemeName "capitaine-cursors"
Net/EnableEventSounds 1
EnableInputFeedbackSounds 0
Xft/Antialias 1
Xft/Hinting 1
Xft/HintStyle "hintslight"
Xft/RGBA "rgb"
Gtk/ApplicationPreferDarkTheme 1
EOF
fi

# Restart xsettingsd if running
pkill -HUP xsettingsd 2>/dev/null || true

# Update dconf settings for GNOME/GTK apps
if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/desktop/interface/gtk-theme "'oomox-cyberpunk-neon'"
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    dconf write /org/gnome/desktop/interface/icon-theme "'Vimix-amethyst-dark'"
    dconf write /org/gnome/desktop/interface/cursor-theme "'capitaine-cursors'"
fi

# Set dark theme for flatpak apps
if command -v flatpak >/dev/null 2>&1; then
    flatpak override --user --env=GTK_THEME=oomox-cyberpunk-neon
    flatpak override --user --env=ICON_THEME=Vimix-amethyst-dark
    flatpak override --user --env=GTK_APPLICATION_PREFER_DARK_THEME=1
fi

# Notify systemd of environment changes
systemctl --user import-environment GTK_THEME QT_STYLE_OVERRIDE GTK_USE_DARK_THEME

echo "Dark theme setup complete!"
echo "Some applications may need to be restarted to apply the theme."
echo "For a full effect, consider logging out and back in."
