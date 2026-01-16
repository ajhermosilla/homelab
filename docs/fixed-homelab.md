# Fixed Homelab Architecture

Always-on infrastructure at home for media, automation, storage, and Bitcoin sovereignty.

## Hardware

*Full specifications in `docs/hardware.md`*

| Device | Specs | Role | Status |
|--------|-------|------|--------|
| Mini PC | Intel N150, 12GB RAM, 512GB SSD | Proxmox VE (OPNsense + Docker VM) | Pending setup |
| Raspberry Pi 4 | 4GB RAM, 1TB external SSD | Start9 (Bitcoin node) | Pending setup |
| NAS | i3-3220T, 8GB RAM, Mini-ITX | Debian (Frigate, Samba, Syncthing) | Pending setup |
| MokerLink Switch | 8x 2.5G + 10G SFP+ | Main LAN backbone | Owned |
| TP-Link PoE Switch | 5x 1G, 4x PoE+ @65W | Camera power | Owned |
| Forza UPS | NT-1012U 1000VA, 220V | Power protection | Owned |

### WiFi

| Device | Model | Specs | Role |
|--------|-------|-------|------|
| Access Point | TP-Link AX3000 | WiFi 6, Dual Band, Gigabit | AP mode (stock firmware) |

*Connected to MokerLink switch, provides WiFi for devices and Tapo camera.*

### Cameras

| Model | Count | Specs | Connection |
|-------|-------|-------|------------|
| Reolink RLC-520A | 2 | 5MP PoE | TP-Link PoE Switch |
| TP-Link Tapo C110 | 1 | 3MP WiFi | AX3000 AP (WiFi) |

## Architecture Diagram

```
                           [ISP Modem]
                                │
                    ┌───────────┴───────────┐
                    │   Mini PC (Proxmox)   │
                    │   NIC1: WAN → ISP     │
                    │   NIC2: LAN → Switch  │
                    └───────────┬───────────┘
                                │
                          VLAN Trunk (1,10,20)
                                │
                    ┌───────────┴───────────┐
                    │  MokerLink 2.5G Switch │
                    │     8x 2.5G Ports      │
                    └───────────┬───────────┘
                                │
    ┌────────┬────────┬────────┼────────┬────────┬────────┬────────┐
    │        │        │        │        │        │        │        │
  Port 1   Port 2   Port 3   Port 4   Port 5   Port 6   Port 7   Port 8
  Trunk    Access   Access   Access   Access   Access   Trunk    Access
 1,10,20   VLAN 1   VLAN 1   VLAN 1   VLAN 1   VLAN 10  1,10,20  VLAN 1
    │        │        │        │        │        │        │        │
 [Mini PC] [Docker] [RPi 4]  [NAS]  [Yamaha]  [PoE   [TP-Link] [Reserved]
 OPNsense    VM     Start9          RX-V671  Switch]   AP       MacBook
              │       │        │        │        │        │
            .10      .11      .12      .30      │      SSIDs:
                                                │   ┌──────────┐
                                     ┌──────────┘   │ HomeNet ─┼─► VLAN 1
                                     │              │ IoT ─────┼─► VLAN 10
                               ┌─────┴─────┐        │ Guest ───┼─► VLAN 20
                               │ PoE Switch│        └──────────┘
                               │TL-SG1005P │             │
                               └─────┬─────┘        WiFi Clients:
                                     │              ┌────┴────┐
                               ┌─────┴─────┐        │         │
                               │           │    [Apple TV] [LG TV]
                            [Cam 1]    [Cam 2]     .31       .32
                             .101       .102     (HomeNet) (HomeNet)
                                                      │
                                                [Tapo C110]
                                                   .103
                                                (IoT SSID)

                         [Tailscale Mesh - 100.64.0.x]
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
              [Mobile Kit]     [Fixed Homelab]    [VPS - US]
              RPi 5 + MacBook  .10, .11, .12     100.64.0.100
              100.64.0.1-2
```

### MokerLink Port Assignment

