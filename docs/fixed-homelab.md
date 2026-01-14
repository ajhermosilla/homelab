# Fixed Homelab Architecture

Always-on infrastructure at home for media, automation, storage, and Bitcoin sovereignty.

## Hardware

| Device | Specs | Role | Storage |
|--------|-------|------|---------|
| Mini PC | Intel N150, 12GB RAM, 512GB SSD | Primary server | Internal SSD |
| Raspberry Pi 4 | 4GB RAM | Bitcoin node + backup | External 1TB SSD |
| Old PC (NAS) | TBD | Network storage | 2TB + 6TB HDDs |

## Architecture Diagram

```
                      [Home Router]
                           |
         +-----------------+-----------------+
         |                 |                 |
    [Mini PC]          [RPi 4]          [Old PC/NAS]
   Primary Server    Bitcoin Node         Storage
   192.168.1.10      192.168.1.11       192.168.1.12
         |                 |                 |
         +-----------------+-----------------+
                           |
                    [Tailscale Mesh]
                     100.64.0.10-12
                           |
              +------------+------------+
              |                         |
         [Mobile Kit]              [VPS - US]
         RPi 5 + MacBook           Coordination
```

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
       [Docker Host VM]        [RPi 4]              [NAS/Old PC]
        192.168.1.10         192.168.1.11          192.168.1.12
              |
    +---------+---------+---------+
    |         |         |         |
[Jellyfin] [HA]  [Nextcloud] [Traefik]
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
| Pi-hole | Network | 53, 80 | DNS sinkhole (home network) |
| Jellyfin | Media | 8096 | Media streaming |
| Sonarr | Media | 8989 | TV show management |
| Radarr | Media | 7878 | Movie management |
| Prowlarr | Media | 9696 | Indexer management |
| qBittorrent | Media | 8080 | Torrent client |
| Home Assistant | Automation | 8123 | Home automation |
| Vaultwarden | Security | 8843 | Password manager |
| Caddy | Networking | 443 | Reverse proxy (simpler than Traefik) |

**Management:** Use `lazydocker` (TUI) or `docker compose` CLI - no web GUI needed.

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

## Old PC - NAS

Debian-based storage server with mergerfs + snapraid.

### Storage Layout

| Drive | Model | Size | Purpose |
|-------|-------|------|---------|
| Drive 1 | WD Nighthawk | 2TB | Frigate NVR recordings |
| Drive 2 | WD Red | 6TB | Media + family backups |
| Parity | (future) | 6TB+ | Snapraid parity |

### Why mergerfs + snapraid

| Feature | Benefit |
|---------|---------|
| No special hardware | Works with any drives |
| Mix drive sizes | 2TB + 6TB no problem |
| Add drives anytime | No array rebuild |
| File-level recovery | Not block-level |
| Low overhead | Simple and reliable |

### Services

| Service | Port | Purpose |
|---------|------|---------|
| Samba | 445 | Network shares |
| Syncthing | 8384, 22000 | Peer-to-peer file sync (replaces Nextcloud) |
| Frigate | 5000 | NVR for security cameras |
| Restic REST | 8000 | Backup target |
| Snapraid | - | Parity protection |

### Directory Structure

```
/mnt/
├── disk1/              # WD Nighthawk 2TB
│   └── frigate/        # NVR recordings
├── disk2/              # WD Red 6TB
│   ├── media/          # Movies, TV, Music
│   └── backups/        # Family backups
└── storage/            # mergerfs pool
    ├── media/          # Merged view
    └── backups/        # Merged view
```

### Frigate Setup

| Component | Purpose |
|-----------|---------|
| Frigate NVR | AI-powered camera detection |
| Coral TPU | Hardware ML acceleration (optional) |
| MQTT | Home Assistant integration |
| RTSP cameras | IP camera feeds |

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
| 5 | Deploy Caddy + Vaultwarden | Docker VM | Pending |
| 6 | Deploy media stack | Docker VM | Pending |
| 7 | Deploy Home Assistant | Docker VM | Pending |
| 8 | Flash Start9 on RPi 4 | RPi 4 | Pending |
| 9 | Sync Bitcoin blockchain | RPi 4 | Pending |
| 10 | Install Debian on NAS | Old PC | Pending |
| 11 | Configure mergerfs + snapraid | Old PC | Pending |
| 12 | Deploy Syncthing + Frigate | Old PC | Pending |
| 13 | Configure Samba shares | Old PC | Pending |
| 14 | Join all to Tailscale mesh | All | Pending |

## Backup Strategy

| Source | Destination | Method | Frequency |
|--------|-------------|--------|-----------|
| Mini PC configs | NAS | Restic | Daily |
| Start9 | NAS | Start9 backup | Weekly |
| NAS critical | VPS (encrypted) | Restic | Weekly |
| Family devices | NAS | Syncthing | Continuous |
| RPi 5 Headscale DB | NAS | Restic | Daily |

## Power Considerations

- UPS recommended for all devices
- Graceful shutdown scripts
- Start9 handles power loss well
- Snapraid: run sync before shutdown

## Future Enhancements

- [ ] Coral TPU for Frigate ML acceleration
- [ ] Second parity drive for snapraid
- [ ] GPU passthrough for Jellyfin transcoding
- [ ] Zigbee/Z-Wave coordinator for Home Assistant
- [ ] Additional cameras for Frigate
- [ ] VLANs for IoT isolation
- [ ] Proxmox Backup Server on NAS
- [ ] HA cluster (second Proxmox node)
- [ ] Ansible playbooks for declarative deployment
- [ ] age + SOPS for encrypted secrets in git

## References

- [Proxmox VE](https://www.proxmox.com/en/proxmox-ve)
- [OPNsense](https://opnsense.org/)
- [Pi-hole](https://pi-hole.net/)
- [Caddy](https://caddyserver.com/)
- [Start9 Docs](https://docs.start9.com/)
- [Syncthing](https://syncthing.net/)
- [mergerfs GitHub](https://github.com/trapexit/mergerfs)
- [Snapraid](https://www.snapraid.it/)
- [Frigate NVR](https://frigate.video/)
- [Home Assistant](https://www.home-assistant.io/)
- [Jellyfin](https://jellyfin.org/)
- [lazydocker](https://github.com/jesseduffield/lazydocker)
