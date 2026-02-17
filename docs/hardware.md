# Hardware Inventory

## Overview

```
[Mobile Kit - On Demand]        [Fixed Homelab - 24/7]          [VPS - 24/7]
├── MacBook Air M1             ├── Mini PC (Proxmox)           ├── Headscale
├── Beryl AX Router            ├── RPi 5 (OpenClaw)            ├── Caddy
└── Samsung A13                ├── RPi 4 (Start9)              ├── Uptime Kuma
                               ├── NAS (DIY Mini-ITX)          ├── ntfy
                               ├── MokerLink 2.5G Switch       └── ~$6/mo
                               ├── TP-Link PoE Switch
                               ├── TP-Link Archer AX50 AP
                               ├── 3x IP Cameras
                               └── Forza UPS
```

---

## Mobile Homelab (On-Demand)

Portable infrastructure. Operates 7AM-7PM or when traveling. Not 24/7.

| Device | Specs | Role | Status |
|--------|-------|------|--------|
| MacBook Air M1 | 16GB RAM, 1TB SSD, macOS Sonoma | Workstation, soft-serve, Docker dev | Active |
| Beryl AX | GL-MT3000 | Network gateway, DHCP, VPN, AdGuard DNS | Active |
| Samsung A13 | Android | USB tethering for internet | Active |

### Mobile Network Topology

```
            [Internet]
                 |
          [Mobile Phone]
           USB Tether
                 |
         [Travel Router]
                 |
          [MacBook Air]
                 |
        [Tailscale Mesh]
```

### Mobile Kit Services

| Device | Services |
|--------|----------|
| Beryl AX | AdGuard DNS (mobile ad-blocking) |
| MacBook | soft-serve, Docker workloads |

*Note: Headscale moved to VPS for 24/7 availability.*

---

## Fixed Homelab

Always-on infrastructure at home.

### Core Devices

| Device | Specs | Role | Status |
|--------|-------|------|--------|
| Mini PC | Intel N150, 12GB RAM, 512GB SSD | Proxmox VE (OPNsense + Docker VM) | Active |
| Raspberry Pi 5 | 8GB RAM, 32GB SD, Active Cooler | OpenClaw (AI assistant) | Pending setup |
| Raspberry Pi 4 | 4GB RAM, 1TB external SSD | Start9 (Bitcoin node) | Pending setup |
| NAS | i3-3220T, 8GB RAM, Mini-ITX | Debian (Frigate, Samba, Syncthing) | Pending setup |

### Networking

| Device | Model | Specs | Role |
|--------|-------|-------|------|
| Managed Switch | MokerLink 8-Port | 8x 2.5G + 10G SFP+, fanless, metal | Main LAN backbone |
| PoE Switch | TP-Link TL-SG1005P | 5x 1G, 4x PoE+ @65W, fanless | Camera power |
| Access Point | TP-Link Archer AX50 | WiFi 6, Dual Band, Gigabit | AP mode (stock firmware) |

### Cameras

| Model | Count | Specs | Status |
|-------|-------|-------|--------|
| Reolink RLC-520A | 2 | 5MP PoE | New in box |
| TP-Link Tapo C110 | 1 | 3MP WiFi | New |

### Power

| Device | Model | Specs |
|--------|-------|-------|
| UPS | Forza NT-1012U | 1000VA, 220V |

### Cooling

| Device | Model | Notes |
|--------|-------|-------|
| USB Fans | AC Infinity MULTIFAN S7 | Dual 120mm, for NAS/switch cooling |

### Mini PC Details

| Component | Spec | Notes |
|-----------|------|-------|
| Model | Aoostar N1 Pro | |
| CPU | Intel N150 | VT-x for virtualization |
| RAM | 12GB | ~1GB host + 2GB OPNsense + 9GB Docker |
| Storage | 512GB SSD | Proxmox + VMs |
| NIC | Dual port required | WAN bridge (vmbr0) + LAN bridge (vmbr1) |
| BIOS | Restore on AC Power Loss | Set to "Power On" for auto-boot |

**VMs:**
| VM | ID | vCPU | RAM | Disk | Start Order |
|----|-----|------|-----|------|-------------|
| OPNsense | 100 | 2 | 2GB | 20GB | 1 (delay: 0) |
| Docker | 101 | 2 | 9GB | 100GB | 2 (delay: 30) |

- **OPNsense** - Router/firewall
- **Docker** - Pi-hole, Jellyfin, Frigate, Home Assistant, *arr stack, etc.

### RPi 5 Details

| Component | Model | Notes |
|-----------|-------|-------|
| Board | Raspberry Pi 5 8GB | OpenClaw AI assistant |
| Storage | 32GB SDHC Class 10 | Consider NVMe HAT later |
| Cooling | Official Active Cooler | Required for 24/7 operation |
| PSU | Official 27W USB-C | In transit (Miami → Asunción) |
| Case | TBD | See `docs/rpi5-case-research.md` |

### RPi 4 Details

