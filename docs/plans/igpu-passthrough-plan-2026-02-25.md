# Intel N150 iGPU Passthrough via SR-IOV for Frigate

**Date:** 2026-02-25
**Status:** Completed (2026-03-02) — iGPU passthrough active, OpenVINO ~15ms, VA-API decode
**Estimated time:** 45-60 minutes (including BIOS access, reboots, troubleshooting)
**Downtime:** ~10-15 minutes (Proxmox reboot + VM stop/start)
**Rollback time:** ~5 minutes (revert VM machine type, remove hostpci0)

---

## Context

Frigate NVR runs OpenVINO on CPU (~117ms inference) with VAAPI hardware decoding disabled because the Docker VM (VM 101) has no GPU access. The N150's Xe-LP iGPU (24 EU) supports OpenVINO GPU inference (~15ms, 7x faster) and VAAPI H.264/H.265 hardware decode. The iGPU is visible on the Proxmox host (`/dev/dri/renderD128`) but not passed through to the VM.

**Approach:** SR-IOV via `i915-sriov-dkms` — creates virtual GPU functions that can be assigned to VMs. The host retains GPU access through the physical function (PF), the VM gets a virtual function (VF).

**Why NOT full PCI passthrough (GVT-d):** The N150's iGPU is not in its own IOMMU group and has no proper reset support — causes VM freeze on boot. GVT-g is deprecated (10th gen was the last). SR-IOV is the community-confirmed working approach for Alder Lake-N.

---

## Pre-Maintenance Checklist

| Item | Status | Value |
|------|--------|-------|
| Proxmox kernel | >= 6.11 required | 6.17.4-2-pve |
| Docker VM kernel | >= 6.11 required | 6.12.63+deb13 (Trixie) |
| VM 101 BIOS | OVMF (UEFI) | OK |
| VM 101 CPU type | host | OK |
| VM 101 machine type | i440fx (default) | Needs q35 |
| VM 101 RAM | 7168MB | OK |
| iGPU PCI address | 00:02.0 | Intel Alder Lake-N |
| GRUB IOMMU | "quiet" only | Needs params |
| SR-IOV | Not configured | Needs setup |

No kernel upgrades needed — both are above the 6.11 minimum.

---

## Step 1: BIOS Settings (~5 min)

**Requires physical access to the Aoostar N1 Pro.**

Power off Proxmox host, enter BIOS, verify/enable:

- [ ] Intel VT-d (Virtualization Technology for Directed I/O): **Enabled**
- [ ] Intel VT-x (Virtualization Technology): **Enabled**
- [ ] Internal Graphics: **Enabled**
- [ ] DVMT Pre-Allocated: **64MB** minimum (higher is better for multiple VFs)
- [ ] SR-IOV Support: **Enabled** (if the option exists in BIOS)
- [ ] ARI (Alternative Routing-ID Interpretation): **Enabled** (if available)

Save and boot into Proxmox.

---

## Step 2: Proxmox Host — IOMMU + SR-IOV (~15-20 min)

SSH into `proxmox` as root (`ssh proxmox` then `sudo -i`).

### 2a. Update GRUB bootloader

Edit `/etc/default/grub`:

```bash
# Change this line:
GRUB_CMDLINE_LINUX_DEFAULT="quiet"

# To:
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt i915.enable_guc=3 i915.max_vfs=7 module_blacklist=xe"
```

Parameter breakdown:
| Parameter | Purpose |
|-----------|---------|
| `intel_iommu=on` | Enable Intel VT-d IOMMU |
| `iommu=pt` | Passthrough mode (performance for non-passthrough devices) |
| `i915.enable_guc=3` | Enable GuC firmware (required for SR-IOV) |
| `i915.max_vfs=7` | Allow up to 7 virtual GPU functions |
| `module_blacklist=xe` | Prevent newer `xe` driver (no SR-IOV support yet) |

Apply:
```bash
update-grub
```

### 2b. Add VFIO kernel modules

Append to `/etc/modules`:
```
vfio
vfio_iommu_type1
vfio_pci
```

**Note:** Do NOT add `vfio_virqfd` — merged into `vfio` since kernel 6.2.

### 2c. Install i915-sriov-dkms

```bash
apt update
apt install -y build-essential dkms sysfsutils proxmox-headers-$(uname -r)

# Download latest .deb from https://github.com/strongtz/i915-sriov-dkms/releases
wget https://github.com/strongtz/i915-sriov-dkms/releases/download/<VERSION>/i915-sriov-dkms_<VERSION>_amd64.deb
dpkg -i i915-sriov-dkms_*.deb
```

Verify:
```bash
dkms status
# Should show: i915-sriov-dkms, <version>, <kernel>: installed
```

### 2d. Configure VFs to persist on boot

