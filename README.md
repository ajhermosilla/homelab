# Homelab

Personal infrastructure as code. Mobile kit, fixed homelab, and VPS.

## Quick Links

| Need to... | Go to... |
|------------|----------|
| See all services | [docs/services.md](docs/services.md) |
| Check hardware specs | [docs/hardware.md](docs/hardware.md) |
| Deploy fixed homelab | [docs/fixed-homelab.md](docs/fixed-homelab.md) |
| Set up Proxmox | [docs/proxmox-setup.md](docs/proxmox-setup.md) |
| Configure OPNsense | [docs/opnsense-setup.md](docs/opnsense-setup.md) |

## Architecture

```
[Mobile Kit]              [Fixed Homelab]              [VPS]
On-demand                 24/7                         24/7
├── MacBook Air           ├── Proxmox (Mini PC)        ├── Headscale
├── Beryl AX Router       │   ├── OPNsense VM          ├── Caddy
└── Samsung A13           │   └── Docker VM            ├── DERP Relay
                          ├── RPi 5 (OpenClaw)         ├── Uptime Kuma
                          ├── Start9 (RPi 4)           └── ntfy
                          └── NAS (Mini-ITX)
```

**24 services** across 3 environments. See [docs/services.md](docs/services.md) for full list.

## Documentation

### Core

| Document | Description |
|----------|-------------|
| [services.md](docs/services.md) | Service inventory, ports, dependencies |
| [hardware.md](docs/hardware.md) | Device specs, Tailscale IPs, power |
| [fixed-homelab.md](docs/fixed-homelab.md) | Fixed site architecture |
| [mobile-homelab.md](docs/mobile-homelab.md) | Portable kit setup |
| [vps-architecture.md](docs/vps-architecture.md) | Cloud infrastructure |

### Setup Guides

| Document | Description |
|----------|-------------|
| [proxmox-setup.md](docs/proxmox-setup.md) | Proxmox VE installation |
| [opnsense-setup.md](docs/opnsense-setup.md) | OPNsense router config |
| [nfs-setup.md](docs/nfs-setup.md) | NFS for Frigate recordings |
| [vlan-design.md](docs/vlan-design.md) | Network segmentation |
| [nut-config.md](docs/nut-config.md) | UPS graceful shutdown |

### Strategy

| Document | Description |
|----------|-------------|
| [architecture-review.md](docs/architecture-review.md) | Design decisions |
| [domain-strategy.md](docs/domain-strategy.md) | DNS and domain plan |
| [certificate-strategy.md](docs/certificate-strategy.md) | TLS certificates |
| [dns-architecture.md](docs/dns-architecture.md) | DNS resolution flow |
| [monitoring-strategy.md](docs/monitoring-strategy.md) | Alerting and metrics |
| [disaster-recovery.md](docs/disaster-recovery.md) | Backup and restore |
| [secrets-management.md](docs/secrets-management.md) | Credential handling |
| [security-hardening.md](docs/security-hardening.md) | 2FA, firewall, fail2ban |

### Operations

| Document | Description |
|----------|-------------|
| [backup-test-procedure.md](docs/backup-test-procedure.md) | Monthly backup tests |
| [home-devices.md](docs/home-devices.md) | Family device inventory |
| [caddy-config.md](docs/caddy-config.md) | Reverse proxy patterns |

### Reference

| Document | Description |
|----------|-------------|
| [tailscale-primer.md](docs/tailscale-primer.md) | Tailscale/Headscale intro |
| [homelab-evaluation.md](docs/homelab-evaluation.md) | Hardware comparisons |
| [rpi5-case-research.md](docs/rpi5-case-research.md) | RPi 5 case options |
| [branding.md](docs/branding.md) | cronova.dev identity |

### Sessions

Daily work logs in [docs/sessions/](docs/sessions/).

## Directory Structure

```
homelab/
├── docker/                    # Docker Compose files
│   ├── mobile/               # Mobile kit services
│   ├── fixed/                # Fixed homelab services
│   │   ├── docker-vm/        # Containers on Docker VM
│   │   └── nas/              # Containers on NAS
│   ├── vps/                  # VPS services
│   └── git/                  # soft-serve (MacBook)
├── ansible/                   # Automation playbooks
├── docs/                      # Documentation
│   └── sessions/             # Daily work logs
├── scripts/                   # Utility scripts
└── CLAUDE.md                  # AI assistant context
```

See [docker/README.md](docker/README.md) for Docker network strategy and deployment order.

## Deployment Order

1. **VPS** - Headscale first (enables mesh network)
2. **Fixed Homelab**
   - Proxmox on Mini PC
   - OPNsense VM
   - Docker VM with services
   - NAS services
   - Start9 on RPi 4
3. **Mobile Kit** - MacBook Air + Beryl AX

## Key Services

| Service | Purpose | Access |
|---------|---------|--------|
| Headscale | Tailscale coordination | hs.cronova.dev |
| Pi-hole | DNS ad-blocking | Local + Tailscale |
| Jellyfin | Media streaming | media.cronova.dev |
| Home Assistant | Automation | home.cronova.dev |
| Vaultwarden | Passwords | vault.cronova.dev |
| Frigate | NVR with AI | Local only |
| Uptime Kuma | Monitoring | Tailscale |

## Network

- **Domain**: cronova.dev (Cloudflare)
- **Internal**: cronova.local
- **Tailscale**: 100.64.0.0/10
- **Local**: 192.168.0.0/24

VLANs:
- VLAN 1: Management (servers)
- VLAN 10: IoT (cameras, isolated)
- VLAN 20: Guest (internet only)

## Status

| Environment | Status |
|-------------|--------|
| VPS | Active (Headscale, Caddy, Uptime Kuma, ntfy) |
| Fixed Homelab | Partial (Proxmox + OPNsense active; Pi-hole, Caddy, Vaultwarden on Docker VM; RPi 5 pending setup) |
| Mobile Kit | Pending |

---

**Owner**: Augusto Hermosilla
**Contact**: augusto@hermosilla.me
