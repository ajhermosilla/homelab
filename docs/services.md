# Services

27 services across 3 environments. Organized by location and category.

## Service Matrix

| Service | Category | Environment | Host | Status |
|---------|----------|-------------|------|--------|
| Headscale | Networking | VPS | Vultr | Active |
| Forgejo | Git | Fixed | NAS | Active |
| Pi-hole | Networking | Fixed | Docker VM | Active |
| OpenClaw | AI | Fixed | RPi 5 | Planned |
| Caddy | Networking | Fixed | Docker VM | Active |
| Jellyfin | Media | Fixed | Docker VM | Planned |
| Sonarr | Media | Fixed | Docker VM | Planned |
| Radarr | Media | Fixed | Docker VM | Planned |
| Prowlarr | Media | Fixed | Docker VM | Planned |
| qBittorrent | Media | Fixed | Docker VM | Planned |
| Home Assistant | Automation | Fixed | Docker VM | Planned |
| Mosquitto | Messaging | Fixed | Docker VM | Planned |
| Vaultwarden | Security | Fixed | Docker VM | Active |
| Watchtower | Monitoring | Fixed | Docker VM | Active |
| Bitcoin Core | Bitcoin | Fixed | RPi 4 (Start9) | Planned |
| LND | Bitcoin | Fixed | RPi 4 (Start9) | Planned |
| Electrum Server | Bitcoin | Fixed | RPi 4 (Start9) | Planned |
| Samba | Storage | Fixed | NAS | Planned |
| Syncthing | Storage | Fixed | NAS | Planned |
| Frigate | Security | Fixed | Docker VM | Planned |
| Restic REST | Backup | Fixed | NAS | Planned |
| DERP Relay | Networking | VPS | Vultr | Planned |
| Pi-hole | Networking | VPS | Vultr | Planned |
| Uptime Kuma | Monitoring | VPS | Vultr | Active |
| ntfy | Monitoring | VPS | Vultr | Active |
| Caddy | Networking | VPS | Vultr | Active |
| headscale-backup | Backup | VPS | Vultr | Active |
| changedetection | Scraping | VPS | Vultr | Planned |
| Restic REST | Backup | VPS | Vultr | Planned |

## By Environment

### Mobile Kit (On-Demand)

*No Docker services. Mobile DNS handled by Beryl AX AdGuard Home.*

### Fixed Homelab - Docker VM

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **Pi-hole** | 53, 8053 | DNS ad-blocking |
| **Caddy** | 80, 443 | Reverse proxy, auto-SSL |
| **Jellyfin** | 8096 | Media streaming |
| **Sonarr** | 8989 | TV show management |
| **Radarr** | 7878 | Movie management |
| **Prowlarr** | 9696 | Indexer management |
| **qBittorrent** | 8081, 6881 | Torrent client (Web UI, protocol) |
| **Home Assistant** | 8123 | Home automation |
| **Mosquitto** | 1883 | MQTT broker (HA ↔ Frigate) |
| **Vaultwarden** | 8843 | Password manager |
| **Watchtower** | - | Automatic container updates |
| **Frigate** | 5000 | NVR with AI detection (NFS to NAS) |

### Fixed Homelab - RPi 5

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **OpenClaw** | 18789 | AI assistant (cloud APIs) |

*Raspberry Pi 5 (8GB) dedicated to OpenClaw, connected to MokerLink switch.*

### Fixed Homelab - Start9 (RPi 4)

| Service | Purpose |
|---------|---------|
| **Bitcoin Core** | Full node (~600GB) |
| **LND** | Lightning Network |
| **Electrum Server** | SPV wallet backend |

*Managed via Start9 web interface, not Docker.*

### Fixed Homelab - NAS

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **Samba** | 445 | Network file shares |
| **Syncthing** | 8384, 22000 | Peer-to-peer file sync |
| **Restic REST** | 8000 | Backup target |
| **Forgejo** | 3000, 2222 | Git server (SSH + web) |
| **NFS** | 2049 | Exports Purple 2TB for Frigate |

### VPS (Vultr) - 24/7

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **Headscale** | 443, 3478 | Tailscale coordination (PRIMARY) |
| **Caddy** | 80, 443 | Reverse proxy, auto-SSL |
| **headscale-backup** | - | Headscale database backups |
| **DERP Relay** | 443, 3478 | Tailscale NAT traversal |
| **Pi-hole** | 53, 8053 | DNS (US-based fallback) |
| **Uptime Kuma** | 3001 | External monitoring |
| **ntfy** | 80 | Push notifications |
| **changedetection** | 5000 | Website change monitor |
| **Restic REST** | 8000 | Encrypted backup target |

## Port Allocation

### Reserved Ranges