| Port | Mode | VLAN | Device | Speed |
|------|------|------|--------|-------|
| 1 | Trunk | 1,10,20 | Mini PC (OPNsense) | 2.5G |
| 2 | Access | 1 | Docker VM | 2.5G |
| 3 | Access | 1 | RPi 4 (Start9) | 1G |
| 4 | Access | 1 | NAS | 2.5G |
| 5 | Access | 1 | Yamaha RX-V671 | 1G |
| 6 | Access | 10 | PoE Switch (Cameras) | 1G |
| 7 | Trunk | 1,10,20 | TP-Link AP | 1G |
| 8 | Access | 1 | Reserved (MacBook) | 2.5G |

### Entertainment Devices

| Device | Connection | IP | VLAN |
|--------|------------|-----|------|
| Yamaha RX-V671 | Ethernet (Port 5) | .30 | 1 |
| Apple TV 4th Gen | WiFi (HomeNet) | .31 | 1 |
| LG Smart TV | WiFi (HomeNet) | .32 | 1 |
| Tapo C110 | WiFi (IoT) | .103 | 10 |

## Mini PC - Proxmox VE Hypervisor

Virtualization host running network gateway and Docker services.

### Hardware Requirements

- Dual NIC (WAN + LAN)
- Intel N150, 12GB RAM, 512GB SSD
- VT-x/VT-d enabled for passthrough

### VM Architecture

```
[Proxmox VE - Mini PC]
├── OPNsense VM (Router/Firewall)
│   ├── WAN: NIC1 (passthrough) → ISP
│   ├── LAN: vmbr0 → Internal network
│   └── Resources: 2 vCPU, 2GB RAM
│
└── Docker Host VM (Ubuntu/Debian)
    ├── Network: vmbr0 (LAN)
    ├── Resources: 2 vCPU, 8GB RAM, 400GB disk
    └── Services: All containers
```

### Network Flow

```
[ISP Modem]
     |
[NIC1 - WAN] ──passthrough──→ [OPNsense VM]
                                    |
                              [vmbr0 - LAN]
                                    |
              +─────────────────────+─────────────────────+
              |                     |                     |
       [Docker Host VM]        [RPi 4]              [NAS]
        192.168.1.10         192.168.1.11          192.168.1.12
              |                                          |
    +---------+---------+---------+              +-------+-------+
    |         |         |         |              |       |       |
[Pi-hole] [Caddy] [Media] [Automation]       [Frigate] [Samba] [Sync]
                          |                      |
                    [HA + Mosquitto] ←──MQTT──→ [Cameras]
```

### OPNsense VM

| Setting | Value |
|---------|-------|
| vCPU | 2 |
| RAM | 2GB |
| Disk | 20GB |
| WAN | NIC1 passthrough (PCI-e) |
| LAN | vmbr0 (bridge) |

**OPNsense Services:**
- Firewall + NAT
- DHCP server
- DNS resolver (Unbound)
- WireGuard/OpenVPN (optional)
- Traffic shaping
- IDS/IPS (Suricata)

### Docker Host VM

| Setting | Value |
|---------|-------|
| OS | Ubuntu 24.04 LTS / Debian 12 |
| vCPU | 2 (expandable) |
| RAM | 8GB (expandable) |
| Disk | 400GB |
| Network | vmbr0 (static IP) |

**Docker Services:**

| Service | Category | Port | Purpose |
|---------|----------|------|---------|
| Pi-hole | Network | 53, 8053 | DNS sinkhole (home network) |
| Caddy | Networking | 80, 443 | Reverse proxy |
| Jellyfin | Media | 8096 | Media streaming |
| Sonarr | Media | 8989 | TV show management |
| Radarr | Media | 7878 | Movie management |
| Prowlarr | Media | 9696 | Indexer management |
| qBittorrent | Media | 6881 | Torrent client |
| Home Assistant | Automation | 8123 | Home automation |
| Mosquitto | Automation | 1883 | MQTT broker (HA ↔ Frigate) |
| Frigate | Security | 5000 | NVR (recordings via NFS to NAS) |
| Vaultwarden | Security | 8843 | Password manager |

**Why Frigate on Docker VM:**
- Intel N150 has modern QuickSync for hardware video decode
- i3-3220T (NAS) too old for efficient multi-stream decode
- NFS mount to NAS Purple 2TB for recordings
- Coral USB TPU can be added to Mini PC later

**Management:** Use `lazydocker` (TUI) or `docker compose` CLI - no web GUI needed.

