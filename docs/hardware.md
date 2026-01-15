# Hardware Inventory

## Overview

```
[Mobile Kit]                    [Fixed Homelab]                 [VPS]
├── RPi 5 (Headscale)          ├── Mini PC (Proxmox)           └── Vultr US
├── MacBook Air M1             ├── RPi 4 (Start9)                  ~$6/mo
├── Beryl AX Router            ├── NAS (DIY Mini-ITX)
└── Samsung A13                ├── MokerLink 2.5G Switch
                               ├── TP-Link PoE Switch
                               ├── 3x IP Cameras
                               └── Forza UPS
```

---

## Mobile Homelab

Portable, self-contained infrastructure. Carry your mesh in your backpack.

| Device | Specs | Role | Status |
|--------|-------|------|--------|
| Raspberry Pi 5 | 8GB RAM, 32GB SD, Active Cooler | **Headscale (PRIMARY)** + Pi-hole | PSU in transit |
| MacBook Air M1 | 16GB RAM, 1TB SSD, macOS Sonoma | Workstation, soft-serve, Docker dev | Active |
| Beryl AX | GL-MT3000 | Network gateway, DHCP, VPN | Active |
| Samsung A13 | Android | USB tethering for internet | Active |

### RPi 5 Details

| Component | Model | Notes |
|-----------|-------|-------|
| Board | Raspberry Pi 5 8GB | Primary coordination server |
| Storage | 32GB SDHC Class 10 | Consider NVMe HAT later |
| Cooling | Official Active Cooler | Required for 24/7 operation |
| PSU | Official 27W USB-C | In transit (Miami → Asunción) |
| Case | TBD | See `docs/rpi5-case-research.md` |

### Mobile Network Topology

```
            [Internet]
                 |
          [Samsung A13]
           USB Tether
                 |
         [Beryl AX Router]
          192.168.8.1
           /         \
          /           \
   [MacBook Air]    [RPi 5]
   192.168.8.10    192.168.8.5
         \           /
          \         /
        [Tailscale Mesh]
         100.64.0.1-2
```

### Mobile Kit Services

| Device | Services |
|--------|----------|
| RPi 5 | Headscale, Pi-hole |
| MacBook | soft-serve, Docker workloads |

---

## Fixed Homelab

Always-on infrastructure at home.

### Core Devices

| Device | Specs | Role | Status |
|--------|-------|------|--------|
| Mini PC | Intel N150, 12GB RAM, 512GB SSD | Proxmox VE (OPNsense + Docker VM) | Pending setup |
| Raspberry Pi 4 | 4GB RAM, 1TB external SSD | Start9 (Bitcoin node) | Pending setup |
| NAS | i3-3220T, 8GB RAM, Mini-ITX | Debian (Frigate, Samba, Syncthing) | Pending setup |

### Networking

| Device | Model | Specs | Role |
|--------|-------|-------|------|
| Managed Switch | MokerLink 8-Port | 8x 2.5G + 10G SFP+, fanless, metal | Main LAN backbone |
| PoE Switch | TP-Link TL-SG1005P | 5x 1G, 4x PoE+ @65W, fanless | Camera power |

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
| CPU | Intel N150 | VT-x/VT-d for passthrough |
| RAM | 12GB | 2GB OPNsense + 8GB Docker VM |
| Storage | 512GB SSD | Proxmox + VMs |
| NIC | Dual port required | WAN passthrough + LAN bridge |

**VMs:**
- OPNsense (2 vCPU, 2GB RAM) - Router/firewall
- Docker Host (2 vCPU, 8GB RAM) - All containers

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
| PSU | TBD (2013) | Solid state, verify model |
| OS | Debian 12 | Docker, no mergerfs/snapraid initially |

**NAS Services:**
- Frigate (NVR)
- Samba (network shares)
- Syncthing (file sync)
- Restic REST (backup target)

### NAS Storage Strategy

