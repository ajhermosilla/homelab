# Deployment Order and Dependencies

Service deployment order and dependency graph for the homelab infrastructure.

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEPLOYMENT ORDER                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 1: VPS (Foundation)                                                   │
│  ┌─────────────┐                                                            │
│  │  Headscale  │ ← Deploy FIRST (mesh coordinator)                          │
│  └──────┬──────┘                                                            │
│         │                                                                    │
│  ┌──────▼──────┐    ┌─────────────┐    ┌─────────────┐                     │
│  │    Caddy    │    │   Pi-hole   │    │    DERP     │                     │
│  │   (VPS)     │    │   (VPS)     │    │   Relay     │                     │
│  └─────────────┘    └─────────────┘    └─────────────┘                     │
│         │                                                                    │
│  ┌──────▼──────┐    ┌─────────────┐                                        │
│  │   Uptime    │───▶│    ntfy     │                                        │
│  │    Kuma     │    │             │                                        │
│  └─────────────┘    └─────────────┘                                        │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 2: Fixed Homelab - Networking                                         │
│  ┌─────────────┐    ┌─────────────┐                                        │
│  │   Pi-hole   │    │    Caddy    │                                        │
│  │  (Docker)   │    │  (Docker)   │                                        │
│  └─────────────┘    └─────────────┘                                        │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 3: Fixed Homelab - Core Services                                      │
│  ┌─────────────┐                                                            │
│  │  Mosquitto  │ ← Deploy BEFORE Home Assistant & Frigate                   │
│  └──────┬──────┘                                                            │
│         │                                                                    │
│  ┌──────▼──────┐    ┌─────────────┐                                        │
│  │    Home     │    │  Vaultwarden│                                        │
│  │  Assistant  │    │             │                                        │
│  └─────────────┘    └─────────────┘                                        │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 4: Fixed Homelab - NAS & Storage                                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                     │
│  │  NFS Server │───▶│   Samba     │    │  Syncthing  │                     │
│  │    (NAS)    │    │   (NAS)     │    │   (NAS)     │                     │
│  └──────┬──────┘    └─────────────┘    └─────────────┘                     │
│         │                                                                    │
│  ┌──────▼──────┐                                                            │
│  │ Restic REST │ ← Backup server for all services                           │
│  │   (NAS)     │                                                            │
│  └─────────────┘                                                            │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 5: Fixed Homelab - Media & Security (requires NFS)                    │
│  ┌─────────────┐    ┌─────────────┐                                        │
│  │   Frigate   │    │   Jellyfin  │                                        │
│  │  (NVR)      │    │   (Media)   │                                        │
│  └─────────────┘    └─────────────┘                                        │
│         │                                                                    │
│  ┌──────▼──────┐    ┌─────────────┐    ┌─────────────┐                     │
│  │   Sonarr    │    │   Radarr    │    │ qBittorrent │                     │
│  └─────────────┘    └─────────────┘    └─────────────┘                     │
│         │                   │                                               │
│  ┌──────▼───────────────────▼──────┐                                        │
│  │           Prowlarr              │                                        │
│  └─────────────────────────────────┘                                        │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 6: Maintenance                                                        │
│  ┌─────────────┐                                                            │
│  │  Watchtower │ ← Deploy LAST (auto-updates other containers)              │
│  └─────────────┘                                                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Deployment Commands by Phase

### Phase 1: VPS Foundation

```bash
# SSH to VPS
ssh linuxuser@vps.cronova.dev

# 1. Headscale (FIRST - enables mesh for everything else)
cd /opt/homelab/repo/docker/vps/networking/headscale
docker compose up -d
# Create user and auth key for other devices

# 2. Caddy (TLS termination)
cd /opt/homelab/repo/docker/vps/networking/caddy
docker compose up -d

# 3. Pi-hole (backup DNS)
cd /opt/homelab/repo/docker/vps/networking/pihole
docker compose up -d

# 4. DERP Relay
cd /opt/homelab/repo/docker/vps/networking/derp
docker compose up -d

# 5. Monitoring (Uptime Kuma + ntfy)
cd /opt/homelab/repo/docker/vps/monitoring
docker compose up -d

# 6. Backup server
cd /opt/homelab/repo/docker/vps/backup
docker compose up -d
```

### Phase 2: Fixed Homelab - Networking

```bash
# SSH to Docker VM (join Tailscale first)
ssh user@100.68.63.168

# 1. Pi-hole (local DNS)
cd /opt/homelab/repo/docker/fixed/docker-vm/networking/pihole
docker compose up -d

# 2. Caddy (local reverse proxy)
cd /opt/homelab/repo/docker/fixed/docker-vm/networking/caddy
docker compose up -d
```

### Phase 3: Fixed Homelab - Core Services

```bash
# 1. Automation (Mosquitto MUST be first)
cd /opt/homelab/repo/docker/fixed/docker-vm/automation
docker compose up -d
# Wait for Mosquitto to be healthy before proceeding

# 2. Security (Vaultwarden)
cd /opt/homelab/repo/docker/fixed/docker-vm/security
docker compose up -d vaultwarden vaultwarden-backup
# Note: Frigate requires NFS, deploy later
```

### Phase 4: NAS & Storage