| Component | Spec | Notes |
|-----------|------|-------|
| Board | Raspberry Pi 4 4GB | Bitcoin node |
| Storage | 1TB external SSD (USB 3.0) | Blockchain + indexes |
| OS | Start9 OS | Sovereign Bitcoin stack |
| PSU | Official 3A USB-C | Required for SSD power |

**Start9 Services:**
- Bitcoin Core (~600GB)
- LND (Lightning)
- Electrum Server (~50GB index)

### NAS Details

DIY Mini-ITX build from 2013, repurposed for NAS duty.

| Component | Model | Notes |
|-----------|-------|-------|
| Case | Cooler Master Elite 120 Advanced | Mini-ITX, compact |
| Motherboard | ASUS P8H77-I | Intel H77, LGA 1155 |
| CPU | Intel Core i3-3220T | Dual-Core 2.8GHz, 35W TDP |
| RAM | Kingston HyperX 8GB | 2x4GB DDR3-1600 |
| PSU | picoPSU-160-XT + 220W brick | 192W DC-DC, 2013 vintage |
| OS | Debian 12 | Docker, no mergerfs/snapraid initially |

**NAS Services:**
- Samba (network shares)
- Syncthing (file sync)
- Restic REST (backup target)
- NFS (exports Purple 2TB for Frigate on Docker VM)

### NAS Storage Strategy

```
┌─────────────────────────────────────────────────────────┐
│                    NAS (Primary)                         │
│ SSD 240GB│ Purple 2TB │ Red Plus 8TB                    │
│  OS/Apps │ Frigate    │ Media + Data                    │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┴───────────────┐
          ▼                               ▼
   [Local Backup]                  [Offsite Backup]
   WD Red 3TB                      Google Drive 1TB
   Sabrent Dock                    (rclone + crypt)
```

**Internal Drives:**

| Drive | Model | Size | Purpose |
|-------|-------|------|---------|
| SSD | Lexar NQ110 | 240GB | Debian OS, Docker, configs (boot) |
| HDD | WD Purple | 2TB | Frigate NVR recordings (dedicated) |
| HDD | WD Red Plus (WD80EFBX) | 8TB | Media, family backups, service backups |

**Backup Targets:**

| Target | Size | Purpose | Notes |
|--------|------|---------|-------|
| WD Red 3TB | 3TB | Local critical backup | In Sabrent dock, 2013 drive |
| Google Drive | 1TB | Offsite critical backup | Via rclone crypt, part of AI Pro sub |

**Retired/Spare Drives:**

| Drive | Size | Age | Status |
|-------|------|-----|--------|
| Crucial MX500 | 1TB | 2021? | Spare - available for future use |
| WD Red 3TB (2nd) | 3TB | 2013 | Test with SMART, keep as spare |

**Strategy Notes:**
- No SnapRAID parity initially (would need 8TB+ drive)
- 3-2-1 backup: NAS + local 3TB + Google Drive
- Purple dedicated to Frigate = optimized surveillance writes
- Consider 8TB parity + 8TB external upgrade later

### Fixed Network Topology

```
                      [ISP Modem]
                           |
                     [Mini PC - Proxmox]
                           |
                    [OPNsense VM - WAN]
                           |
                  [Managed 2.5G Switch]
                           |
     +----------+----------+-----------+----------+-----------+
     |          |          |           |          |           |
[Docker VM] [RPi 5]  [Bitcoin]   [NAS]    [WiFi AP]  [PoE Switch]
           OpenClaw    Node                              |
                                          +----+----+
                                          |         |
                                     [PoE Cam]  [PoE Cam]

                    [Tailscale Mesh]
```

### Fixed Homelab Services

| Device | Services |
|--------|----------|
| Docker VM | Pi-hole, Caddy, Jellyfin, *arr stack, Home Assistant, Vaultwarden, Mosquitto, Frigate |
| RPi 5 | OpenClaw (AI assistant) |
| RPi 4 | Bitcoin Core, LND, Electrum Server (Start9) |
| NAS | NFS (for Frigate), Samba, Syncthing, Restic REST |

*Frigate runs on Docker VM (Intel N150 QuickSync) with NFS mount to NAS Purple 2TB for recordings.*

---

## VPS

Cloud helper node (not critical infrastructure).

| Provider | Plan | Specs | Cost |
|----------|------|-------|------|
| Vultr | High Frequency | 1 vCPU, 1GB RAM, 32GB NVMe | ~$6/mo |

**Services (active):** Headscale, Caddy, Uptime Kuma, ntfy | **Planned:** DERP relay, changedetection, Restic REST

**See:** `docs/vps-architecture.md`

---

## Tailscale IP Allocation

### IP Ranges

| Range | Purpose |
|-------|---------|
| x.x.x.1-9 | Mobile devices |
| x.x.x.10-19 | Fixed homelab servers |
| x.x.x.20-29 | Client devices |
| x.x.x.100-109 | Cloud/VPS |
| x.x.x.200-254 | Reserved |

### Allocation Strategy

Devices are organized by role:
- **Mobile**: Phones, laptops, portable devices
- **Fixed**: Servers, NAS, infrastructure
- **Clients**: Family desktops, media devices
- **Cloud**: VPS and external infrastructure

