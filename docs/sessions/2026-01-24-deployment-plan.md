# Fixed Homelab Deployment - 2026-01-24

**Window:** ~4 hours while family is away
**Goal:** Internet working when family returns
**Backup plan:** Beryl AX if things go wrong

---

## Current State

| Component | Status |
|-----------|--------|
| Mini PC | Bare metal |
| NAS | Bare metal |
| Physical cabling | Not done |
| ISP Modem | Bridge mode |
| TP-Link AX3000 | Currently doing DHCP/Gateway/AP |
| VPS/Headscale | Working |
| Beryl AX | Available as backup |

## Strategy

```
CURRENT:
[ISP Modem] → [AX3000 as Router+AP] → [Devices]
                    (keeps working while we set up)

TARGET:
[ISP Modem] → [Mini PC/OPNsense] → [Switch] → [AX3000 as AP only] → [Devices]
```

**Critical moment:** The cutover from AX3000-as-router to OPNsense. We do this LAST, when everything else is ready.

---

## Pre-Deployment Checklist (Do BEFORE Jan 24)

### Downloads (do on MacBook, save to USB)
- [ ] Proxmox VE ISO: https://www.proxmox.com/en/downloads
- [ ] OPNsense ISO: https://opnsense.org/download/ (amd64, dvd)
- [ ] Debian 12 netinst ISO: https://www.debian.org/download (for NAS)
- [ ] Ventoy (multi-boot USB): https://www.ventoy.net/

### Hardware prep - Mini PC
- [ ] Find/label all Ethernet cables needed
- [ ] Locate HDMI cable + USB keyboard for Mini PC install
- [ ] Verify Mini PC boots (enter BIOS, check dual NIC visible)
- [ ] Verify Beryl AX works (test as backup router)
- [ ] Charge phone (for tethering if things go wrong)

### Hardware prep - NAS (do BEFORE Jan 24)
- [ ] Open NAS case
- [ ] Install SSD (240GB Lexar) - boot drive
- [ ] Install WD Purple 2TB - Frigate recordings
- [ ] Install WD Red Plus 8TB - media/data
- [ ] Verify all drives detected in BIOS
- [ ] Close case, connect power + Ethernet cable ready

### Network planning
- [ ] Decide IP scheme:
  - OPNsense LAN: `192.168.1.1`
  - DHCP range: `192.168.1.100-199`
  - Docker VM: `192.168.1.10`
  - NAS (future): `192.168.1.12`
- [ ] Note current AX3000 settings (for reference)
- [ ] Note ISP modem settings (bridge mode config)

### Credentials ready
- [ ] Proxmox root password (write down)
- [ ] OPNsense admin password (write down)
- [ ] Tailscale auth key from Headscale (generate fresh)

---

## Deployment Timeline

### T-0:00 - Family Leaves, Start Clock

**Verify everything ready:**
- USB boot drive with Proxmox + OPNsense ISOs
- Keyboard, HDMI cable
- Ethernet cables
- Phone charged (backup tether)
- Beryl AX accessible

---

### Phase 1: Physical Layer (30-45 min)
*Internet stays on AX3000 during this phase*

#### 1.1 Set up MokerLink Switch
```
[ ] Unbox and power on switch
[ ] Connect to management interface (if needed)
[ ] No VLAN config needed for day 1 - just use as unmanaged
```

#### 1.2 Cable the network
```
Current (keep working):
[ISP Modem] → [AX3000 WAN port]

New cables to add:
[AX3000 LAN port] → [Switch Port 7] (trunk for AP)
[Switch Port 2] → [Mini PC NIC2/LAN]
[Switch Port 4] → [NAS] (optional, skip if NAS not ready)

Leave disconnected for now:
[ISP Modem] → [Mini PC NIC1/WAN] (connect during cutover)
```

#### 1.3 Verify switch works
```
[ ] Plug laptop into switch
[ ] Should get IP from AX3000 DHCP
[ ] Internet works through switch
```

**Checkpoint:** Switch working, cables ready. AX3000 still routing. ~45 min elapsed.

---

### Phase 2: Proxmox Install (30-45 min)
*Internet stays on AX3000 during this phase*

#### 2.1 Boot Mini PC from USB
```
[ ] Connect HDMI + keyboard to Mini PC
[ ] Insert Ventoy USB
[ ] Boot, select Proxmox ISO
[ ] Run installer
```