**See also:** `docs/caddy-config.md` for reverse proxy configuration.

### Docker Structure

```
docker/
├── networking/
│   ├── pihole/
│   │   └── docker-compose.yml
│   └── caddy/
│       └── docker-compose.yml
├── media/
│   └── docker-compose.yml    # Jellyfin, *arr stack
├── automation/
│   └── docker-compose.yml    # Home Assistant
└── security/
    └── docker-compose.yml    # Vaultwarden
```

### Proxmox Backup

- VM snapshots before major changes
- Proxmox Backup Server (future, on NAS)
- OPNsense config export to NAS

## Raspberry Pi 4 - Bitcoin Node

Sovereign Bitcoin infrastructure with Start9 OS.

### Why Start9 over Umbrel

| Aspect | Start9 | Umbrel |
|--------|--------|--------|
| Security | HTTPS everywhere | HTTP on LAN |
| License | Fully open source | Non-open source |
| Backups | One-click encrypted | Manual/limited |
| Config | Rich web forms | SSH + CLI |
| Focus | Privacy-first | General homelab |
| Geek factor | High | Medium |

### Services

| Service | Purpose | Storage |
|---------|---------|---------|
| Bitcoin Core | Full node | ~600GB blockchain |
| LND or CLN | Lightning Network | ~1GB |
| Electrum Server | SPV wallet backend | ~50GB index |

*BTCPay Server: Add later only if you need payment processing.*

### Hardware Requirements

- Raspberry Pi 4 (4GB RAM minimum)
- External SSD: 1TB minimum (USB 3.0)
- Quality power supply (3A)
- Ethernet connection (recommended)

### Backup Role

If Mini PC fails, RPi 4 can run essential services:
- Pi-hole (Start9 has it as an app)
- Lightweight containers
- Network monitoring

## NAS (DIY Mini-ITX)

Debian-based storage server. Repurposed 2013 build, compact and low-power.

*Full hardware specs in `docs/hardware.md`*

### Hardware

| Component | Model | Notes |
|-----------|-------|-------|
| Case | Cooler Master Elite 120 Advanced | Mini-ITX, compact |
| Motherboard | ASUS P8H77-I | Intel H77, LGA 1155 |
| CPU | Intel Core i3-3220T | Dual-Core 2.8GHz, 35W TDP |
| RAM | Kingston HyperX 8GB | 2x4GB DDR3-1600 |
| PSU | picoPSU-160-XT + 220W brick | 192W DC-DC, 2013 vintage |
| OS | Debian 12 | Docker-based services |

### Storage Strategy

No mergerfs/snapraid initially - using dedicated drives with 3-2-1 backup instead.

```
┌─────────────────────────────────────────────────────────┐
│                    NAS (Primary)                         │
│  SSD 240GB │ Purple 2TB │ Red Plus 8TB                  │
│  OS/Docker │ Frigate    │ Media + Data                  │
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

**Spare:** Crucial MX500 1TB SSD available for future use.

**Backup Targets:**

| Target | Size | Purpose | Method |
|--------|------|---------|--------|
| WD Red 3TB | 3TB | Local critical backup | Restic to Sabrent dock |
| Google Drive | 1TB | Offsite critical backup | rclone crypt (encrypted) |

**Why this approach:**
- Purple dedicated to Frigate = optimized for 24/7 surveillance writes
- No parity overhead, simpler management
- 3-2-1 backup protects against more failure modes than parity alone
- Can add SnapRAID parity later with 8TB+ drive if needed

### Services

| Service | Port | Purpose |
|---------|------|---------|
| NFS Server | 2049 | Export Purple 2TB for Frigate (Docker VM) |
| Samba | 445 | Network shares |
| Syncthing | 8384, 22000 | Peer-to-peer file sync |
| Restic REST | 8000 | Backup target for other devices |

### Directory Structure

```
/mnt/
├── ssd/                # Crucial MX500 1TB
│   ├── docker/         # Docker data
│   └── configs/        # Service configs
├── purple/             # WD Purple 2TB (dedicated)
│   └── frigate/        # NVR recordings only
├── data/               # WD Red Plus 8TB
│   ├── media/          # Movies, TV, Music
│   ├── backups/        # Service backups (Headscale, Vaultwarden, etc.)
│   ├── family/         # Family file sync (Syncthing)
│   └── photos/         # Photo archive
└── external/           # Sabrent dock mount point
    └── backup/         # Local backup target (3TB)