| Range | Purpose |
|-------|---------|
| 53 | DNS (Pi-hole) |
| 80, 443 | HTTP/HTTPS (Caddy) |
| 3478 | STUN (Headscale, DERP) |
| 5000-5999 | Misc services |
| 7000-7999 | *arr stack |
| 8000-8999 | Web interfaces |
| 9000-9999 | Additional services |
| 22000+ | Syncthing |

### Full Port Map

| Port | Service | Environment |
|------|---------|-------------|
| 53 | Pi-hole DNS | All |
| 80 | Pi-hole Web / ntfy | All |
| 443 | Caddy / Headscale | Fixed / VPS |
| 445 | Samba | NAS |
| 1883 | Mosquitto MQTT | Fixed |
| 3001 | Uptime Kuma | VPS |
| 3478 | STUN (Headscale/DERP) | VPS |
| 5000 | Frigate / changedetection | Fixed / VPS |
| 5353 | Unbound (OPNsense) | Fixed |
| 7878 | Radarr | Fixed |
| 8000 | Restic REST | NAS / VPS |
| 8053 | Pi-hole Web | Fixed / VPS |
| 8080 | ntfy | VPS |
| 8081 | qBittorrent | Fixed |
| 6881 | qBittorrent (torrent) | Fixed |
| 8096 | Jellyfin | Fixed |
| 8123 | Home Assistant | Fixed |
| 8384 | Syncthing Web | NAS |
| 8843 | Vaultwarden | Fixed |
| 8989 | Sonarr | Fixed |
| 9696 | Prowlarr | Fixed |
| 22000 | Syncthing Sync | NAS |
| 18789 | OpenClaw Gateway | Fixed |
| 2222 | Forgejo SSH | NAS |
| 3000 | Forgejo Web | NAS |

## Active Services

### Forgejo

Self-hosted Git server (Gitea fork) with web UI and SSH access.

| Property | Value |
|----------|-------|
| Location | `docker/fixed/nas/git/` |
| Image | `codeberg.org/forgejo/forgejo:11` |
| Host | NAS |
| Ports | 3000 (Web), 2222 (SSH) |
| Data | `/srv/forgejo` (NAS SSD) |
| URL | https://git.cronova.dev |

**Access:**
```bash
# Clone via SSH
git clone ssh://git@192.168.0.12:2222/augusto/<repo>.git

# Web UI
https://git.cronova.dev
```

## Docker Directory Structure

```
docker/
├── mobile/
├── fixed/
│   ├── docker-vm/
│   │   ├── networking/
│   │   │   ├── pihole/
│   │   │   └── caddy/
│   │   ├── media/
│   │   │   └── docker-compose.yml  # Jellyfin, *arr, qBit
│   │   ├── automation/
│   │   │   └── docker-compose.yml  # Home Assistant, Mosquitto
│   │   └── security/
│   │       └── docker-compose.yml  # Vaultwarden, Frigate
│   └── nas/
│       ├── storage/
│       │   └── docker-compose.yml  # Samba, Syncthing
│       ├── backup/
│       │   └── docker-compose.yml  # Restic REST
│       └── git/
│           └── docker-compose.yml  # Forgejo
├── vps/
│   ├── networking/
│   │   ├── derp/
│   │   └── pihole/
│   ├── monitoring/
│   │   └── docker-compose.yml  # Uptime Kuma, ntfy
│   ├── scraping/
│   │   └── docker-compose.yml  # changedetection
│   └── backup/
│       └── docker-compose.yml  # Restic REST
└── shared/                   # Shared env files
```

## Service Categories

| Category | Services | Count |
|----------|----------|-------|
| Networking | Headscale, Pi-hole (x3), Caddy (x2), DERP | 7 |
| Media | Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent | 5 |
| Bitcoin | Bitcoin Core, LND, Electrum Server | 3 |
| Storage | Samba, Syncthing | 2 |
| Security | Vaultwarden, Frigate | 2 |
| Automation | Home Assistant | 1 |
| Messaging | Mosquitto | 1 |
| Monitoring | Uptime Kuma, ntfy, Watchtower | 3 |
| Backup | Restic REST (x2), headscale-backup | 3 |
| Scraping | changedetection | 1 |
| Git | Forgejo | 1 |
| AI | OpenClaw | 1 |

**Unique services:** 26 | **Total deployments:** 30

## Service Dependencies

Services and their required dependencies for operation.

