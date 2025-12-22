# Resizable BAR Status - December 13, 2025

## Verification Results

### ✅ Resizable BAR is ENABLED and Working

**Confirmed via NVIDIA SMI**:
```bash
$ nvidia-smi -q | grep -A 3 "BAR1"
    BAR1 Memory Usage
        Total                                          : 16384 MiB
        Used                                           : 5 MiB
        Free                                           : 16379 MiB
```

### What This Means

Your RTX 4090 has **16GB of VRAM** and the BAR1 memory shows **16384 MiB (16GB)**. This confirms that:

1. ✅ **Resizable BAR is enabled** at the BIOS/UEFI level
2. ✅ **The CPU can access the full GPU VRAM** directly
3. ✅ **No additional configuration needed**

### System Configuration

- **GPU**: NVIDIA GeForce RTX 4090 Laptop GPU
- **VRAM**: 16GB GDDR6X
- **CPU**: Intel Raptor Lake (13th/14th Gen)
- **Platform**: Stellaris 17 Gen6 Laptop
- **BIOS**: ReBAR already enabled by manufacturer
- **Driver**: nvidia-dkms 580.119.02-2

### Why ReBAR Matters

**Traditional PCIe BAR (Before ReBAR)**:
- CPU could only access 256MB of GPU VRAM at a time
- Required multiple small transfers for large data
- Increased latency and reduced performance

**With Resizable BAR Enabled**:
- CPU can access all 16GB of GPU VRAM directly
- Single large transfers instead of multiple small ones
- Reduced latency and improved performance
- Particularly beneficial for:
  - Large texture streaming (games, 3D apps)
  - Machine learning workloads
  - GPU computing tasks
  - Wayland compositors with direct scanout

### Performance Impact

**Expected improvements with ReBAR**:
- **Gaming**: 5-10% FPS improvement in GPU-bound scenarios
- **Compositing**: Better direct scanout performance
- **ML/AI**: Faster data transfer to/from GPU
- **General**: Reduced PCIe transfer overhead

### Verification Commands

```bash
# Check BAR1 size (should match VRAM)
nvidia-smi -q | grep -A 3 "BAR1"

# Check PCI memory regions
lspci -vvv -s 01:00.0 | grep "Region 1"
# Should show: Region 1: Memory at 6000000000 (64-bit, prefetchable) [size=16G]

# Check kernel config
cat /etc/modprobe.d/nvidia.conf
# Should show: options nvidia_drm modeset=1 fbdev=1
```

### No Action Required

Your system is already optimally configured:
- ✅ ReBAR enabled in BIOS
- ✅ NVIDIA drivers correctly detect and use ReBAR
- ✅ Full 16GB VRAM accessible via BAR1
- ✅ Hyprland direct_scanout can take full advantage

### Intel + NVIDIA Hybrid Graphics Note

Your system has:
- **Intel Raptor Lake iGPU** (for power saving)
- **NVIDIA RTX 4090 dGPU** (for performance)

With ReBAR enabled, both GPUs work efficiently:
- Intel iGPU handles desktop compositing when idle
- NVIDIA dGPU takes over for intensive tasks
- ReBAR allows fast CPU-GPU memory transfers

Your mkinitcpio config already loads modules in the correct order:
```bash
MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm ...)
```

This ensures Intel iGPU initializes first, preventing conflicts.

### References

- **NVIDIA ReBAR Documentation**: Requires RTX 30+ series GPUs
- **Intel Platform**: 10th Gen+ CPUs with 400+ series chipsets
- **PCIe 3.0/4.0**: Both support ReBAR (your system uses PCIe 4.0)
- **Hyprland**: Benefits from ReBAR with direct_scanout enabled

---

**Document Created**: 2025-12-13
**Status**: ✅ ReBAR verified and working correctly
**Action Required**: None - system already optimal


