# Howdy Face Authentication Setup Guide

Complete guide to setting up Howdy (Windows Hello-style face recognition) on
Arch/CachyOS with Hyprland, including polkit integration for GUI privilege
escalation (e.g., KDE Partition Manager, Software Center, etc.).

---

## Table of Contents

- [How It All Works (ELI5)](#how-it-all-works-eli5)
- [Prerequisites](#prerequisites)
- [Step 1: Install Packages](#step-1-install-packages)
- [Step 2: Identify Your IR Camera](#step-2-identify-your-ir-camera)
- [Step 3: Configure Howdy](#step-3-configure-howdy)
- [Step 4: Enroll Your Face](#step-4-enroll-your-face)
- [Step 5: Configure PAM (Password Rules)](#step-5-configure-pam-password-rules)
- [Step 6: Set Up the Polkit Agent](#step-6-set-up-the-polkit-agent)
- [Step 7: Fix Polkit Sandboxing for Camera + GPU](#step-7-fix-polkit-sandboxing-for-camera--gpu)
- [Step 8: Test Everything](#step-8-test-everything)
- [Troubleshooting](#troubleshooting)
- [Reference: Config File Locations](#reference-config-file-locations)

---

## How It All Works (ELI5)

### What is Howdy?

Howdy is like Face ID or Windows Hello for Linux. When your computer asks for
your password, Howdy uses your webcam (ideally an infrared camera) to look at
your face. If it recognizes you, it unlocks without you typing anything.

### What is PAM?

**PAM** (Pluggable Authentication Modules) is the system Linux uses to verify
who you are. Think of it as a **bouncer at a nightclub** with a checklist:

1. First, try checking your face (Howdy)
2. If that doesn't work, ask for the password

Every program that needs to verify your identity (sudo, login, screen lock,
etc.) has its own checklist file in `/etc/pam.d/`. When you add Howdy to one
of these files, you're telling that program: "Try face recognition first."

The key PAM rule we use is:

```
auth sufficient pam_howdy.so
```

- `auth` = "this is an authentication check"
- `sufficient` = "if this succeeds, skip everything else and let them in"
- `pam_howdy.so` = "use the Howdy face recognition module"

If Howdy fails (can't see your face, timeout, etc.), PAM just moves to the
next item on the checklist — which is the normal password prompt.

### What is polkit?

**Polkit** (PolicyKit) is the system that handles "I need admin permission to
do this specific thing" in graphical apps. Think of it like this:

- **sudo** = you type a command in the terminal and it asks for your password
- **polkit** = you click a button in a graphical app and a popup asks for
  your password

For example, when KDE Partition Manager needs to modify your disk, it asks
polkit: "Can this user do this?" Polkit then asks you to prove who you are.

Polkit has three parts:

1. **polkitd** (the daemon) — the decision maker, runs in the background.
   It knows the rules about who can do what.
2. **polkit agent** (the popup) — the program that shows you the "enter your
   password" dialog. On Hyprland, we use `hyprpolkitagent`.
3. **polkit-agent-helper-1** (the verifier) — the behind-the-scenes program
   that actually checks your password (or face!) through PAM. This runs as
   a systemd service with strict security sandboxing.

The flow looks like this:

```
App needs permission
    → polkitd says "authenticate the user"
    → polkit agent shows the dialog
    → polkit-agent-helper-1 runs PAM checks
    → PAM tries Howdy (face scan)
    → If face fails, PAM asks for password
    → Result sent back to polkitd
    → App gets (or doesn't get) permission
```

### What is systemd sandboxing?

When `polkit-agent-helper-1` runs, systemd wraps it in a security sandbox —
like putting it in a locked room with only the bare minimum it needs. By
default, this sandbox blocks access to ALL hardware devices (cameras, GPUs),
blocks writable+executable memory (needed by CUDA), and more.

This is great for security, but it means Howdy can't access your camera or
use your NVIDIA GPU for fast face detection unless we poke specific holes in
the sandbox.

### What is the IR camera?

Most laptops with face recognition have **two** cameras on the same physical
hardware:

- `/dev/video0` — the regular RGB webcam (what you see in video calls)
- `/dev/video2` — the infrared (IR) camera (invisible light, works in the
  dark, harder to fool with a photo)

Howdy uses the IR camera for more reliable and secure face detection.

### What is dlib and CNN vs HOG?

Howdy uses a library called **dlib** to detect and recognize faces. It has
two detection modes:

- **HOG** (Histogram of Oriented Gradients) — fast on CPU, less accurate.
  Good for weaker hardware.
- **CNN** (Convolutional Neural Network) — much more accurate, but very slow
  on CPU. With an NVIDIA GPU and CUDA, it runs in milliseconds. This is what
  we use with the RTX 4090.

---

## Prerequisites

- Arch Linux or CachyOS (or any Arch-based distro)
- Hyprland window manager
- A webcam with IR capability (check with `v4l2-ctl --list-devices`)
- NVIDIA GPU with CUDA support (optional but strongly recommended for CNN mode)
- Your user must be in the `video` group:
  ```bash
  sudo usermod -aG video $USER
  ```

---

## Step 1: Install Packages

```bash
# Core packages
sudo pacman -S polkit hyprpolkitagent

# Howdy (from AUR — use your preferred AUR helper)
yay -S howdy-git

# For CUDA-accelerated face detection (recommended with NVIDIA GPU)
yay -S dlib-cuda python-dlib-cuda

# Verify CUDA works
python3 -c "import dlib; print('CUDA:', dlib.DLIB_USE_CUDA)"
# Should print: CUDA: True
```

### What each package does

| Package | Purpose |
|---------|---------|
| `polkit` | The privilege management daemon |
| `hyprpolkitagent` | Shows the auth dialog on Hyprland |
| `howdy-git` | Face recognition PAM module + tools |
| `dlib-cuda` | Face detection library with GPU support |
| `python-dlib-cuda` | Python bindings for dlib with CUDA |
| `python-opencv` | Camera capture library (installed as howdy dependency) |

---

## Step 2: Identify Your IR Camera

```bash
# List all camera devices
v4l2-ctl --list-devices
```

You'll see output like:

```
FHD Webcam: FHD Webcam (usb-0000:00:14.0-5):
    /dev/video0      ← Regular webcam
    /dev/video1      ← Regular webcam metadata
    /dev/video2      ← IR camera
    /dev/video3      ← IR camera metadata
```

Verify which one is the IR camera:

```bash
v4l2-ctl -d /dev/video2 --all | head -5
# Look for "IR Camera" in the Card type
```

**Remember the IR camera device path** (e.g., `/dev/video2`). You'll need it
for the Howdy config.

---

## Step 3: Configure Howdy

Edit the Howdy configuration:

```bash
sudo howdy config
```

Or directly edit `/etc/howdy/config.ini`. Here are the important settings:

```ini
[core]
# Show "attempting facial authentication" in terminal
detection_notice = true
# Use NVIDIA GPU for face detection (set false if no NVIDIA GPU)
use_gpu = true
# Use CNN model (much more accurate, needs GPU to be fast)
use_cnn = true
# Don't run in SSH sessions (security)
abort_if_ssh = true
# Don't try if laptop lid is closed
abort_if_lid_closed = true
# Enable howdy
disabled = false

[video]
# How close the match needs to be (lower = stricter, 3.0-4.0 is good)
certainty = 3.2
# How long to try before giving up (seconds)
timeout = 10
# Path to your IR camera (from Step 2!)
device_path = /dev/video2
# Don't print warnings if camera not found (avoids noise)
warn_no_device = false
# Camera resolution
frame_width = 640
frame_height = 360
# Threshold for "too dark" frames (IR cameras produce darker images)
dark_threshold = 30
# Use OpenCV for camera capture
recording_plugin = opencv
# Camera frame rate
device_fps = 30

[snapshots]
# Save photos of failed login attempts (security monitoring)
save_failed = true
save_successful = false

[debug]
# Set to true temporarily if you need to debug issues
end_report = false
```

---

## Step 4: Enroll Your Face

```bash
# Add your first face model
sudo howdy add

# Add more models for different conditions (glasses, lighting, etc.)
sudo howdy add

# List enrolled models
sudo howdy list

# Test that recognition works
sudo howdy test
```

**Tip:** Enroll multiple models — one with glasses, one without, one in
different lighting. This significantly improves recognition reliability.

To remove a model:

```bash
sudo howdy remove <ID>
```

---

## Step 5: Configure PAM (Password Rules)

This is the most important step. We need to tell each authentication service
to try Howdy first, then fall back to password.

### Critical Rule: Howdy goes in EACH SERVICE, NOT in system-auth

The file `/etc/pam.d/system-auth` is **included** by other services (sudo,
polkit, hyprlock, etc.). If you put Howdy in `system-auth` AND in the
individual service files, Howdy runs **twice** per auth attempt — causing
duplicate popups and camera conflicts.

**The correct approach:** Put Howdy in each individual service file, and
keep `system-auth` clean.

### /etc/pam.d/system-auth (NO Howdy here!)

```bash
sudo tee /etc/pam.d/system-auth << 'EOF'
#%PAM-1.0

# NOTE: Howdy face auth is configured per-service (sudo, polkit-1, hyprlock, etc.)
# Do NOT add pam_howdy.so here to avoid double invocation via 'include system-auth'

auth       required                    pam_faillock.so      preauth
-auth      [success=2 default=ignore]  pam_systemd_home.so
auth       [success=1 default=bad]     pam_unix.so          try_first_pass nullok
auth       [default=die]               pam_faillock.so      authfail

auth       optional                    pam_permit.so
auth       required                    pam_env.so
auth       required                    pam_faillock.so      authsucc

-account   [success=1 default=ignore]  pam_systemd_home.so
account    required                    pam_unix.so
account    optional                    pam_permit.so
account    required                    pam_time.so

-password  [success=1 default=ignore]  pam_systemd_home.so
password   required                    pam_unix.so          try_first_pass nullok shadow
password   optional                    pam_permit.so

-session   optional                    pam_systemd_home.so
session    required                    pam_limits.so
session    required                    pam_unix.so
session    optional                    pam_permit.so
EOF
```

### /etc/pam.d/sudo

```bash
sudo tee /etc/pam.d/sudo << 'EOF'
#%PAM-1.0
auth sufficient /lib/security/pam_howdy.so
auth		include		system-auth
account		include		system-auth
session		include		system-auth
EOF
```

### /etc/pam.d/polkit-1

```bash
sudo tee /etc/pam.d/polkit-1 << 'EOF'
#%PAM-1.0

# Howdy face authentication for PolicyKit
auth       sufficient                  pam_howdy.so

# Include system-auth for fallback authentication
auth       include                     system-auth
account    include                     system-auth
session    include                     system-auth
EOF
```

### /etc/pam.d/hyprlock

```bash
sudo tee /etc/pam.d/hyprlock << 'EOF'
#%PAM-1.0
# PAM configuration for hyprlock with Howdy support

# Try facial recognition first
auth sufficient pam_howdy.so

# Fall back to password if face recognition fails
auth include system-auth
account include system-auth
password include system-auth
session include system-auth
EOF
```

### /etc/pam.d/sddm (login screen)

```bash
sudo tee /etc/pam.d/sddm << 'EOF'
#%PAM-1.0

# Howdy face authentication for SDDM login
auth       sufficient                  pam_howdy.so

auth       include                     system-auth
-auth      optional                    pam_gnome_keyring.so
-auth      optional                    pam_kwallet5.so

account    include                     system-auth

password   include                     system-auth
-password  optional                    pam_gnome_keyring.so use_authtok

session    include                     system-auth
-session   optional                    pam_keyinit.so revoke
-session   optional                    pam_gnome_keyring.so auto_start
-session   optional                    pam_kwallet5.so auto_start
EOF
```

### Why `sufficient`?

In PAM, `sufficient` means "if this module succeeds, immediately grant access
and skip everything else." If it fails, PAM just continues to the next line.
This is perfect for Howdy: if it sees your face, you're in. If not, you type
your password as usual.

---

## Step 6: Set Up the Polkit Agent

A polkit agent is the program that shows you the authentication dialog when
a graphical app needs elevated privileges. **Without a polkit agent, GUI apps
can't ask for your password at all.**

### Enable hyprpolkitagent

```bash
# Enable the systemd user service (starts on login)
systemctl --user enable hyprpolkitagent.service
```

### Add to Hyprland autostart

In your Hyprland autostart config (e.g., `~/.config/hypr/config/autostart.conf`):

```
# Polkit authentication agent (needed for GUI privilege escalation)
exec-once = systemctl --user start hyprpolkitagent.service
```

### Verify it's running

```bash
pgrep -a hyprpolkit
# Should show: /usr/lib/hyprpolkitagent/hyprpolkitagent

systemctl --user status hyprpolkitagent.service
# Should show: active (running)
```

### Why not lxqt-policykit-agent?

On Hyprland, `lxqt-policykit-agent` tends to crash or fail to register
properly. `hyprpolkitagent` is built specifically for Hyprland and runs
reliably as a systemd user service with auto-restart.

---

## Step 7: Fix Polkit Sandboxing for Camera + GPU

This is the step most guides miss. The polkit authentication helper runs
inside a strict systemd sandbox that blocks hardware access by default.
Without this fix, Howdy will try to scan but the camera will never turn on.

### The Problem

When a polkit auth is triggered, systemd spawns `polkit-agent-helper-1` with
these security restrictions (from `/usr/lib/systemd/system/polkit-agent-helper@.service`):

```ini
PrivateDevices=yes       # Creates a private /dev with NO hardware devices
DevicePolicy=strict      # Blocks all device access except what's listed
DeviceAllow=/dev/null rw # Only /dev/null is allowed
MemoryDenyWriteExecute=yes  # Blocks CUDA GPU memory mapping
```

This means:
- **Camera is invisible** — `/dev/video2` doesn't exist in the sandbox
- **NVIDIA GPU is blocked** — CUDA can't map memory, so dlib falls back to
  CPU-only CNN detection which is absurdly slow (seconds per frame instead
  of milliseconds)

### The Fix: Create a systemd drop-in override

```bash
# Create the override directory
sudo mkdir -p /etc/systemd/system/polkit-agent-helper@.service.d

# Create the override file
sudo tee /etc/systemd/system/polkit-agent-helper@.service.d/howdy-camera.conf << 'EOF'
# Allow Howdy face recognition via pam_howdy.so
# The default service has strict sandboxing that prevents:
# 1. Camera access (PrivateDevices=yes, DevicePolicy=strict)
# 2. CUDA/GPU acceleration (MemoryDenyWriteExecute=yes)

[Service]
# Allow camera device access
PrivateDevices=no
DevicePolicy=auto
DeviceAllow=/dev/video0 rw
DeviceAllow=/dev/video1 rw
DeviceAllow=/dev/video2 rw
DeviceAllow=/dev/video3 rw
# Allow NVIDIA GPU access for CUDA-accelerated face detection
DeviceAllow=/dev/nvidia0 rw
DeviceAllow=/dev/nvidiactl rw
DeviceAllow=/dev/nvidia-uvm rw
DeviceAllow=/dev/nvidia-uvm-tools rw

# Allow CUDA to map GPU memory (needed for dlib CNN face detection)
MemoryDenyWriteExecute=no

# Allow writing snapshots to /var/log/howdy
ReadWritePaths=/var/log/howdy
EOF

# Reload systemd to apply changes
sudo systemctl daemon-reload
```

### Verify the override is active

```bash
systemctl cat polkit-agent-helper@.service
# Should show the original config PLUS your override at the bottom
```

### What about security?

This override relaxes some sandboxing for the polkit helper. The tradeoffs:

| Setting | Default | Override | Risk |
|---------|---------|----------|------|
| `PrivateDevices` | yes | no | Helper can see hardware devices |
| `DevicePolicy` | strict | auto | Specific devices are whitelisted |
| `MemoryDenyWriteExecute` | yes | no | Allows JIT/CUDA memory mapping |

The remaining sandboxing is still active (`ProtectSystem=strict`,
`ProtectHome=yes`, `PrivateNetwork=yes`, `NoNewPrivileges=yes`, etc.), so
the helper is still well-contained. The override only punches the minimum
holes needed for Howdy to access the camera and GPU.

### No NVIDIA GPU?

If you don't have an NVIDIA GPU, you can simplify the override — remove the
`nvidia` DeviceAllow lines and keep `MemoryDenyWriteExecute=yes`. You should
also set `use_cnn = false` in the Howdy config to use HOG mode instead (fast
on CPU, slightly less accurate).

---

## Step 8: Test Everything

### Test sudo (terminal)

```bash
sudo -k          # Clear cached credentials
sudo echo "works" # Should scan your face
```

### Test polkit (GUI apps)

```bash
pkexec echo "polkit works"   # Should show polkit dialog + face scan
```

Then open a real app like KDE Partition Manager and verify the face scan
triggers when it asks for authentication.

### Test hyprlock (screen lock)

Lock your screen and verify face unlock works.

### Verify camera activation

When Howdy is scanning, you should see:
- IR camera LED lights up
- Terminal shows "Attempting facial authentication"
- Howdy GTK overlay shows "Identifying you..." (for polkit)
- Recognition completes in ~2-3 seconds with GPU

---

## Troubleshooting

### "Attempting facial authentication" but camera never turns on

**For sudo/hyprlock:** Check that `/dev/video2` exists and your user is in
the `video` group:

```bash
ls -la /dev/video2
groups $USER | grep video
```

**For polkit:** The systemd sandbox is blocking camera access. Apply the
override from [Step 7](#step-7-fix-polkit-sandboxing-for-camera--gpu).

### Camera turns on but face is never recognized

**Check if CUDA is working:**

```bash
python3 -c "import dlib; print('CUDA:', dlib.DLIB_USE_CUDA, 'Devices:', dlib.cuda.get_num_devices())"
```

If CUDA shows `False` or 0 devices, install `dlib-cuda` and `python-dlib-cuda`.

**For polkit specifically:** The `MemoryDenyWriteExecute=yes` sandbox setting
blocks CUDA. Without GPU acceleration, CNN mode is too slow to scan enough
frames in the timeout period. Apply the full override from Step 7.

**If you don't have a GPU:** Set `use_cnn = false` in `/etc/howdy/config.ini`
to use HOG mode, which is fast on CPU.

### Howdy runs twice / stacking popups

Howdy is configured in both the service PAM file AND in `system-auth`. Since
services `include system-auth`, Howdy triggers twice. **Remove Howdy from
`/etc/pam.d/system-auth`** and only configure it in individual service files.

### Stuck howdy-gtk / zombie processes after polkit auth

The `howdy-gtk` visual overlay can get orphaned on Wayland. Kill it:

```bash
pkill -f howdy-gtk
```

If processes are stuck and sudo doesn't work (because the camera is locked):

```bash
# Option 1: Use systemctl (doesn't need sudo)
systemctl list-units "polkit-agent-helper@*"
# Then: systemctl stop <unit-name>  (may need a reboot if access denied)

# Option 2: If completely stuck, reboot
systemctl reboot
```

### No polkit dialog appears at all

Check that the polkit agent is running:

```bash
pgrep -a hyprpolkit
systemctl --user status hyprpolkitagent.service
```

If not running:

```bash
systemctl --user start hyprpolkitagent.service
systemctl --user enable hyprpolkitagent.service
```

### Howdy works for sudo but not polkit

This is almost always the systemd sandbox. Verify the override:

```bash
systemctl cat polkit-agent-helper@.service | grep -A5 "howdy-camera"
```

If the override isn't showing, re-create it (Step 7) and run
`sudo systemctl daemon-reload`.

### Enable debug output

Temporarily enable detailed timing info:

```bash
sudo howdy config
# Set [debug] end_report = true
```

Then trigger an auth and check the output. The report shows:
- How long camera took to open
- How many frames were scanned
- FPS and timing breakdown
- Which model matched and at what certainty

Remember to set it back to `false` when done.

---

## Reference: Config File Locations

| File | Purpose |
|------|---------|
| `/etc/howdy/config.ini` | Main Howdy configuration |
| `/etc/howdy/models/<user>.dat` | Enrolled face models |
| `/usr/share/dlib-data/` | dlib neural network model files |
| `/etc/pam.d/system-auth` | Base PAM auth config (NO Howdy here) |
| `/etc/pam.d/sudo` | PAM config for sudo |
| `/etc/pam.d/polkit-1` | PAM config for polkit privilege escalation |
| `/etc/pam.d/hyprlock` | PAM config for Hyprland screen lock |
| `/etc/pam.d/sddm` | PAM config for SDDM login screen |
| `/etc/systemd/system/polkit-agent-helper@.service.d/howdy-camera.conf` | Systemd sandbox override for camera+GPU |
| `/usr/lib/systemd/system/polkit-agent-helper@.service` | Original polkit helper service (don't edit) |
| `/usr/lib/systemd/user/hyprpolkitagent.service` | Polkit agent systemd service |
| `~/.config/hypr/config/autostart.conf` | Hyprland autostart (polkit agent launch) |
| `/var/log/howdy/snapshots/` | Failed login attempt snapshots |
| `/lib/security/pam_howdy.so` | The Howdy PAM module binary |
| `/usr/lib/howdy/compare.py` | Face comparison Python script |

---

## Package Versions (as of this setup)

| Package | Version |
|---------|---------|
| howdy-git | r592.d3ab993-1 |
| polkit | 127-3.1 |
| hyprpolkitagent | 0.1.3-4.1 |
| python-dlib-cuda | 20.0-2 |
| python-opencv | 4.13.0-2.1 |
| dlib-cuda | 19.24.6-1 |

---

*Last updated: 2026-02-08*
*System: CachyOS (Arch-based), Hyprland, NVIDIA RTX 4090*
