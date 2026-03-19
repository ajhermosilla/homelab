# Pre-Deployment Prep Session - 2026-01-23

**Window:** ~2 hours afternoon
**Goal:** Proxmox + OPNsense VM ready (no cutover)
**Risk:** Zero - AX3000 keeps routing, family internet unaffected

---

## Why Do This Today

| If done Jan 23 | Jan 24 benefit |
|----------------|----------------|
| Proxmox installed | Skip Phase 2 (save 45 min) |
| OPNsense VM created | Skip most of Phase 3 (save 45 min) |
| NAS drives installed | Phase 6 faster |
| **Total**|**~1.5 hours saved + less stress** |

---

## Prerequisites

Before starting, verify you have:

- [ ] Ventoy USB with Proxmox + OPNsense ISOs
- [ ] HDMI cable + USB keyboard
- [ ] Ethernet cable to connect Mini PC to switch/network
- [ ] Passwords decided (Proxmox root, OPNsense admin)
- [ ] Tailscale auth key from Headscale (generate if needed)

---

## Session Timeline

```text
START   Task                                    Duration
─────────────────────────────────────────────────────────
0:00    Setup: Connect Mini PC                  5 min
0:05    Install Proxmox                         40 min
0:45    Post-install: Access web UI             10 min
0:55    Create OPNsense VM                      30 min
1:25    Install OPNsense in VM                  20 min
1:45    Join Tailscale (optional)               10 min
1:55    Install NAS drives (if time)            15 min
─────────────────────────────────────────────────────────
~2:10   DONE
```

---

## Task 1: Connect Mini PC to Network (5 min)

The Mini PC needs network access for Proxmox post-install, but does NOT need to be in the routing path.

```text
Current setup (keep as-is):
[ISP Modem] → [AX3000] → [Devices]
                 │
            [Switch] ← Connect Mini PC here (just for management)
                 │
           [Mini PC] ← Will get IP from AX3000 DHCP
```

```json
[ ] Connect Mini PC NIC2 (LAN port) to switch
    - Do NOT connect NIC1 (WAN port) to anything yet
[ ] Connect HDMI + keyboard to Mini PC
[ ] Power on Mini PC
[ ] Enter BIOS, verify:
    - Both NICs visible
    - VT-x/VT-d enabled (for passthrough later)
    - Boot order: USB first
```

---

## Task 2: Install Proxmox VE (40 min)

### 2.1 Boot from USB

```json
[ ] Insert Ventoy USB
[ ] Boot Mini PC, select USB boot
[ ] Select Proxmox VE ISO from Ventoy menu
[ ] Wait for Proxmox installer to load
```

### 2.2 Run Installer

```json
[ ] Click "Install Proxmox VE"
[ ] Accept license agreement
[ ] Select target disk: 512GB SSD
    - Options: ext4 (default) or ZFS
    - For single disk, ext4 is fine
[ ] Country: Paraguay
[ ] Timezone: America/Asuncion
[ ] Keyboard: US (or your preference)
```

### 2.3 Admin Password & Email

```json
[ ] Password: [your chosen password - WRITE IT DOWN]
[ ] Confirm password
[ ] Email: augusto@hermosilla.me
```

### 2.4 Network Configuration

**Important:** Configure for current network (AX3000 as gateway), will adjust later.

```yaml
Management Interface: Select NIC2 (the one connected to switch)
                      Look for the one that's "UP" or has link

Hostname: pve.home.local
IP Address: 192.168.1.5/24      ← Static IP for Proxmox
Gateway: 192.168.1.1            ← AX3000 (current router)
DNS Server: 192.168.1.1         ← AX3000
```

### 2.5 Confirm & Install

```json
[ ] Review summary
[ ] Click "Install"
[ ] Wait for installation (~10-15 min)
[ ] Remove USB when prompted
[ ] Reboot
```

---

## Task 3: Post-Install Access (10 min)

### 3.1 Verify Proxmox Booted

```json
[ ] Mini PC shows Proxmox console login screen
[ ] Note the URL shown: https://192.168.1.5:8006
```

### 3.2 Access Web UI

From your MacBook (or any device on the network):

```json
[ ] Open browser: https://192.168.1.5:8006
[ ] Accept self-signed certificate warning
[ ] Login:
    - Username: root
    - Password: [your password]
    - Realm: Linux PAM
[ ] Dismiss "No valid subscription" popup (click OK)
```

