# Deployment Order and Dependencies

Service deployment order and dependency graph for the homelab infrastructure.

## Boot Orchestrator (Docker VM)

On reboot, the Docker VM uses a systemd service to start stacks in correct order:

- **Service**: `docker-boot-orchestrator.service` (runs after `docker.service`)
- **Script**: `/opt/homelab/repo/scripts/docker-boot-orchestrator.sh`
- **Ansible file**: `ansible/files/docker-boot-orchestrator.service`

The orchestrator:

1. Waits for Docker daemon (60s timeout)
2. Waits for NFS mount at `/mnt/nas/frigate` (300s timeout, non-fatal)
3. Stops all containers for clean state
4. Starts stacks in phases 4–13 (see below)

Safe to re-run manually: `sudo systemctl restart docker-boot-orchestrator`

## Docker Network Dependencies

Stacks communicate via external Docker networks. The **creating stack must start first**.

| Network | Created By | Consumed By |
|---------|-----------|-------------|

| `caddy-net` | networking/caddy | auth, tools, documents, monitoring (grafana), photos (immich) |
| `mqtt-net` | automation | security (frigate) |
| `monitoring-net` | monitoring | _(internal only)_ |

If a consuming stack starts before the creating stack, it will fail with a network-not-found error.

## Dependency Graph

```text
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

> **Note**: Use SSH aliases (`vps`, `docker-vm`, `nas`) from `~/.ssh/config`.

### Phase 1: VPS Foundation

```bash
ssh vps

# 1. Headscale (FIRST — enables mesh for everything else)
cd /opt/homelab/repo/docker/vps/networking/headscale && docker compose up -d
# Create user and auth key for other devices

# 2. AdGuard + Unbound (yvága — recursive DNS, must start before Caddy)
cd /opt/homelab/repo/docker/vps/networking/adguard && docker compose up -d

# 3. Caddy (TLS termination)
cd /opt/homelab/repo/docker/vps/networking/caddy && docker compose up -d

# 4. Pi-hole (legacy/secondary DNS)
cd /opt/homelab/repo/docker/vps/networking/pihole && docker compose up -d

# 5. DERP Relay
cd /opt/homelab/repo/docker/vps/networking/derp && docker compose up -d

# 6. Monitoring (Uptime Kuma + ntfy)
cd /opt/homelab/repo/docker/vps/monitoring && docker compose up -d

# 7. Scraping
cd /opt/homelab/repo/docker/vps/scraping && docker compose up -d

# 8. Backup
cd /opt/homelab/repo/docker/vps/backup && docker compose up -d
```

### Phase 2: NAS Services

```bash
ssh nas

# 1. Backup (Restic REST server — needed by Docker VM backup sidecars)
cd /opt/homelab/repo/docker/fixed/nas/backup && docker compose up -d

# 2. Git (Forgejo)
cd /opt/homelab/repo/docker/fixed/nas/git && docker compose up -d

# 3. Storage (Samba + Syncthing)
cd /opt/homelab/repo/docker/fixed/nas/storage && docker compose up -d

# 4. Monitoring (Glances)
cd /opt/homelab/repo/docker/fixed/nas/monitoring && docker compose up -d

# 5. PaaS (Coolify — separate start command)
cd /data/coolify/source && docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Phase 3: Docker VM (boot orchestrator handles this on reboot)

The boot orchestrator runs these in order. For manual deployment:

```bash
ssh docker-vm
BASE=/opt/homelab/repo/docker/fixed/docker-vm

# Phase 4:  Networking — creates caddy-net (required by most stacks)
cd $BASE/networking/pihole && docker compose up -d
cd $BASE/networking/caddy && docker compose up -d

# Phase 5:  Automation — creates mqtt-net (required by security/frigate)
cd $BASE/automation && docker compose up -d
# Wait for mosquitto to be healthy before proceeding

# Phase 6:  Security — frigate joins mqtt-net, needs NFS
cd $BASE/security && docker compose up -d

# Phase 7:  Auth (Authelia — forward auth for protected services)
cd $BASE/auth && docker compose up -d

# Phase 8:  Tools (Dozzle, BentoPDF, Homepage)
cd $BASE/tools && docker compose up -d

# Phase 9:  Documents (Paperless-ngx)
cd $BASE/documents && docker compose up -d

# Phase 10: Monitoring (VictoriaMetrics, vmagent, vmalert, Alertmanager, cAdvisor, Grafana)
cd $BASE/monitoring && docker compose up -d

# Phase 11: Photos (Immich)
cd $BASE/photos && docker compose up -d

# Phase 12: Media (Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent — NFS-dependent)
cd $BASE/media && docker compose up -d

# Phase 13: Maintenance (Watchtower — always last)
cd $BASE/maintenance && docker compose up -d
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

| Service | Depends On | Network | Notes |
|---------|------------|---------|-------|

| **Headscale** | None | headscale-net | Deploy first, enables mesh |
| **Caddy (VPS)** | Headscale | headscale-net, monitoring-net | TLS for hs.cronova.dev |
| **Pi-hole** | None | — | Can run standalone |
| **DERP** | Headscale | derp-net | Relay for NAT traversal |
| **Uptime Kuma** | ntfy (optional) | monitoring-net | For notifications |
| **Caddy (Docker VM)**| None |**creates caddy-net** | Must start before auth/tools/docs/monitoring/photos |
| **Mosquitto**| None |**creates mqtt-net** | Must start before Frigate |
| **Home Assistant** | Mosquitto (healthy) | automation-net, mqtt-net | MQTT integration |
| **Frigate** | Mosquitto, NFS | security-net, mqtt-net | Events via MQTT, recordings on NFS |
| **Authelia** | Caddy | caddy-net | Forward auth for protected services |
| **Vaultwarden** | None | security-net | Can run standalone |
| **Grafana** | VictoriaMetrics (healthy) | monitoring-net, caddy-net | Dashboards |
| **Immich** | Caddy | photos-net, caddy-net | Photo management |
| **Paperless-ngx** | Caddy | documents-net, caddy-net | Document management |
| **Jellyfin** | NFS | media-net | Media files on NAS |
| **Sonarr/Radarr** | Prowlarr, qBittorrent | media-net | Indexers and downloads |
| **Watchtower** | All others | — | Updates labeled containers, deploy last |

## Critical Path

The minimum services needed for basic functionality:

```text
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

```text
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

### Networking Stack (creates caddy-net)

- **Pi-hole** → standalone, host network
- **Caddy** → creates `caddy-net` external network

### Automation Stack (creates mqtt-net)

- **Mosquitto** → standalone, creates `mqtt-net`
- **Home Assistant** → requires healthy Mosquitto
- **homeassistant-backup** → requires Home Assistant

### Security Stack (joins mqtt-net)

- **Vaultwarden** → standalone
- **Frigate** → requires Mosquitto (automation stack) + NFS mount + mqtt-net
- **vaultwarden-backup** → requires Vaultwarden

### Auth Stack (joins caddy-net)

- **Authelia** → requires caddy-net (forward auth via Caddy)

### Tools Stack (joins caddy-net)

- **Dozzle** → requires caddy-net + Docker socket
- **BentoPDF** → requires caddy-net
- **Homepage** → requires caddy-net + Docker socket

### Documents Stack (joins caddy-net)

- **Paperless-ngx** → requires healthy paperless-db + paperless-redis + caddy-net
- **paperless-db** → standalone (PostgreSQL)
- **paperless-redis** → standalone
- **paperless-backup** → requires Paperless-ngx

### Monitoring Stack

- **VictoriaMetrics** → standalone (TSDB)
- **vmagent** → requires healthy VictoriaMetrics
- **Alertmanager** → standalone (needs ntfy-token file)
- **vmalert** → requires healthy VictoriaMetrics + healthy Alertmanager
- **cAdvisor** → standalone
- **Grafana** → requires healthy VictoriaMetrics + caddy-net

### Photos Stack (joins caddy-net)

- **immich-db** → standalone (PostgreSQL + VectorChord)
- **immich-valkey** → standalone (Redis-compatible)
- **immich-server** → requires healthy immich-db + immich-valkey + caddy-net
- **immich-ml** → standalone
- **immich-backup** → requires healthy immich-db

### Media Stack (NFS-dependent)

- **Prowlarr** → standalone (indexer manager)
- **Sonarr** → requires Prowlarr
- **Radarr** → requires Prowlarr
- **qBittorrent** → standalone
- **Jellyfin** → requires NFS mount for media

### Maintenance Stack

- **Watchtower** → deploy last, requires Docker socket

## Pre-Deployment Checklist

Before deploying any stack:

- [ ] Tailscale/Headscale mesh is operational
- [ ] Target host is accessible via SSH aliases (`vps`, `docker-vm`, `nas`)
- [ ] NFS mounts configured on Docker VM (`/mnt/nas/frigate`, `/mnt/nas/media`, `/mnt/nas/downloads`)
- [ ] `.env` files created from `.env.example` for each stack
- [ ] Secrets generated (admin tokens, passwords — stored in KeePassXC)
- [ ] `ntfy-token` file created on Docker VM for Alertmanager
- [ ] Maintenance stack `.env` has `NTFY_USER` and `NTFY_PASS` for Watchtower notifications
- [ ] Boot orchestrator enabled: `sudo systemctl enable docker-boot-orchestrator`

## References

- [setup-runbook.md](setup-runbook.md) - Detailed first-time setup
- [disaster-recovery.md](../strategy/disaster-recovery.md) - Recovery procedures
- [services.md](../architecture/services.md) - Service descriptions
- [hardware.md](../architecture/hardware.md) - Hardware inventory