```

### NFS Export for Frigate

The Purple 2TB drive is exported via NFS to Docker VM for Frigate recordings.

```
NAS: /mnt/purple/frigate  →  NFS export
Docker VM: /mnt/frigate   →  NFS mount (rw, sync, no_subtree_check)
```

**Why NFS:**
- Frigate runs on Docker VM (better hardware decode)
- Recordings stored on NAS (dedicated surveillance drive)
- Low latency on local gigabit+ network

## Frigate Setup (Docker VM)

| Component | Location | Purpose |
|-----------|----------|---------|
| Frigate NVR | Docker VM | AI-powered object detection |
| Coral USB TPU | Mini PC USB (future) | Hardware ML acceleration |
| Mosquitto | Docker VM | MQTT broker |
| Recordings | NAS (NFS) | Purple 2TB dedicated |
| Cameras | Network | 2x RLC-520A (PoE), 1x Tapo C110 (WiFi) |

**Camera Flow:**
```
[Cameras] → [Network] → [Docker VM: Frigate]
                              ↓
                        [NFS Mount]
                              ↓
                    [NAS: Purple 2TB]

[Frigate] → [MQTT] → [Home Assistant]
```

**Hardware Acceleration:**
- Intel N150 QuickSync for video decode (vaapi)
- Coral USB TPU for detection (future purchase)

## Network Configuration

### Static IPs (DHCP Reservation)

| Device | IP | MAC |
|--------|----|----|
| Mini PC | 192.168.1.10 | Reserve |
| RPi 4 | 192.168.1.11 | Reserve |
| Old PC/NAS | 192.168.1.12 | Reserve |

### Tailscale IPs

| Device | Tailscale IP | Hostname |
|--------|--------------|----------|
| Mini PC | 100.64.0.10 | minipc |
| RPi 4 | 100.64.0.11 | rpi4 |
| NAS | 100.64.0.12 | nas |

### Firewall Rules (OPNsense)

- WAN: Block all inbound, allow established outbound
- LAN: Allow all outbound, selective inbound
- Port forwards: As needed for external access
- Tailscale: Allow mesh traffic
- SSH: Only from Tailscale IPs
- Inter-VLAN: Consider VLANs for IoT isolation (future)

## Deployment Order

| Phase | Task | Device | Status |
|-------|------|--------|--------|
| 1 | Install Proxmox VE | Mini PC | Pending |
| 2 | Configure networking (vmbr0, passthrough) | Mini PC | Pending |
| 3 | Create OPNsense VM, configure WAN/LAN | Mini PC | Pending |
| 4 | Create Docker Host VM, install Docker | Mini PC | Pending |
| 5 | Deploy Pi-hole | Docker VM | Pending |
| 6 | Deploy Caddy + Vaultwarden | Docker VM | Pending |
| 7 | Deploy media stack (Jellyfin, *arr, qBittorrent) | Docker VM | Pending |
| 8 | Deploy Mosquitto MQTT broker | Docker VM | Pending |
| 9 | Deploy Home Assistant | Docker VM | Pending |
| 10 | Flash Start9 on RPi 4 | RPi 4 | Pending |
| 11 | Sync Bitcoin blockchain | RPi 4 | Pending |
| 12 | Install Debian 12 on NAS | NAS | Pending |
| 13 | Mount drives (SSD, Purple, Red Plus) | NAS | Pending |
| 14 | Configure NFS export for Purple 2TB | NAS | Pending |
| 15 | Deploy Syncthing + Samba | NAS | Pending |
| 16 | Deploy Restic REST server | NAS | Pending |
| 17 | Mount NFS share on Docker VM | Docker VM | Pending |
| 18 | Deploy Frigate NVR (with NFS + vaapi) | Docker VM | Pending |
| 19 | Configure cameras in Frigate | Docker VM | Pending |
| 20 | Connect Frigate → MQTT → Home Assistant | Docker VM | Pending |
| 21 | Join all devices to Tailscale mesh | All | Pending |
| 22 | Configure backup jobs (local + cloud) | NAS | Pending |

## Backup Strategy

**3-2-1 Backup Rule:**
- 3 copies of data (primary + 2 backups)
- 2 different media types (SSD/HDD + cloud)
- 1 offsite (Google Drive)

*Full procedures in `docs/disaster-recovery.md`*

### Critical Services (Hourly)

| Source | Destination | Method | Retention |
|--------|-------------|--------|-----------|
| Headscale DB (RPi 5) | NAS + Google Drive | Restic + rclone | 30 days |
| Vaultwarden (Docker VM) | NAS + Google Drive | Restic + rclone | 30 days |

### Standard Services (Daily)

| Source | Destination | Method | Retention |
|--------|-------------|--------|-----------|
| Pi-hole config | NAS | Restic | 7 days |
| Home Assistant | NAS | Restic | 14 days |
| Docker VM configs | NAS | Restic | 14 days |
| Frigate clips (important) | NAS 8TB | Manual export | As needed |

### Other Backups

| Source | Destination | Method | Retention |
|--------|-------------|--------|-----------|
| Start9 | NAS | Start9 built-in | 4 weeks |
| Family devices | NAS (Syncthing) | Continuous sync | N/A |
| Photos | NAS + Google Drive | Syncthing + rclone | Permanent |

### Backup Paths

```
NAS: /mnt/data/backups/
├── headscale/          # Hourly, 30 days
├── vaultwarden/        # Hourly, 30 days
├── pihole/             # Daily, 7 days
├── homeassistant/      # Daily, 14 days
├── docker-vm/          # Daily, 14 days
└── start9/             # Weekly, 4 weeks