```bash
# SSH to NAS
ssh user@100.82.77.97

# 1. Storage (Samba + Syncthing)
cd /opt/homelab/repo/docker/fixed/nas/storage
docker compose up -d

# 2. Backup (Restic REST server)
cd /opt/homelab/repo/docker/fixed/nas/backup
docker compose up -d
```

### Phase 5: Media & Security (NFS-dependent)

```bash
# Back on Docker VM - verify NFS mounts first
mount | grep nfs
# Should show /mnt/nas/media and /mnt/nas/frigate

# 1. Frigate (now that NFS is ready)
cd /opt/homelab/repo/docker/fixed/docker-vm/security
docker compose up -d frigate

# 2. Media stack
cd /opt/homelab/repo/docker/fixed/docker-vm/media
docker compose up -d
```

### Phase 6: Maintenance

```bash
# Deploy LAST - will auto-update labeled containers
cd /opt/homelab/repo/docker/fixed/docker-vm/maintenance
docker compose up -d
```

## Using Ansible

Deploy all stacks in correct order:

```bash
# Full deployment (respects dependencies)
ansible-playbook -i inventory.yml playbooks/docker-compose-deploy.yml -l vps
ansible-playbook -i inventory.yml playbooks/docker-compose-deploy.yml -l docker_vm
ansible-playbook -i inventory.yml playbooks/docker-compose-deploy.yml -l storage

# Single stack deployment
ansible-playbook -i inventory.yml playbooks/docker-compose-deploy.yml -l docker_vm -e "stack=automation"
```

## Service Dependencies

| Service | Depends On | Notes |
|---------|------------|-------|
| **Headscale** | None | Deploy first, enables mesh |
| **Caddy (VPS)** | Headscale | TLS for hs.cronova.dev |
| **Pi-hole** | None | Can run standalone |
| **DERP** | Headscale | Relay for NAT traversal |
| **Uptime Kuma** | ntfy (optional) | For notifications |
| **Mosquitto** | None | MQTT broker |
| **Home Assistant** | Mosquitto | For MQTT integration |
| **Frigate** | Mosquitto, NFS | Events via MQTT, recordings on NFS |
| **Vaultwarden** | None | Can run standalone |
| **Jellyfin** | NFS | Media files on NAS |
| **Sonarr/Radarr** | Prowlarr, qBittorrent | Indexers and downloads |
| **Watchtower** | All others | Updates labeled containers |

## Critical Path

The minimum services needed for basic functionality:

```
Headscale → Tailscale clients → Pi-hole → Vaultwarden
```

Without Headscale: No mesh networking (devices isolated)
Without Pi-hole: No DNS (use public DNS temporarily)
Without Vaultwarden: No password access (use cached/backup)

## Restart Order After Outage

If everything goes down, restart in this order:

1. **Headscale** (VPS) - Mesh coordination
2. **Pi-hole** (any) - DNS resolution
3. **Caddy** (VPS) - Public TLS
4. **Vaultwarden** - Password access
5. **Mosquitto** - MQTT broker
6. **Home Assistant** - Automations
7. **Frigate** - Security cameras
8. **Media stack** - Entertainment
9. **Watchtower** - Auto-updates (last)

## Network Dependencies

```
┌─────────────────────────────────────────────────────────────────┐
│                    NETWORK TOPOLOGY                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Internet ─────► VPS (Vultr)                                    │
│                    │                                             │
│                    │ Headscale (WireGuard mesh)                  │
│                    │                                             │
│        ┌───────────┼───────────┐                                │
│        │           │           │                                │
│        ▼           ▼           ▼                                │
│   Fixed Homelab  Mobile Kit  MacBook                            │
│   (192.168.0.x)  (portable)  (anywhere)                         │
│        │                                                         │
│        ├── Docker VM (100.68.63.168)                            │
│        ├── NAS (100.82.77.97)                                    │
│        └── RPi 4/Start9 (100.64.0.11)                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Stack Interdependencies

### Automation Stack
- **Mosquitto** → standalone, no dependencies
- **Home Assistant** → requires healthy Mosquitto
- **homeassistant-backup** → requires Home Assistant

### Security Stack
- **Vaultwarden** → standalone
- **Frigate** → requires Mosquitto (automation stack) + NFS mount
- **vaultwarden-backup** → requires Vaultwarden

### Media Stack
- **Prowlarr** → standalone (indexer manager)
- **Sonarr** → requires Prowlarr
- **Radarr** → requires Prowlarr
- **qBittorrent** → standalone
- **Jellyfin** → requires NFS mount for media

## Pre-Deployment Checklist

Before deploying any stack:

- [ ] Tailscale/Headscale mesh is operational
- [ ] Target host is accessible via Tailscale
- [ ] NFS mounts are configured (for media/security)
- [ ] `.env` files are created from examples
- [ ] Secrets are generated (admin tokens, passwords)
- [ ] Required networks exist or will be created

## References

- [setup-runbook.md](setup-runbook.md) - Detailed first-time setup
- [disaster-recovery.md](../strategy/disaster-recovery.md) - Recovery procedures
- [services.md](../architecture/services.md) - Service descriptions
- [hardware.md](../architecture/hardware.md) - Hardware inventory