*Actual allocations managed in Headscale admin.*

### Hostname Convention

```
<device-type>[-owner]

Examples:
- rpi5 (device type only)
- phone-user (device + owner)
- laptop-user (device + owner)
```

### MagicDNS

Tailscale MagicDNS provides automatic DNS:

```
<hostname>.tail → Tailscale IP
```

### ACL Policy (Headscale)

```yaml
# Example ACL structure - customize for your needs

groups:
  servers:
    - docker
    - nas
    - vps
    # Add server hostnames

  users:
    - phone-*
    - laptop-*
    # Add user device patterns

acls:
  # Servers can reach each other
  - action: accept
    src: ["group:servers"]
    dst: ["group:servers:*"]

  # Users can reach servers
  - action: accept
    src: ["group:users"]
    dst: ["group:servers:*"]
```

### Adding New Devices

1. Generate auth key in Headscale
2. Install Tailscale on device
3. Connect with: `tailscale up --login-server=https://<your-domain> --authkey=<key>`
4. Assign IP from appropriate range
5. Update internal documentation

---

## Power Considerations

### Mobile Kit

| Device | Power | Notes |
|--------|-------|-------|
| Beryl AX | 15W USB-C | Can share power bank |
| MacBook | Battery | 15+ hours |

### Fixed Homelab

All critical devices connected to Forza NT-1012U 1000VA UPS.

| Device | Power | UPS Protected |
|--------|-------|---------------|
| Mini PC | ~35W | Yes |
| RPi 5 | 27W | Yes |
| RPi 4 | 15W | Yes |
| NAS | ~50W idle | Yes |
| MokerLink Switch | ~15W | Yes |
| TP-Link PoE Switch | ~65W max | Yes (cameras need graceful stop) |

**Total estimated load:** ~180W (well under 1000VA capacity)

**See:** `docs/nut-config.md` for NUT graceful shutdown configuration

---

## Accessories

| Item | Model | Purpose |
|------|-------|---------|
| Keyboard | Keychron K2C3 | 75% mechanical keyboard, home workstation |
| Keyboard | Logitech MX Keys for Mac | Full-size, stationary at T&C office |
| Mouse | Logitech MX Master 3 | Wireless, portable, mainly with MacBook Air M1 |
| Flash Drive | Lexar D40E 128GB | USB-C/USB-A dual, portable transfers |
| Card Reader | UGREEN SD/MicroSD | USB-C/USB 3.0, for RPi SD cards |
| USB-C Cables | UGREEN 100W 6.6ft (2-pack) | Device charging/data |
| HDD Dock | Sabrent EC-DFLT | USB 3.0 SATA dock for backup drives |
| YubiKey | 5C NFC | 2FA hardware key (USB-C + NFC) |
| E-Reader | Kindle Paperwhite (2018) | Waterproof, 8GB, ad-supported |

---

## Purchase History

| Item | Date | Status |
|------|------|--------|
| RPi 5 8GB + Active Cooler | 2026-01 | Owned |
| RPi 5 27W PSU | 2026-01 | In transit |
| 32GB SD Card | 2026-01 | Owned |
| Mini PC (N150) | ? | Owned |
| RPi 4 4GB | ? | Owned |
| NAS components | 2013 | Owned |
| Kindle Paperwhite (2018) | 2020 | Owned |
| YubiKey 5C NFC | 2021 | Owned |
| Keychron K2C3 | 2021 | Owned |
| Logitech MX Master 3 | 2021 | Owned |
| WD Red Plus 8TB | 2021 | Owned |
| Sabrent HDD Dock | 2021 | Owned |
| TP-Link Archer AX50 AP | 2021 | Owned |
| Logitech MX Keys for Mac | 2023 | Owned (at T&C office) |
| WD Purple 2TB | 2026 | Owned |
| MokerLink 2.5G Switch | 2026 | Owned |
| TP-Link PoE Switch | 2026 | Owned |
| Forza UPS 1000VA | 2026 | Owned |
| Reolink RLC-520A (x2) | 2026 | New in box |
| TP-Link Tapo C110 | 2026 | New |
| AC Infinity Fans | 2026 | Owned |

---

## Future Hardware

| Item | Purpose | Priority |
|------|---------|----------|
| NVMe HAT for RPi 5 | Faster storage | Low |
| Coral USB TPU | Frigate ML acceleration (Mini PC) | Medium |
| 8TB HDD (parity) | SnapRAID parity drive | Low |
| 8TB HDD (external) | Larger local backup | Low |
| 3D printed case | RPi 5 enclosure | Medium |
| New NAS PSU | Replace 2013 PSU if needed | Medium |

---

## References

- [Raspberry Pi 5 Specs](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [GL-MT3000 (Beryl AX)](https://www.gl-inet.com/products/gl-mt3000/)
- [Start9 Hardware Requirements](https://docs.start9.com/)
- [Proxmox VE Requirements](https://www.proxmox.com/en/proxmox-ve)
- [Frigate NVR](https://frigate.video/)
- [rclone crypt](https://rclone.org/crypt/)