```bash
echo "devices/pci0000:00/0000:00:02.0/sriov_numvfs = 7" > /etc/sysfs.conf
```

### 2e. Reboot Proxmox

```bash
reboot
```

### 2f. Verify after reboot

```bash
# IOMMU active
dmesg | grep -e DMAR -e IOMMU
# Expected: "DMAR: IOMMU enabled"

# VFs created (should show 8 entries: 1 PF + 7 VFs)
lspci | grep VGA
# Expected:
# 00:02.0 VGA compatible controller: Intel Corporation Alder Lake-N [Intel Graphics]  (PF)
# 00:02.1 VGA compatible controller: Intel Corporation Alder Lake-N [Intel Graphics]  (VF1)
# 00:02.2 ... (VF2)
# ... up to 00:02.7 (VF7)

# DKMS module loaded
dkms status
# Expected: i915-sriov-dkms installed

# SR-IOV VFs active
dmesg | grep i915
# Expected: "Enabled 7 VFs"
```

**If VFs don't appear:** Check BIOS VT-d setting, verify `i915.max_vfs=7` is in GRUB, check `dkms status` for build errors.

---

## Step 3: Assign VF to Docker VM (~5 min)

**CRITICAL: Never pass the Physical Function (00:02.0) to a VM — only pass VFs (00:02.1 through 00:02.7).**

```bash
# Stop VM first (required for machine type change)
qm stop 101

# Change machine type from i440fx to q35 (required for PCIe passthrough)
qm set 101 -machine q35

# Assign first virtual function to VM
qm set 101 -hostpci0 0000:00:02.1,pcie=1

# Start VM
qm start 101
```

Resulting `/etc/pve/qemu-server/101.conf` should include:
```
machine: q35
hostpci0: 0000:00:02.1,pcie=1
```

**Risk note:** Changing i440fx → q35 may change device naming inside the VM. OVMF + virtio-scsi-single + virtio NIC should work fine with q35. If VM doesn't boot, revert:
```bash
qm stop 101
qm set 101 -machine i440fx
qm set 101 -delete hostpci0
qm start 101
```

---

## Step 4: Verify GPU in Docker VM (~5 min)

SSH into `docker-vm`:

```bash
# Check GPU device exists
ls -la /dev/dri/
# Expected: card0, renderD128

# Install verification tools
sudo apt install -y vainfo intel-gpu-tools

# Verify VAAPI profiles
vainfo
# Expected: VAProfileH264High, VAProfileHEVCMain, etc.

# Note the render group GID (needed for Docker)
getent group render
# Expected: render:x:109: (or similar GID)

# Optional: check GPU activity
sudo intel_gpu_top
# Should show GPU utilization when Frigate runs
```

### Fallback: If `/dev/dri` is missing

Install the patched i915 driver in the guest VM too:

```bash
sudo apt install -y build-essential dkms linux-headers-$(uname -r)

# Copy the same .deb from Proxmox host or download it
sudo dpkg -i i915-sriov-dkms_*.deb

# Configure i915 options
echo 'options i915 enable_guc=3' | sudo tee /etc/modprobe.d/i915.conf
echo 'blacklist xe' | sudo tee /etc/modprobe.d/blacklist-xe.conf

sudo update-initramfs -u
sudo reboot
```

---

## Step 5: Update Frigate Configuration (~5 min)

### 5a. Frigate config (`docker/fixed/docker-vm/security/frigate.yml`)

Change detector from CPU to GPU:
```yaml
detectors:
  ov:
    type: openvino
    device: GPU    # was: CPU
    # IMPORTANT: Do NOT use "AUTO" — known bug. Must be explicit "GPU" or "CPU"
```

Enable VAAPI hardware decoding (uncomment):
```yaml
ffmpeg:
  hwaccel_args: preset-vaapi
```

### 5b. Docker Compose (`docker/fixed/docker-vm/security/docker-compose.yml`)

Optionally tighten device mapping and add render group:
```yaml
devices:
  - /dev/dri/renderD128:/dev/dri/renderD128  # was: /dev/dri:/dev/dri
group_add:
  - "109"  # render group GID — verify with: getent group render
```

---

## Step 6: Deploy and Verify (~5-10 min)

```bash
# SCP updated config to Docker VM
scp docker/fixed/docker-vm/security/frigate.yml docker-vm:/tmp/

# Copy into container and restart
ssh docker-vm "sudo docker cp /tmp/frigate.yml frigate:/config/config.yml"
ssh docker-vm "cd /opt/homelab/repo/docker/fixed/docker-vm/security && sudo docker compose restart frigate"

# Verify VAAPI inside container
ssh docker-vm "sudo docker exec frigate vainfo"
# Expected: Intel iHD driver, H.264/H.265 profiles listed

# Check Frigate logs for GPU detection
ssh docker-vm "sudo docker logs frigate 2>&1 | tail -30"
# Expected: OpenVINO GPU device loaded, VAAPI initialized

# Check inference speed in Frigate web UI
# taguato.cronova.dev → System → should show ~15ms instead of ~117ms
```