External: /mnt/external/backup/
└── critical/           # Local copy of critical backups

Cloud: Google Drive (via rclone crypt)
└── homelab-backup/     # Encrypted offsite
    ├── headscale/
    ├── vaultwarden/
    └── photos/
```

## Power Considerations

All critical devices connected to **Forza NT-1012U 1000VA UPS**.

| Device | Power | UPS Protected |
|--------|-------|---------------|
| Mini PC | ~35W | Yes |
| RPi 4 | 15W | Yes |
| NAS | ~50W idle | Yes |
| MokerLink Switch | ~15W | Yes |
| TP-Link PoE Switch | ~65W max | Yes |

**Total estimated load:** ~180W (well under 1000VA capacity)

**TODO:** Configure NUT (Network UPS Tools) for graceful shutdown on power loss.

## Future Enhancements

### Hardware
- [ ] Coral USB TPU for Frigate ML acceleration (connect to Mini PC)
- [ ] 8TB HDD for SnapRAID parity (when budget allows)
- [ ] 8TB HDD for larger external backup
- [ ] GPU passthrough for Jellyfin transcoding
- [ ] Zigbee/Z-Wave coordinator for Home Assistant
- [ ] Replace NAS PSU (2013, aging)

### Infrastructure
- [x] VLANs for IoT/camera isolation (see `docs/vlan-design.md`)
- [ ] Proxmox Backup Server on NAS
- [x] NUT for UPS graceful shutdown (see `docs/nut-config.md`)
- [ ] HA cluster (second Proxmox node)

### Automation
- [ ] Ansible playbooks for declarative deployment
- [ ] age + SOPS for encrypted secrets in git (`.sops.yaml` ready)
- [ ] Automated backup verification scripts

## References

- [Proxmox VE](https://www.proxmox.com/en/proxmox-ve)
- [OPNsense](https://opnsense.org/)
- [Pi-hole](https://pi-hole.net/)
- [Caddy](https://caddyserver.com/)
- [Start9 Docs](https://docs.start9.com/)
- [Syncthing](https://syncthing.net/)
- [Frigate NVR](https://frigate.video/)
- [Home Assistant](https://www.home-assistant.io/)
- [Jellyfin](https://jellyfin.org/)
- [Mosquitto MQTT](https://mosquitto.org/)
- [Restic](https://restic.net/)
- [rclone crypt](https://rclone.org/crypt/)
- [lazydocker](https://github.com/jesseduffield/lazydocker)
- [NUT - Network UPS Tools](https://networkupstools.org/)