### 3.3 Quick Verification

```json
[ ] Proxmox dashboard loads
[ ] See "pve" node in left sidebar
[ ] Summary shows correct RAM/CPU
```

**Checkpoint:** Proxmox installed and accessible! ~55 min elapsed.

---

## Task 4: Create OPNsense VM (30 min)

### 4.1 Upload OPNsense ISO

```json
[ ] Proxmox UI → pve → local (storage) → ISO Images
[ ] Click "Upload"
[ ] Select OPNsense ISO from your computer
[ ] Wait for upload to complete
```

### 4.2 Identify NICs for Passthrough

Before creating VM, identify which NIC is which:

```bash
# SSH to Proxmox (or use Shell in web UI)
ssh root@192.168.1.5

# List network interfaces
ip link show

# Identify NICs:
# - One should be "UP" (connected to switch, used for management)
# - Other will be used for WAN passthrough

# Get PCI addresses for passthrough
lspci | grep -i ethernet
# Example output:
# 01:00.0 Ethernet controller: Intel...  ← NIC1 (use for WAN)
# 02:00.0 Ethernet controller: Intel...  ← NIC2 (management)
```

Note the PCI address of the NIC you'll use for WAN (the one NOT currently in use).

### 4.3 Enable IOMMU (if not already)

```bash
# Check if IOMMU is enabled
dmesg | grep -i iommu

# If not enabled, edit GRUB:
nano /etc/default/grub

# Change GRUB_CMDLINE_LINUX_DEFAULT to include:
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"

# Update GRUB and reboot
update-grub
reboot
```

After reboot, re-access Proxmox web UI.

### 4.4 Create VM

```json
[ ] Proxmox UI → pve → Create VM (top right button)

General:
- VM ID: 100
- Name: opnsense

OS:
- ISO image: Select uploaded OPNsense ISO
- Type: Other

System:
- Machine: q35
- BIOS: UEFI (OVMF)
- Add EFI Disk: Yes, storage: local-lvm
- SCSI Controller: VirtIO SCSI

Disks:
- Bus/Device: VirtIO Block (virtio0)
- Storage: local-lvm
- Disk size: 20 GB
- Discard: checked

CPU:
- Sockets: 1
- Cores: 2
- Type: host

Memory:
- Memory: 2048 MB
- Ballooning: unchecked

Network:
- Bridge: vmbr0
- Model: VirtIO (paravirtualized)
- This will be the LAN interface

[ ] Finish (don't start yet)
```

### 4.5 Add WAN Interface

#### Option A: PCI Passthrough (recommended)

```json
[ ] Select VM 100 → Hardware → Add → PCI Device
[ ] Select the NIC for WAN (identified earlier)
[ ] Check "All Functions" if available
[ ] Click Add
```

#### Option B: Second Bridge (simpler, if passthrough fails)

```bash
# SSH to Proxmox, create second bridge for WAN
nano /etc/network/interfaces

# Add:
auto vmbr1
iface vmbr1 inet manual
    bridge-ports enp1s0  # Replace with actual WAN NIC name
    bridge-stp off
    bridge-fd 0
```

Then add vmbr1 as second network device to VM.

### 4.6 VM Hardware Summary

After configuration, VM 100 should have:

| Device | Purpose |
|--------|---------|
| virtio0 | 20GB disk |
| net0 (vmbr0) | LAN interface |
| hostpci0 OR net1 (vmbr1) | WAN interface |
| EFI Disk | UEFI boot |

**Checkpoint:** OPNsense VM created! ~1:25 elapsed.

---

## Task 5: Install OPNsense (20 min)

### 5.1 Start VM and Open Console

```json
[ ] Select VM 100 → Start
[ ] Click "Console" button (or use noVNC)
[ ] Watch boot process
```

### 5.2 Boot OPNsense Installer

```json
[ ] Wait for OPNsense to boot to login prompt
[ ] Login as: installer
[ ] Password: opnsense
```

### 5.3 Run Installation

```json
[ ] Select "Install (UFS)" - simpler than ZFS for small disk
[ ] Select target disk (virtio0)
[ ] Confirm disk wipe
[ ] Wait for installation
[ ] Set root password when prompted: [WRITE IT DOWN]
[ ] Select "Complete Install"
[ ] Reboot
```