#### 2.2 Proxmox Installation Options
```
Target disk: 512GB SSD (entire disk)
Country/Timezone: Paraguay / America/Asuncion
Password: [your chosen password]
Email: augusto@hermosilla.me
Hostname: pve.home.local

Management Network:
- Interface: Select NIC2 (LAN side, NOT the one for WAN passthrough)
- IP: 192.168.1.5/24 (temporary, AX3000 is still .1)
- Gateway: 192.168.1.1 (AX3000)
- DNS: 192.168.1.1 (AX3000)
```

#### 2.3 Post-install access
```
[ ] Reboot Mini PC
[ ] Remove USB drive
[ ] Access Proxmox: https://192.168.1.5:8006
[ ] Login: root / [password]
```

#### 2.4 Join Tailscale (optional but recommended)
```bash
# SSH to Proxmox
ssh root@192.168.1.5

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Join mesh
tailscale up --login-server=https://hs.cronova.dev --authkey=YOUR_KEY
```

**Checkpoint:** Proxmox accessible via web UI and/or Tailscale. ~1.5 hours elapsed.

---

### Phase 3: OPNsense VM (1-1.5 hours)
*Internet stays on AX3000 during this phase*

#### 3.1 Upload OPNsense ISO to Proxmox
```
[ ] Proxmox UI → local storage → ISO Images
[ ] Upload OPNsense ISO
```

#### 3.2 Identify NICs in Proxmox
```bash
# SSH to Proxmox
ip link show

# Note which NIC is which:
# - NIC1 (for WAN passthrough): usually the Intel one
# - NIC2 (for LAN bridge): the other one
# Check with: lspci | grep -i net
```

#### 3.3 Create OPNsense VM
```
VM Settings:
- VM ID: 100
- Name: opnsense
- OS: Other (FreeBSD)
- ISO: OPNsense
- Disk: 20GB on local-lvm
- CPU: 2 cores
- RAM: 2048 MB
- Network 1: vmbr0 (LAN bridge)

For WAN, choose ONE option:

Option A - PCI Passthrough (better performance):
[ ] Proxmox → Datacenter → Host → System → IOMMU enabled
[ ] Add PCI device to VM (NIC1)
[ ] Requires reboot if IOMMU wasn't enabled

Option B - Bridge (simpler for day 1):
[ ] Create vmbr1 for WAN
[ ] Attach NIC1 to vmbr1
[ ] Add vmbr1 as second network to VM
```

#### 3.4 Install OPNsense
```
[ ] Start VM, open console
[ ] Boot from ISO
[ ] Login: installer / opnsense
[ ] Install to disk
[ ] Reboot (remove ISO from VM)
```

#### 3.5 Configure OPNsense (initial)
```
Console menu:
1) Assign interfaces
   - WAN: vtnet1 (or passthrough NIC)
   - LAN: vtnet0

2) Set interface IP
   - LAN: 192.168.1.2/24 (NOT .1 yet - AX3000 is still .1)
   - Enable DHCP: NO (AX3000 still doing DHCP)

[ ] Access OPNsense web UI: https://192.168.1.2
[ ] Login: root / opnsense
[ ] Run wizard but skip WAN config for now
```

#### 3.6 Test OPNsense routing (without cutover)
```
[ ] From laptop, set manual IP: 192.168.1.50
[ ] Set gateway: 192.168.1.2 (OPNsense)
[ ] Set DNS: 8.8.8.8 (temporary)
[ ] Test: ping google.com

If works → OPNsense routing is functional
If fails → Debug before cutover
```

**Checkpoint:** OPNsense VM running, tested routing works. ~3 hours elapsed.

---

### Phase 4: The Cutover (30 min)
*This is when internet goes down briefly*

#### 4.1 Prepare
```
[ ] Tell any family member home that internet will be down briefly
[ ] Have Beryl AX ready (just in case)
[ ] Open OPNsense console (in case web UI unreachable)
```

#### 4.2 Reconfigure OPNsense for production
```
OPNsense Console or Web UI:

[ ] Change LAN IP: 192.168.1.2 → 192.168.1.1
[ ] Enable DHCP Server:
    - Range: 192.168.1.100 - 192.168.1.199
    - DNS: 192.168.1.1 (OPNsense Unbound)
[ ] Configure WAN: DHCP (get IP from ISP modem)
```