---

## Step 7: Commit Changes

```bash
git add docker/fixed/docker-vm/security/frigate.yml docker/fixed/docker-vm/security/docker-compose.yml
git commit -m "feat: enable OpenVINO GPU + VAAPI via iGPU SR-IOV passthrough"
git push
```

---

## Time Estimates

| Step | Duration | Notes |
|------|----------|-------|
| Step 1: BIOS check | 5 min | Physical access, reboot into BIOS |
| Step 2: Proxmox IOMMU + SR-IOV | 15-20 min | GRUB, DKMS install, reboot |
| Step 3: VM config + GPU assign | 5 min | Stop/start VM |
| Step 4: Verify GPU in VM | 5 min | Install vainfo, check /dev/dri |
| Step 5: Update Frigate config | 5 min | Edit 2 files |
| Step 6: Deploy + verify | 5-10 min | SCP, restart, check logs |
| Step 7: Commit | 2 min | Git commit + push |
| **Total** | **~45-60 min** | **Including troubleshooting buffer** |
| **Downtime** | **~10-15 min** | **Proxmox reboot + VM stop/start** |

---

## Rollback Procedure

If anything goes wrong, revert in reverse order:

### Revert Frigate config
```bash
# Change device: GPU back to device: CPU
# Comment out hwaccel_args: preset-vaapi
# Redeploy
```

### Revert VM configuration
```bash
qm stop 101
qm set 101 -delete hostpci0
qm set 101 -machine i440fx
qm start 101
```

### Revert Proxmox GRUB (if needed)
```bash
# Restore GRUB to original
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
update-grub
reboot
```

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| i440fx → q35 breaks VM boot | VM won't start | Revert: `qm set 101 -machine i440fx -delete hostpci0` |
| DKMS breaks on PVE kernel update | VFs disappear after update | Monitor `dkms status` after `apt upgrade`; pin kernel if needed |
| SR-IOV not upstream kernel | Community module maintenance | Watch GitHub releases, rebuild after kernel updates |
| VFs fail to initialize after host reboot | Frigate loses GPU silently | Add healthcheck for `/dev/dri/renderD128` existence |
| Headless boot issue | GPU drivers fail without monitor | Use dummy HDMI plug (~$5) if this occurs (SR-IOV should be fine) |

---

## Expected Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| OpenVINO inference | ~117ms (CPU) | ~15ms (GPU) | **~7x faster** |
| Video decoding | ffmpeg CPU | VAAPI hardware | **Major CPU savings** |
| Frigate CPU usage | High | Significantly lower | Free CPU for other services |
| Host GPU access | Full | Retained (PF on host) | No loss |
| Concurrent decode | Limited by CPU | Hardware engine | Better multi-camera |

---

## Maintenance Notes

- **After every Proxmox kernel update**: Run `dkms status` to verify the i915-sriov-dkms module was rebuilt. If not, run `dkms autoinstall && update-initramfs -u`.
- **SR-IOV is NOT mainline** as of kernel 6.17. The community DKMS module remains necessary.
- The `xe` driver (Intel's newer GPU driver) must stay blacklisted — it does not support SR-IOV yet.
- If you ever need more VFs (e.g., for a second VM), they're already created (7 total). Just assign another VF via `hostpci`.

---

## Sources

- [Proxmox Wiki: PCI Passthrough](https://pve.proxmox.com/wiki/PCI_Passthrough)
- [strongtz/i915-sriov-dkms (GitHub)](https://github.com/strongtz/i915-sriov-dkms)
- [Proxmox Forum: Intel N150 GPU passthrough](https://forum.proxmox.com/threads/intel-n150-gpu-passthrough.160477/)
- [Proxmox Forum: N150 iGPU stuck on boot](https://forum.proxmox.com/threads/stuck-on-boot-with-intel-n150-igpu-passthrough.177837/)
- [patcfly/n150-passthrough (GitHub)](https://github.com/patcfly/n150-passthrough)
- [Derek Seaman: Proxmox vGPU Passthrough with Intel Alder Lake](https://www.derekseaman.com/2024/07/proxmox-ve-8-2-windows-11-vgpu-vt-d-passthrough-with-intel-alder-lake.html)
- [Michael's Stinkerings: vGPU SR-IOV with Intel 12th Gen](https://www.michaelstinkerings.org/gpu-virtualization-with-intel-12th-gen-igpu-uhd-730/)
- [Frigate Docs: Hardware Acceleration](https://docs.frigate.video/configuration/hardware_acceleration_video/)
