# Autostart Best Practices for Hyprland + UWSM

## The Three Ways to Autostart Apps

### 1. 🏆 Systemd User Services (BEST for supported apps)

**Use when:** App provides a systemd service file in `/usr/lib/systemd/user/`

**Example:** ulauncher

```bash
# Enable (starts on login)
systemctl --user enable ulauncher.service

# Manual control
systemctl --user start ulauncher.service
systemctl --user stop ulauncher.service
systemctl --user status ulauncher.service

# View logs
journalctl --user -u ulauncher -f
```

**Benefits:**
- ✅ Auto-restart on crash
- ✅ Proper lifecycle management
- ✅ Integrated logging
- ✅ Dependency management
- ✅ Session integration

---

### 2. 📁 XDG Autostart Desktop Files (AUTOMATIC systemd integration)

**Location:** `~/.config/autostart/*.desktop` or `/etc/xdg/autostart/*.desktop`

**How it works:**
- Desktop files are automatically converted to systemd units
- Runs as `app-*@autostart.service`
- Full systemd integration without manual setup

**Examples in your setup:**
- 1Password → `app-1password@autostart.service`
- Blueman → `app-blueman@autostart.service`
- CopyQ, Nextcloud, Nym-VPN, etc.

**Check status:**
```bash
systemctl --user list-units | grep "@autostart"
```

**Benefits:**
- ✅ No configuration needed
- ✅ Automatic systemd integration
- ✅ Standard cross-desktop compatibility

---

### 3. 🔧 exec-once with uwsm app (For apps without systemd service)

**Use when:** App doesn't have systemd service or needs custom arguments

**Syntax:**
```conf
exec-once = uwsm app -- <command> <args>
```

**Examples in your setup:**
```conf
exec-once = uwsm app -- beeper
exec-once = uwsm app -- pypr
exec-once = uwsm app -- bongocat --watch-config
exec-once = uwsm app -- qs -c waybar
exec-once = uwsm app -- xsettingsd -c ~/.config/xsettingsd/xsettingsd.conf
```

**When to use `uwsm app`:**
- Apps without systemd services
- Apps needing custom config paths
- Apps needing specific arguments
- GUI applications

**Benefits:**
- ✅ Environment variables inherited from uwsm
- ✅ Session-scoped processes
- ✅ Proper cleanup on logout

---

## Decision Tree

```
Does app have systemd service?
├─ YES → Check if needs custom args
│  ├─ NO custom args needed
│  │  └─ ✅ Use: systemctl --user enable <service>
│  └─ YES needs custom args
│     └─ ✅ Use: exec-once = uwsm app -- <command> <args>
│
└─ NO → Does app provide XDG autostart .desktop file?
   ├─ YES
   │  └─ ✅ Use: Place/keep in ~/.config/autostart/
   └─ NO
      └─ ✅ Use: exec-once = uwsm app -- <command>
```

---

## Your Current Setup (Correct ✅)

| App | Method | Status |
|-----|--------|--------|
| ulauncher | systemd service | ✅ Enabled |
| 1Password | XDG autostart | ✅ Auto-managed |
| blueman | XDG autostart | ✅ Auto-managed |
| nm-applet | XDG autostart | ✅ Auto-managed |
| CopyQ | XDG autostart | ✅ Auto-managed |
| Nextcloud | XDG autostart | ✅ Auto-managed |
| Nym-VPN | XDG autostart | ✅ Auto-managed |
| beeper | uwsm app | ✅ Correct |
| pypr | uwsm app | ✅ Correct |
| bongocat | uwsm app | ✅ Correct |
| quickshell | uwsm app | ✅ Correct |
| xsettingsd | uwsm app + custom config | ✅ Correct |

---

## Useful Commands

```bash
# List all systemd user services
systemctl --user list-unit-files

# List running services
systemctl --user list-units --state=running

# Check XDG autostart integration
systemctl --user list-units | grep "@autostart"

# View app logs
journalctl --user -u <service> -f

# Check if service exists for an app
systemctl --user list-unit-files | grep -i <app-name>
```

---

## Common Mistakes to Avoid

❌ **Don't do this:**
```conf
# Bad: App has systemd service but using exec-once
exec-once = ulauncher --hide-window &
```

✅ **Do this instead:**
```bash
systemctl --user enable ulauncher.service
```

---

❌ **Don't do this:**
```conf
# Bad: Using sleep hacks for timing
exec-once = sleep 5 && some-app &
```

✅ **Do this instead:**
```conf
# Use systemd service with proper After= dependencies
# Or let XDG autostart handle it
```

---

## Last Updated
2025-11-03 - Full audit completed, all services properly configured
