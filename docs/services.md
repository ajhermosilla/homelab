# Services

23 services across 3 environments. Organized by location and category.

## Service Matrix

| Service | Category | Environment | Host | Status |
|---------|----------|-------------|------|--------|
| Headscale | Networking | Mobile | RPi 5 | Planned |
| Pi-hole | Networking | Mobile | RPi 5 | Planned |
| soft-serve | Git | Mobile | MacBook | Active |
| Pi-hole | Networking | Fixed | Docker VM | Planned |
| Caddy | Networking | Fixed | Docker VM | Planned |
| Jellyfin | Media | Fixed | Docker VM | Planned |
| Sonarr | Media | Fixed | Docker VM | Planned |
| Radarr | Media | Fixed | Docker VM | Planned |
| Prowlarr | Media | Fixed | Docker VM | Planned |
| qBittorrent | Media | Fixed | Docker VM | Planned |
| Home Assistant | Automation | Fixed | Docker VM | Planned |
| Mosquitto | Messaging | Fixed | Docker VM | Planned |
| Vaultwarden | Security | Fixed | Docker VM | Planned |
| Bitcoin Core | Bitcoin | Fixed | RPi 4 (Start9) | Planned |
| LND | Bitcoin | Fixed | RPi 4 (Start9) | Planned |
| Electrum Server | Bitcoin | Fixed | RPi 4 (Start9) | Planned |
| Samba | Storage | Fixed | NAS | Planned |
| Syncthing | Storage | Fixed | NAS | Planned |
| Frigate | Security | Fixed | NAS | Planned |
| Restic REST | Backup | Fixed | NAS | Planned |
| DERP Relay | Networking | VPS | Vultr | Planned |
| Pi-hole | Networking | VPS | Vultr | Planned |
| Uptime Kuma | Monitoring | VPS | Vultr | Planned |
| ntfy | Monitoring | VPS | Vultr | Planned |
| changedetection | Scraping | VPS | Vultr | Planned |
| Restic REST | Backup | VPS | Vultr | Planned |

## By Environment

### Mobile Kit

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **Headscale** | 443, 3478 | Tailscale coordination server |
| **Pi-hole** | 53, 80 | DNS ad-blocking |
| **soft-serve** | 23231-23233 | Git server (on MacBook) |

### Fixed Homelab - Docker VM

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **Pi-hole** | 53, 80 | DNS ad-blocking |
| **Caddy** | 443 | Reverse proxy, auto-SSL |
| **Jellyfin** | 8096 | Media streaming |
| **Sonarr** | 8989 | TV show management |
| **Radarr** | 7878 | Movie management |
| **Prowlarr** | 9696 | Indexer management |
| **qBittorrent** | 8080 | Torrent client |
| **Home Assistant** | 8123 | Home automation |
| **Mosquitto** | 1883 | MQTT broker (HA ↔ Frigate) |
| **Vaultwarden** | 8843 | Password manager |

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
| **Frigate** | 5000 | NVR with AI detection |
| **Restic REST** | 8000 | Backup target |

### VPS (Vultr)

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **DERP Relay** | 443, 3478 | Tailscale NAT traversal |
| **Pi-hole** | 53, 8080 | DNS (US-based fallback) |
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
| 22000+ | Syncthing, soft-serve |

### Full Port Map

| Port | Service | Environment |
|------|---------|-------------|
| 53 | Pi-hole DNS | All |
| 80 | Pi-hole Web / ntfy | All |
| 443 | Caddy / Headscale | Fixed / Mobile |
| 445 | Samba | NAS |
| 1883 | Mosquitto MQTT | Fixed |
| 3001 | Uptime Kuma | VPS |
| 3478 | STUN (Headscale/DERP) | Mobile / VPS |
| 5000 | Frigate / changedetection | NAS / VPS |
| 5353 | Unbound (OPNsense) | Fixed |
| 7878 | Radarr | Fixed |
| 8000 | Restic REST | NAS / VPS |
| 8080 | qBittorrent / Pi-hole alt | Fixed / VPS |
| 8096 | Jellyfin | Fixed |
| 8123 | Home Assistant | Fixed |
| 8384 | Syncthing Web | NAS |
| 8843 | Vaultwarden | Fixed |
| 8989 | Sonarr | Fixed |
| 9696 | Prowlarr | Fixed |
| 22000 | Syncthing Sync | NAS |
| 23231 | soft-serve SSH | Mobile |
| 23232 | soft-serve HTTP | Mobile |
| 23233 | soft-serve Stats | Mobile |

## Active Services

### soft-serve

Self-hosted Git server with SSH-based TUI.

| Property | Value |
|----------|-------|
| Location | `docker/git/` |
| Image | `charmcli/soft-serve:latest` |
| Host | Mobile (MacBook Air M1) |
| Ports | 23231 (SSH), 23232 (HTTP), 23233 (Stats) |
| Data | Docker volume `git_soft-serve-data` |

**Access:**
```bash
# TUI
ssh -p 23231 localhost

# Clone
git clone ssh://localhost:23231/<repo>.git

# Create repo
ssh -p 23231 localhost repo create <name>
```

## Docker Directory Structure

```
docker/
├── mobile/
│   └── rpi5/
│       ├── networking/
│       │   ├── headscale/
│       │   │   └── docker-compose.yml
│       │   └── pihole/
│       │       └── docker-compose.yml
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
│   │       └── docker-compose.yml  # Vaultwarden
│   └── nas/
│       ├── storage/
│       │   └── docker-compose.yml  # Samba, Syncthing
│       ├── security/
│       │   └── docker-compose.yml  # Frigate
│       └── backup/
│           └── docker-compose.yml  # Restic REST
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
└── git/
    └── docker-compose.yml  # soft-serve (MacBook)
```

## Service Categories

| Category | Services | Count |
|----------|----------|-------|
| Networking | Headscale, Pi-hole (x3), Caddy, DERP | 6 |
| Media | Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent | 5 |
| Bitcoin | Bitcoin Core, LND, Electrum Server | 3 |
| Storage | Samba, Syncthing | 2 |
| Security | Vaultwarden, Frigate | 2 |
| Automation | Home Assistant | 1 |
| Messaging | Mosquitto | 1 |
| Monitoring | Uptime Kuma, ntfy | 2 |
| Backup | Restic REST (x2) | 2 |
| Scraping | changedetection | 1 |
| Git | soft-serve | 1 |

**Unique services:** 23 | **Total deployments:** 26

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
- [soft-serve](https://github.com/charmbracelet/soft-serve)
