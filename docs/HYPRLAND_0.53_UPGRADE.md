# Hyprland 0.53 Upgrade Checklist

## ✅ Completed Updates

### 1. Fullscreen Behavior (BREAKING CHANGE)
- **Updated**: `config/variables.conf`
  - Replaced `misc:new_window_takes_over_fullscreen = 2` with `misc:new_window_takes_over_fs = 2`
  - Removed `master:inherit_fullscreen = true` (now handled by `misc:new_window_takes_over_fs`)
  - Added comments explaining the change

### 2. Window Rule Syntax (BREAKING CHANGE)
- **Updated**: `config/windowrules.conf`
  - Converted all `windowrule` (v1) entries to `windowrulev2` format
  - Added warning header about 0.53 syntax overhaul
  - ⚠️ **IMPORTANT**: Window rule syntax has been completely overhauled in 0.53
  - All windowrules have been converted, but **please verify they work correctly** after upgrading
  - See: https://wiki.hyprland.org/Configuring/Window-Rules/

- **Updated**: `config/user-config.conf`
  - Converted `windowrule` to `windowrulev2` format

### 3. Launch Method (RECOMMENDED)
- **Created**: `~/.local/share/wayland-sessions/hyprland.desktop`
  - User override desktop file that uses `start-hyprland` instead of `Hyprland`
  - This provides crash recovery and safe mode features
  - **Note**: Ensure `hyprland-guiutils` is installed for safe mode functionality

### 4. Hyprpaper (IF USED)
- **Status**: No hyprpaper configs found in your setup
- **If you use hyprpaper**: Update to 0.8.0 and check the wiki for new syntax
  - Hyprpaper 0.8.0 breaks configs and uses a new IPC protocol
  - See: https://wiki.hyprland.org/Configuring/Hyprpaper/

## ⚠️ Manual Verification Required

### Window Rules
The window rule syntax has been completely overhauled. While all rules have been converted from `windowrule` to `windowrulev2`, the new 0.53 syntax may use a different format for conditions. Please:

1. Test all window rules after upgrading
2. Check the wiki for the exact new syntax: https://wiki.hyprland.org/Configuring/Window-Rules/
3. Update any rules that don't work as expected

### Scripts
All scripts have been verified:
- ✅ No scripts launch `Hyprland` directly
- ✅ UWSM wrapper uses proper desktop file reference
- ✅ Logout scripts check for Hyprland process but don't launch it

## 📋 Pre-Upgrade Checklist

Before upgrading to Hyprland 0.53:

- [ ] Backup your current config: `cp -r ~/.config/hypr ~/.config/hypr.backup`
- [ ] Ensure `hyprland-guiutils` is installed (required for safe mode)
- [ ] Review all window rules after upgrade
- [ ] If using hyprpaper, update to 0.8.0 and migrate config

## 📋 Post-Upgrade Checklist

After upgrading to Hyprland 0.53:

- [ ] Test window rules - verify all applications match correctly
- [ ] Test fullscreen behavior - verify `misc:new_window_takes_over_fs` works as expected
- [ ] Test launch method - verify `start-hyprland` works correctly
- [ ] Check for any config errors in logs: `journalctl --user -u hyprland -f`
- [ ] Verify all applications start correctly
- [ ] Test window decorations, borders, and animations

## 🔗 Useful Links

- [Hyprland 0.53 Release Notes](https://hypr.land/news/update53/)
- [Window Rules Documentation](https://wiki.hyprland.org/Configuring/Window-Rules/)
- [Hyprpaper 0.8.0 Documentation](https://wiki.hyprland.org/Configuring/Hyprpaper/)

## 📝 Notes

- The new `start-hyprland` wrapper provides crash recovery and safe mode
- Safe mode requires `hyprland-guiutils` to be installed
- Window rule syntax is completely different - all rules need verification
- `misc:new_window_takes_over_fs` replaces both old fullscreen options

---

**Generated**: $(date)
**Hyprland Version**: 0.53 (upgrade from 0.52.2)
