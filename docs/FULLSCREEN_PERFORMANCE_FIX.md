# Fullscreen Performance Fix

## Problem
Performance seriously degrades when making a window fullscreen.

## Root Causes Identified

### 1. **Blur Not Disabled for Fullscreen** ❌
- General fullscreen windows did NOT have `noblur` rule
- Only specific apps (steam, mpv, vlc, video sites) had blur disabled
- Blur is one of the most expensive compositing operations

### 2. **Expensive User Config Overrides** ⚠️
- `user-config.conf` overrides `decorations.conf` with expensive settings:
  - `passes = 2` (doubles blur cost)
  - `vibrancy = 0.85` (very high, expensive)
  - `contrast = 2.0` (very high, expensive)
  - `shadow range = 40` and `render_power = 4` (very expensive)

### 3. **Rounding Still Applied** ⚠️
- `rounding 1` was still applied to fullscreen windows
- Rounding requires compositing, preventing direct scanout

### 4. **Layer Blur Applied to Everything** ⚠️
- `layerrule = blur, ^(.*)$` applies blur to ALL layers
- This can affect fullscreen performance

## Fixes Applied

### ✅ Window Rules (`config/windowrules.conf`)

1. **Added `noblur` to all fullscreen windows**:
   ```hyprlang
   windowrulev2 = noblur, fullscreen:0          # True fullscreen
   windowrulev2 = noblur, fullscreen:1          # Maximized
   ```

2. **Removed rounding from fullscreen**:
   ```hyprlang
   windowrulev2 = rounding 0, fullscreen:0     # Remove rounding for direct scanout
   windowrulev2 = rounding 0, fullscreen:1     # Remove rounding for better performance
   ```

3. **Optimized Cursor fullscreen rules**:
   - Disabled blur, shadows, and rounding
   - Set opacity to 1.0 (full opacity) for better performance
   - Kept `immediate` mode for direct scanout

### ✅ User Config (`config/user-config.conf`)

1. **Added performance warnings** to expensive settings
2. **Noted layer blur impact** on fullscreen performance

## Performance Impact

### Before:
- Blur enabled on fullscreen windows (expensive)
- Rounding applied (prevents direct scanout)
- 2 blur passes + high vibrancy/contrast (very expensive)
- Shadows enabled (moderate cost)

### After:
- Blur disabled on all fullscreen windows ✅
- Rounding removed (enables direct scanout) ✅
- Shadows disabled for true fullscreen ✅
- Animations disabled ✅
- Immediate mode enabled ✅

## Expected Results

- **Direct scanout enabled**: Windows can bypass compositor for maximum performance
- **No blur overhead**: Eliminates expensive blur calculations
- **No rounding overhead**: Removes compositing requirement
- **Better GPU utilization**: Direct rendering path

## Additional Optimization Tips

If performance is still not optimal, consider:

1. **Reduce blur passes in user-config.conf**:
   ```hyprlang
   passes = 1  # Instead of 2
   ```

2. **Reduce vibrancy**:
   ```hyprlang
   vibrancy = 0.2  # Instead of 0.85
   ```

3. **Reduce contrast**:
   ```hyprlang
   contrast = 1.0  # Instead of 2.0
   ```

4. **Make layer blur selective**:
   ```hyprlang
   # Instead of: layerrule = blur, ^(.*)$
   layerrule = blur, waybar
   layerrule = blur, swaync
   # Only blur specific layers, not everything
   ```

## Testing

After applying these fixes:

1. Test fullscreen performance with various applications
2. Check if `direct_scanout` is working: `hyprctl monitors`
3. Monitor GPU usage during fullscreen
4. Verify no stuttering or frame drops

## Notes

- `direct_scanout = true` in `variables.conf` enables direct scanout when possible
- `immediate` window rule enables immediate mode for direct scanout
- These optimizations work best with `direct_scanout = true` in render settings

---

**Fixed**: $(date)
**Issue**: Fullscreen performance degradation
**Solution**: Disable blur, shadows, rounding, and animations for fullscreen windows