#### 4.3 Physical cutover
```
1. [ ] Unplug ISP modem cable from AX3000 WAN port
2. [ ] Plug that cable into Mini PC NIC1 (WAN)
3. [ ] Wait 30 seconds for OPNsense to get WAN IP
4. [ ] On AX3000: Disable DHCP server, set to AP mode
       - Or just let devices get new IPs from OPNsense
```

#### 4.4 Verify internet works
```
[ ] On phone: Forget WiFi, reconnect
[ ] Should get IP from OPNsense (192.168.1.1xx)
[ ] Test: Open google.com
[ ] Test: Open youtube.com
```

#### 4.5 If it doesn't work - BACKUP PLAN
```
Option A: Debug
- Check OPNsense console for errors
- Verify WAN has IP: Interfaces → WAN
- Check firewall rules allow outbound

Option B: Rollback (5 min)
- Unplug Mini PC from ISP modem
- Plug ISP modem back into AX3000 WAN
- Internet restored (old config)
- Debug OPNsense later

Option C: Beryl AX emergency
- Follow family-emergency-internet.md
- Beryl AX becomes temporary router
```

**Checkpoint:** Internet working through OPNsense! ~3.5 hours elapsed.

---

### Phase 5: Post-Cutover (remaining time)
*Internet is working, family can come home now*

These are nice-to-have, not required for day 1:

#### 5.1 Create Docker VM (optional)
```
[ ] Create Ubuntu/Debian VM
    - 2 vCPU, 8GB RAM, 100GB disk
    - Network: vmbr0, static IP 192.168.1.10
[ ] Install Docker
[ ] Join Tailscale
```

#### 5.2 Deploy Pi-hole (optional)
```
[ ] On Docker VM
[ ] Configure OPNsense to use Pi-hole as DNS
[ ] Family gets ad-blocking
```

#### 5.3 Configure DHCP reservations (optional)
```
OPNsense → Services → DHCPv4 → LAN → Static mappings
- Docker VM: 192.168.1.10
- NAS: 192.168.1.12
```

---

### Phase 6: NAS Deployment (1.5-2 hours)
*Optional - only if Mini PC + OPNsense done in under 2.5 hours*

**Decision point after Phase 4:**
- Check time remaining
- If 1.5+ hours left AND internet stable → proceed with NAS
- If tight on time → defer NAS to another day

#### 6.1 Connect NAS to network
```
[ ] Connect NAS to Switch Port 4
[ ] Power on NAS
[ ] Move keyboard/HDMI from Mini PC to NAS
```

#### 6.2 Install Debian 12
```
[ ] Boot from Ventoy USB, select Debian ISO
[ ] Graphical install or text install

Partitioning (SSD 240GB only - will mount HDDs manually):
- /boot: 512MB (ext4)
- swap: 4GB
- /: remaining space (ext4)

DO NOT partition the Purple or Red Plus drives during install!

Network:
- Hostname: nas
- Domain: home.local
- IP: Will get DHCP initially, set static later

User:
- Root password: [your password]
- User: augusto
- User password: [your password]

Software:
- SSH server: YES
- Standard system utilities: YES
- Desktop: NO (server only)
```

#### 6.3 Post-install: Static IP
```bash
# SSH to NAS (find IP from OPNsense DHCP leases)
ssh augusto@192.168.1.1xx

# Set static IP
sudo nano /etc/network/interfaces
```

```
auto enp0s31f6  # or your interface name
iface enp0s31f6 inet static
    address 192.168.1.12
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 192.168.1.1
```

```bash
# Apply (will disconnect SSH - reconnect to .12)
sudo systemctl restart networking

# Verify
ip addr show
ping google.com
```

#### 6.4 Mount data drives
```bash
# Identify drives
lsblk
sudo blkid

# Create mount points
sudo mkdir -p /mnt/{purple,data}

# Format drives (CAREFUL - destructive!)
# Purple 2TB for Frigate
sudo mkfs.ext4 -L purple /dev/sdX

# Red Plus 8TB for data
sudo mkfs.ext4 -L data /dev/sdY

# Get UUIDs
sudo blkid | grep -E "purple|data"

# Add to fstab
sudo nano /etc/fstab
```

Add these lines:
```
UUID=<purple-uuid>  /mnt/purple  ext4  defaults,noatime  0  2
UUID=<data-uuid>    /mnt/data    ext4  defaults,noatime  0  2
```

```bash
# Mount all
sudo mount -a

# Verify
df -h
```