### 5.4 Remove ISO

```json
[ ] While VM is rebooting:
    - VM 100 → Hardware → CD/DVD Drive
    - Edit → Do not use any media
    - Click OK
```

### 5.5 Initial OPNsense Configuration

After reboot, at OPNsense console:

```json
[ ] Login as: root / [your password]

Assign interfaces (option 1):
[ ] Do you want to configure VLANs? n
[ ] Enter WAN interface: [select passthrough NIC or vtnet1]
[ ] Enter LAN interface: vtnet0
[ ] Confirm

Set interface IP (option 2):
[ ] Select LAN (2)
[ ] Configure IPv4 via DHCP? n
[ ] IPv4 address: 192.168.1.2
    - Using .2 because AX3000 is still .1
[ ] Subnet: 24
[ ] Gateway: <blank> (this IS the gateway)
[ ] Configure IPv6? n
[ ] Enable DHCP server? n
    - AX3000 is still doing DHCP
[ ] Revert to HTTP? n
```

### 5.6 Test Web Access

```json
[ ] From MacBook: https://192.168.1.2
[ ] Accept certificate warning
[ ] Login: root / [your password]
[ ] OPNsense dashboard should load
```

**Checkpoint:** OPNsense installed and accessible! ~1:45 elapsed.

---

## Task 6: Join Proxmox to Tailscale (10 min)

This gives you remote access to Proxmox even if local network has issues.

```bash
# SSH to Proxmox
ssh root@192.168.1.5

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Join mesh with your Headscale server
tailscale up --login-server=https://hs.cronova.dev --authkey=YOUR_AUTH_KEY

# Verify
tailscale status
```

Now you can access Proxmox via Tailscale IP even remotely.

---

## Task 7: Install NAS Drives (15 min, if time permits)

If you have time remaining:

```json
[ ] Power off NAS (if on)
[ ] Open case
[ ] Install SSD (240GB Lexar) - connect to first SATA port
[ ] Install WD Purple 2TB - connect to second SATA port
[ ] Install WD Red Plus 8TB - connect to third SATA port
[ ] Close case (or leave open for easy access tomorrow)
[ ] Power on, enter BIOS
[ ] Verify all 3 drives detected
[ ] Power off (don't install OS today)
```

---

## End of Session Checklist

Before stopping:

```json
[ ] Proxmox accessible at https://192.168.1.5:8006
[ ] OPNsense VM created and accessible at https://192.168.1.2
[ ] OPNsense LAN IP is 192.168.1.2 (not .1)
[ ] AX3000 still routing - family internet works
[ ] Tailscale connected (optional)
[ ] NAS drives installed (optional)
[ ] Passwords written down safely
```

---

## What's Ready for Jan 24

After this session:

| Phase | Status | Jan 24 Action |
|-------|--------|---------------|
| Phase 1 | Ready | Just connect cables |
| Phase 2 | **DONE** | Skip |
| Phase 3 | **Mostly DONE** | Only cutover config |
| Phase 4 | Ready | Do cutover |
| Phase 5-7 | Ready | Proceed as planned |

---

## Troubleshooting

### Can't access Proxmox web UI

```bash
# From Mini PC console, check IP
ip addr show

# Check if web server running
systemctl status pveproxy

# Try restarting
systemctl restart pveproxy
```

### OPNsense VM won't start

```bash
# Check IOMMU if using passthrough
dmesg | grep -i iommu

# Try without passthrough - use bridge instead
# Remove PCI device, add second network bridge
```

### Can't access OPNsense web UI

```bash
# From OPNsense console, check IP
Option 7 (ping host) → ping 192.168.1.5

# If Proxmox reachable, check firewall
# Temporarily disable firewall from console: pfctl -d
```

---

## Notes for Tomorrow

Things to remember for Jan 24:

1. **OPNsense is at .2** - Will change to .1 during cutover
2. **DHCP is OFF** on OPNsense - Will enable during cutover
3. **WAN not connected** - Will connect ISP modem during cutover
4. **Passthrough NIC** - Note which one for WAN

---

*Session plan created: 2026-01-21*
*Session date: 2026-01-23 afternoon*