```
Headscale (VPS)          ← Required first (enables mesh)
    │
    ├── DERP Relay       ← NAT traversal
    │
    └── All other services (Tailscale clients)

Pi-hole (any)            ← DNS resolution
    │
    └── All local services

Mosquitto               ← MQTT broker
    │
    ├── Frigate          → Publishes events
    └── Home Assistant   → Subscribes to events

NFS (NAS)               ← Storage backend
    │
    └── Frigate          → Stores recordings

Prowlarr                ← Indexer management
    │
    ├── Sonarr           → TV indexers
    └── Radarr           → Movie indexers

qBittorrent             ← Download client
    │
    ├── Sonarr           → TV downloads
    └── Radarr           → Movie downloads
```

### Startup Order

**VPS (deploy first):**
1. Headscale → enables mesh network
2. DERP Relay → improves connectivity
3. Pi-hole → DNS fallback
4. Uptime Kuma → external monitoring
5. ntfy → notifications
6. Restic REST → backup target

**Fixed Homelab - NAS:**
1. NFS → storage for Frigate
2. Samba → file shares
3. Syncthing → file sync
4. Restic REST → backup target
5. Forgejo → git server

**Fixed Homelab - Docker VM:**
1. Pi-hole → local DNS
2. Caddy → reverse proxy
3. Watchtower → automatic container updates
4. Mosquitto → MQTT broker
5. Frigate → NVR (needs NFS, MQTT)
6. Home Assistant → automation (needs MQTT)
7. Vaultwarden → passwords
8. Media stack (Prowlarr → Sonarr/Radarr → qBittorrent → Jellyfin)

## Access Matrix

How services are accessed based on location.

| Service | Local Access | Tailscale Access | Public Access |
|---------|--------------|------------------|---------------|
| **Headscale** | - | - | hs.cronova.dev |
| **Pi-hole** | 192.168.0.10:8053 | pihole.tail:8053 | - |
| **Caddy** | 192.168.0.10:443 | - | - |
| **Jellyfin** | yrasema.cronova.dev | yrasema.cronova.dev | - |
| **Home Assistant** | jara.cronova.dev | jara.cronova.dev | - |
| **Vaultwarden** | vault.cronova.dev | vault.cronova.dev | - |
| **Frigate** | 192.168.0.10:5000 | frigate.tail:5000 | - |
| **Sonarr** | 192.168.0.10:8989 | sonarr.tail:8989 | - |
| **Radarr** | 192.168.0.10:7878 | radarr.tail:7878 | - |
| **Prowlarr** | 192.168.0.10:9696 | prowlarr.tail:9696 | - |
| **qBittorrent** | 192.168.0.10:8081 | qbit.tail:8081 | - |
| **Uptime Kuma** | - | status.tail:3001 | - |
| **ntfy** | - | ntfy.tail:80 | - |
| **Syncthing** | 192.168.0.12:8384 | nas.tail:8384 | - |

*Note: `.tail` = Tailscale MagicDNS hostname*

## Service Criticality

### Critical (24/7 Required)

Services that must always be available.

| Service | Location | Impact if Down |
|---------|----------|----------------|
| Headscale | VPS | Mesh network offline |
| Pi-hole (VPS) | VPS | DNS fallback lost |
| Uptime Kuma | VPS | No external monitoring |
| ntfy | VPS | No push notifications |
| Vaultwarden | Docker VM | Password access lost |

### Important (Business Hours)

Services needed during active use.

| Service | Location | Impact if Down |
|---------|----------|----------------|
| Pi-hole (Fixed) | Docker VM | Local DNS lost |
| Home Assistant | Docker VM | Automation offline |
| Frigate | Docker VM | No camera recording |
| Samba | NAS | File shares unavailable |
| Forgejo | NAS | Git server offline |

### Optional (On-Demand)

Services used occasionally.

| Service | Location | Impact if Down |
|---------|----------|----------------|
| Jellyfin | Docker VM | Media streaming unavailable |
| Sonarr/Radarr | Docker VM | No auto-downloads |
| qBittorrent | Docker VM | Manual downloads only |
| Syncthing | NAS | Sync paused |

## References

- [Headscale](https://headscale.net/)
- [Pi-hole](https://pi-hole.net/)
- [Caddy](https://caddyserver.com/)
- [Jellyfin](https://jellyfin.org/)
- [Sonarr](https://sonarr.tv/)
- [Radarr](https://radarr.video/)
- [Prowlarr](https://prowlarr.com/)
- [qBittorrent](https://www.qbittorrent.org/)
- [Home Assistant](https://www.home-assistant.io/)
- [Mosquitto](https://mosquitto.org/)
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden)
- [Start9](https://start9.com/)
- [Syncthing](https://syncthing.net/)
- [Frigate](https://frigate.video/)
- [Restic REST Server](https://github.com/restic/rest-server)
- [Tailscale DERP](https://tailscale.com/kb/1118/custom-derp-servers/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [ntfy](https://ntfy.sh/)
- [changedetection.io](https://changedetection.io/)
- [Forgejo](https://forgejo.org/)
