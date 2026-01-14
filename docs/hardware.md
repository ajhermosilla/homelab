# Hardware Inventory

## Overview

```
[Mobile Kit]                    [Fixed Homelab]                 [VPS]
├── RPi 5 (Headscale)          ├── Mini PC (Proxmox)           └── Vultr US
├── MacBook Air M1             ├── RPi 4 (Start9)                  ~$6/mo
├── Beryl AX Router            └── Old PC (NAS)
└── Samsung A13
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

| Device | Specs | Role | Status |
|--------|-------|------|--------|
| Mini PC | Intel N150, 12GB RAM, 512GB SSD | Proxmox VE (OPNsense + Docker VM) | Pending setup |
| Raspberry Pi 4 | 4GB RAM, 1TB external SSD | Start9 (Bitcoin node) | Pending setup |
| Old PC | TBD | NAS (Debian, mergerfs, Frigate) | Pending specs |

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

### Old PC / NAS Details

| Component | Spec | Notes |
|-----------|------|-------|
| CPU | TBD | Document when convenient |
| RAM | TBD | |
| Storage 1 | WD Nighthawk 2TB | Frigate NVR recordings |
| Storage 2 | WD Red 6TB | Media + family backups |
| OS | Debian 12 | mergerfs + snapraid |

**NAS Services:**
- Samba (network shares)
- Syncthing (file sync)
- Frigate (NVR)
- Restic REST (backup target)

### Fixed Network Topology

```
                      [ISP Modem]
                           |
                     [Mini PC - Proxmox]
                           |
                    [OPNsense VM - WAN]
                           |
                    [vmbr0 - LAN Bridge]
                           |
         +-----------------+-----------------+
         |                 |                 |
    [Docker VM]        [RPi 4]          [Old PC/NAS]
    192.168.1.10      192.168.1.11      192.168.1.12
         |                 |                 |
         +-----------------+-----------------+
                           |
                    [Tailscale Mesh]
                     100.64.0.10-12
```

### Fixed Homelab Services

| Device | Services |
|--------|----------|
| Docker VM | Pi-hole, Caddy, Jellyfin, *arr stack, Home Assistant, Vaultwarden |
| RPi 4 | Bitcoin Core, LND, Electrum Server (Start9) |
| NAS | Samba, Syncthing, Frigate, Restic REST |

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

| Device | Power | Notes |
|--------|-------|-------|
| Mini PC | ~35W | UPS recommended |
| RPi 4 | 15W | UPS recommended |
| Old PC/NAS | ~50W idle | UPS recommended |

**Future:** UPS with graceful shutdown scripts

---

## Purchase History

| Item | Date | Source | Status |
|------|------|--------|--------|
| RPi 5 8GB | 2026-01 | ? | Owned |
| RPi 5 Active Cooler | 2026-01 | ? | Owned |
| RPi 5 27W PSU | 2026-01 | Miami | In transit |
| 32GB SD Card | 2026-01 | ? | Owned |
| Mini PC | ? | ? | Owned |
| RPi 4 4GB | ? | ? | Owned |
| 1TB SSD (RPi 4) | ? | ? | TBD |

---

## Future Hardware

| Item | Purpose | Priority |
|------|---------|----------|
| NVMe HAT for RPi 5 | Faster storage | Low |
| Coral USB TPU | Frigate ML acceleration | Medium |
| UPS | Power protection | Medium |
| Second NIC for Mini PC | If not dual-port | High (if needed) |
| 3D printed case | RPi 5 enclosure | Medium |

---

## References

- [Raspberry Pi 5 Specs](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [GL-MT3000 (Beryl AX)](https://www.gl-inet.com/products/gl-mt3000/)
- [Start9 Hardware Requirements](https://docs.start9.com/)
- [Proxmox VE Requirements](https://www.proxmox.com/en/proxmox-ve)
