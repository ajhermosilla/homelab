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
- [ ] Ventoy (multi-boot USB): https://www.ventoy.net/

### Hardware prep
- [ ] Find/label all Ethernet cables needed
- [ ] Locate HDMI cable + USB keyboard for Mini PC install
- [ ] Verify Mini PC boots (enter BIOS, check dual NIC visible)
- [ ] Verify Beryl AX works (test as backup router)
- [ ] Charge phone (for tethering if things go wrong)

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
- NAS (future): 192.168.1.12
```

---

## Day 1 Success Criteria

**Minimum (must have):**
- [ ] Internet works through OPNsense
- [ ] Family devices can browse/stream
- [ ] OPNsense accessible for management

**Nice to have:**
- [ ] Docker VM created
- [ ] Pi-hole running (ad-blocking)
- [ ] Tailscale working on Proxmox

**Defer to later:**
- NAS setup
- Frigate/cameras
- Home Assistant
- Media stack
- Backups

---

## Post-Deployment Tasks (after Jan 24)

| Task | Priority |
|------|----------|
| Install Debian on NAS | High |
| Set up NFS export for Frigate | High |
| Deploy full Docker stack | Medium |
| Configure VLANs for IoT | Medium |
| Set up cameras in Frigate | Medium |
| Configure UPS/NUT | Low |
| Start9 on RPi 4 | Low |

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
| Proxmox | 192.168.1.5 | Hypervisor management |
| Docker VM | 192.168.1.10 | Container host |
| AX3000 (AP mode) | 192.168.1.2 | WiFi only |
| DHCP range | .100-.199 | Client devices |

---

*Plan created: 2026-01-21*
*Deployment date: 2026-01-24*