```
┌─────────────────────────────────────────────────────────┐
│                    NAS (Primary)                         │
│  SSD 1TB │ Purple 2TB │ Red Plus 8TB                    │
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
| SSD | Crucial MX500 | 1TB | Debian OS, Docker, configs |
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
                  [MokerLink 2.5G Switch]
                    8x 2.5G + 10G SFP+
                           |
         +-----------------+-----------------+
         |                 |                 |
    [Docker VM]        [RPi 4]            [NAS]
    192.168.1.10      192.168.1.11      192.168.1.12
         |                                   |
         |                          [TP-Link PoE Switch]
         |                            4x PoE+ @65W
         |                                   |
         |                 +-----------------+-----------------+
         |                 |                 |                 |
         |           [RLC-520A]        [RLC-520A]        [Tapo C110]
         |            Camera 1          Camera 2          Camera 3
         |
         +-----------------+-----------------+
                           |
                    [Tailscale Mesh]
                     100.64.0.10-12
```

### Fixed Homelab Services

| Device | Services |
|--------|----------|
| Docker VM | Pi-hole, Caddy, Jellyfin, *arr stack, Home Assistant, Vaultwarden, Mosquitto |
| RPi 4 | Bitcoin Core, LND, Electrum Server (Start9) |
| NAS | Frigate, Samba, Syncthing, Restic REST |

---

## VPS

Cloud helper node (not critical infrastructure).

| Provider | Plan | Specs | Cost |
|----------|------|-------|------|
| Vultr | High Frequency | 1 vCPU, 1GB RAM, 32GB NVMe | ~$6/mo |

**Services:** DERP relay, Pi-hole, Uptime Kuma, ntfy, changedetection, Restic REST

**See:** `docs/vps-architecture.md`

---

## Tailscale IP Allocation

| Device | Tailscale IP | Hostname | Environment |
|--------|--------------|----------|-------------|
| RPi 5 | 100.64.0.1 | rpi5 | Mobile |
| MacBook Air | 100.64.0.2 | macbook | Mobile |
| Mini PC | 100.64.0.10 | minipc | Fixed |
| RPi 4 | 100.64.0.11 | rpi4 | Fixed |
| NAS | 100.64.0.12 | nas | Fixed |
| VPS | 100.64.0.100 | vps | Cloud |

*IPs assigned by Headscale on RPi 5.*

---

## Power Considerations

### Mobile Kit

| Device | Power | Notes |
|--------|-------|-------|
| RPi 5 | 27W USB-C | Official PSU required |
| Beryl AX | 15W USB-C | Can share power bank |
| MacBook | Battery | 15+ hours |

**Future:** USB-C power bank for RPi 5 + Beryl AX

### Fixed Homelab

All critical devices connected to Forza NT-1012U 1000VA UPS.

| Device | Power | UPS Protected |
|--------|-------|---------------|
| Mini PC | ~35W | Yes |
| RPi 4 | 15W | Yes |
| NAS | ~50W idle | Yes |
| MokerLink Switch | ~15W | Yes |
| TP-Link PoE Switch | ~65W max | Yes (cameras need graceful stop) |

**Total estimated load:** ~180W (well under 1000VA capacity)

**TODO:** Configure NUT for graceful shutdown on power loss

---

## Accessories

| Item | Model | Purpose |
|------|-------|---------|
| Flash Drive | Lexar D40E 128GB | USB-C/USB-A dual, portable transfers |
| Card Reader | UGREEN SD/MicroSD | USB-C/USB 3.0, for RPi SD cards |
| USB-C Cables | UGREEN 100W 6.6ft (2-pack) | Device charging/data |
| SSD (spare) | Lexar NQ110 240GB SATA | Spare/testing |
| HDD Dock | Sabrent EC-DFLT | USB 3.0 SATA dock for backup drives |

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
| WD Red Plus 8TB | 2021 | Owned |
| WD Purple 2TB | 2026 | Owned |
| Sabrent HDD Dock | 2021 | Owned |
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
| Coral USB TPU | Frigate ML acceleration | Medium |
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