#### 6.5 Create Frigate directory
```bash
# Create directory for Frigate recordings
sudo mkdir -p /mnt/purple/frigate
sudo chown -R 1000:1000 /mnt/purple/frigate
sudo chmod 755 /mnt/purple/frigate
```

#### 6.6 Install and configure NFS
```bash
# Install NFS server
sudo apt update
sudo apt install -y nfs-kernel-server

# Create export symlink
sudo mkdir -p /srv/frigate
sudo ln -s /mnt/purple/frigate /srv/frigate

# Configure export (for Docker VM)
echo '/srv/frigate 192.168.1.10(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports

# Apply exports
sudo exportfs -ra

# Verify
sudo exportfs -v

# Enable and start NFS
sudo systemctl enable nfs-kernel-server
sudo systemctl start nfs-kernel-server
```

#### 6.7 Test NFS from Docker VM (if created)
```bash
# SSH to Docker VM
ssh user@192.168.1.10

# Install NFS client
sudo apt update
sudo apt install -y nfs-common

# Create mount point
sudo mkdir -p /mnt/nas/frigate

# Test mount
sudo mount -t nfs 192.168.1.12:/srv/frigate /mnt/nas/frigate

# Verify
df -h /mnt/nas/frigate

# Test write
touch /mnt/nas/frigate/test.txt
rm /mnt/nas/frigate/test.txt

# Add to fstab for persistence
echo '192.168.1.12:/srv/frigate  /mnt/nas/frigate  nfs  defaults,_netdev,nofail  0  0' | sudo tee -a /etc/fstab
```

#### 6.8 Join NAS to Tailscale (optional)
```bash
# On NAS
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --login-server=https://hs.cronova.dev --authkey=YOUR_KEY
```

**Checkpoint:** NAS running, NFS exporting, Docker VM can mount. ~5-5.5 hours total.

---

## Day 1 Success Criteria

**Minimum (must have):**
- [ ] Internet works through OPNsense
- [ ] Family devices can browse/stream
- [ ] OPNsense accessible for management

**Nice to have (if time permits):**
- [ ] Docker VM created
- [ ] Pi-hole running (ad-blocking)
- [ ] Tailscale working on Proxmox
- [ ] NAS running with Debian
- [ ] NFS export configured for Frigate

**Defer to later:**
- Frigate deployment + cameras
- Home Assistant
- Media stack (*arr, Jellyfin)
- Full backup automation
- Start9 on RPi 4

---

## Post-Deployment Tasks (after Jan 24)

*Skip NAS tasks if completed on Day 1*

| Task | Priority | Notes |
|------|----------|-------|
| Install Debian on NAS | High | Skip if done Day 1 |
| Set up NFS export for Frigate | High | Skip if done Day 1 |
| Deploy Frigate on Docker VM | High | Needs NFS ready |
| Configure cameras in Frigate | High | After Frigate deployed |
| Deploy Pi-hole (if not done) | Medium | Ad-blocking |
| Deploy Mosquitto + Home Assistant | Medium | Automation |
| Deploy media stack (*arr, Jellyfin) | Medium | Entertainment |
| Configure VLANs for IoT | Medium | Camera isolation |
| Configure UPS/NUT | Low | Graceful shutdown |
| Set up backup automation | Low | Restic to NAS + cloud |
| Start9 on RPi 4 | Low | Bitcoin node |

---

## Emergency Contacts During Deployment

| Issue | Action |
|-------|--------|
| Can't boot Proxmox | Check USB, try different USB port |
| No network after Proxmox | Check NIC assignment, cables |
| OPNsense no WAN IP | Check ISP modem bridge mode, try reboot modem |
| Family needs internet NOW | Use Beryl AX (see family-emergency-internet.md) |
| Something else broke | Rollback: ISP modem → AX3000 → devices |

---

## Quick Reference: Key IPs

| Device | IP | Role |
|--------|-----|------|
| OPNsense LAN | 192.168.1.1 | Gateway, DHCP, DNS |
| AX3000 (AP mode) | 192.168.1.2 | WiFi only |
| Proxmox | 192.168.1.5 | Hypervisor management |
| Docker VM | 192.168.1.10 | Container host |
| NAS | 192.168.1.12 | Storage, NFS server |
| DHCP range | .100-.199 | Client devices |

---

*Plan created: 2026-01-21*
*Deployment date: 2026-01-24*
