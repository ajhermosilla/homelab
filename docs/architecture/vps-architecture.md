# VPS Architecture

Cloud node for Tailscale coordination, monitoring, and external services - minimal personal data at rest.

**Key principle:** Headscale runs on VPS for 24/7 mesh availability. Mobile kit operates on-demand (7AM-7PM). If VPS dies, mesh clients still work with cached keys but can't add new nodes.

## Goals

- 24/7 Tailscale mesh coordination
- External monitoring of homelab
- Privacy/sovereignty preserved (data stays at home)
- US IP for web scraping
- ~$6/month budget

## Provider

| Provider | Plan | Specs | Price |
|----------|------|-------|-------|

| **Vultr** | High Frequency | 1 vCPU, 1GB RAM, 32GB NVMe | $6/mo |

**Location:** USA (for web scraping and low latency)

## Services

### Tier 1: Network Infrastructure

| Service | Port | Purpose | Status |
|---------|------|---------|--------|

| Headscale | 8080 | Tailscale coordination server | Active |
| Caddy | 80, 443 | Reverse proxy, auto-SSL | Active |

### Tier 2: Monitoring

| Service | Port | Purpose | Status |
|---------|------|---------|--------|

| Uptime Kuma | 3001 | Status monitoring | Active |
| ntfy | 80 | Push notifications | Active |

### Tier 3: Future Services

| Service | Port | Purpose | Status |
|---------|------|---------|--------|

| changedetection.io | 5000 | Website change monitoring | Planned |
| DERP Relay | 3478/udp | Tailscale NAT traversal | Planned |
| Restic REST Server | 8000 | Encrypted backup target | Planned |

## Architecture Diagram

```json
                        [Internet]
                            |
                     [Vultr VPS - US]
                      <VPS_PUBLIC_IP>
                      100.77.172.46 (TS)
                            |
    +------------+----------+----------+------------+
    |            |          |          |            |
[Headscale]  [Caddy]  [Uptime Kuma]  [ntfy]    [Future]
(TS coord)  (proxy)   (monitoring) (alerts)  (DERP, etc)
                            |
                     [Tailscale Mesh]
                            |
        +-------------------+-------------------+
        |                   |                   |
   [Mobile Kit]        [Devices]         [Fixed Homelab]
   Beryl AX + RPi 5    MacBook, Phone    Proxmox + Docker VM
```

**Flow:** VPS Headscale coordinates mesh. All devices connect via Tailscale. VPS acts as exit node when needed.

## Endpoints

| Subdomain | Service | Notes |
|-----------|---------|-------|

| hs.cronova.dev | Headscale | Tailscale coordination |
| status.cronova.dev | Uptime Kuma | Public status page |
| notify.cronova.dev | ntfy | Push notifications |
| cronova.dev | Landing page | Static HTML |

## Privacy Model

### What VPS Sees

- Tailscale mesh metadata (which devices are online)
- Which websites you monitor for uptime
- Notification content (you control what's sent)

### What VPS Never Sees

- Actual file contents from home
- Traffic between mesh devices (WireGuard encrypted)
- Passwords, documents, media

### Trust Level: Moderate

- VPS is assumed potentially compromised
- No sensitive data at rest
- Mesh traffic is end-to-end encrypted

## Docker Structure

```text
docker/vps/
├── networking/
│   ├── headscale/
│   │   ├── docker-compose.yml
│   │   ├── backup.sh
│   │   └── config/
│   └── caddy/
│       ├── docker-compose.yml
│       ├── Caddyfile
│       └── www/
└── monitoring/
    └── docker-compose.yml    # Uptime Kuma, ntfy
```

## Deployment Status

| Phase | Task | Status |
|-------|------|--------|

| 1 | Create Vultr account, deploy VPS | Done |
| 2 | Basic hardening (SSH keys, firewall) | Done |
| 3 | Install Docker | Done |
| 4 | Deploy Headscale | Done |
| 5 | Deploy Caddy reverse proxy | Done |
| 6 | Deploy Uptime Kuma | Done |
| 7 | Deploy ntfy | Done |
| 8 | Deploy changedetection.io | Pending |
| 9 | Configure DERP relay | Pending |

## Security Hardening

- SSH key auth only (no password)
- UFW firewall (only needed ports)
- Fail2ban for SSH
- Automatic security updates
- No root login
- Tailscale for private service access

## Backup Strategy

- Headscale: Hourly backup via sidecar container
- Backup location: `/home/linuxuser/backups/headscale/`
- See `docker/vps/networking/headscale/backup.sh`

## Cost

| Item | Monthly |
|------|---------|

| Vultr VPS (1GB) | $6.00 |
| Domain (cronova.dev) | ~$1.00 |
| **Total** | ~$7.00 |

## Future Enhancements

- [ ] Deploy changedetection.io for website monitoring
- [ ] Add DERP relay for better NAT traversal
- [ ] Grafana for VPS metrics
- [ ] Restic REST server for encrypted backups

## References

- [Headscale Documentation](https://headscale.net/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [ntfy](https://ntfy.sh/)
- [Vultr](https://www.vultr.com/)
