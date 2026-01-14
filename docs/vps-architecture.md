# VPS Architecture

Cloud node for coordination, monitoring, and scraping - no personal data at rest.

## Goals

- Multiple points of failure (redundancy)
- Privacy/sovereignty preserved (data stays at home)
- US IP for web scraping
- External monitoring of homelab
- ~$6/month budget

## Provider Comparison

| Provider | Plan | Specs | Price | Notes |
|----------|------|-------|-------|-------|
| **Vultr** | High Frequency | 1 vCPU, 1GB RAM, 32GB NVMe | $6/mo | Faster CPU, recommended |
| Vultr | Regular Cloud | 1 vCPU, 1GB RAM, 25GB SSD | $6/mo | Standard option |
| DigitalOcean | Basic Droplet | 1 vCPU, 1GB RAM, 25GB SSD | $6/mo | Better docs/community |
| Vultr | IPv6 only | 1 vCPU, 512MB RAM, 10GB | $2.50/mo | If IPv6-only works |

**Decision:** Vultr US (burn credits first, better price/performance)

## Services

### Tier 1: Coordination (No Personal Data)

| Service | Port | Purpose | RAM |
|---------|------|---------|-----|
| Headscale | 443, 3478 | Tailscale coordination server | ~50MB |
| DERP Relay | 3478 | NAT traversal relay | ~30MB |
| Uptime Kuma | 3001 | Monitor homelab externally | ~100MB |
| ntfy | 80 | Push notifications | ~50MB |

### Tier 2: Web Scraping (US IP)

| Service | Port | Purpose | RAM |
|---------|------|---------|-----|
| changedetection.io | 5000 | Website change monitoring | ~100MB |
| Browserless | 3000 | Headless Chrome (optional) | ~500MB |

### Tier 3: Backup Relay (Encrypted)

| Service | Port | Purpose | RAM |
|---------|------|---------|-----|
| Restic REST Server | 8000 | Encrypted backup target | ~50MB |

## Architecture Diagram

```
                        [Internet]
                            |
                     [Vultr VPS - US]
                      100.64.0.100
                            |
         +------------------+------------------+
         |                  |                  |
    [Headscale]       [Uptime Kuma]    [changedetection]
    [DERP Relay]         [ntfy]         [Browserless]
                            |
                     [Tailscale Mesh]
                            |
        +-------------------+-------------------+
        |                                       |
   [Mobile Kit]                          [Fixed Homelab]
   MacBook + RPi 5                       Mini PC + RPi 4
   100.64.0.1-2                          100.64.0.10-11
```

## Privacy Model

### What VPS Sees (Coordination Only)

- Device names and Tailscale IPs
- When devices connect/disconnect
- Which websites you monitor for changes
- Encrypted backup blobs (client-side encryption)

### What VPS Never Sees

- Actual file contents
- Passwords, documents, media
- Traffic between mesh devices (WireGuard encrypted)
- Backup contents (you hold the keys)

### Trust Level: Moderate

- VPS is assumed potentially compromised
- No sensitive data at rest
- All backups encrypted before leaving home
- Coordination metadata is acceptable risk

## Redundancy Matrix

| Failure | Impact | Recovery |
|---------|--------|----------|
| VPS down | Mesh keeps working (cached keys), no external monitoring | Wait or rebuild VPS |
| Home down | Mobile kit self-contained | Nothing to do |
| Mobile down | Home still works | Nothing to do |
| All down | Rebuild from any node | Restore from backups |

## Docker Structure

```
docker/
└── vps/
    ├── headscale/
    │   └── docker-compose.yml
    ├── monitoring/
    │   └── docker-compose.yml  # uptime-kuma + ntfy
    ├── scraping/
    │   └── docker-compose.yml  # changedetection
    └── backup/
        └── docker-compose.yml  # restic-rest-server
```

## Deployment Order

| Phase | Task | Status |
|-------|------|--------|
| 1 | Create Vultr account, deploy VPS | Pending |
| 2 | Basic hardening (SSH keys, firewall) | Pending |
| 3 | Install Docker | Pending |
| 4 | Deploy Headscale + DERP | Pending |
| 5 | Deploy Uptime Kuma + ntfy | Pending |
| 6 | Deploy changedetection.io | Pending |
| 7 | Configure Restic REST server | Pending |
| 8 | Join all devices to mesh | Pending |

## Security Hardening

- SSH key auth only (no password)
- UFW firewall (only needed ports)
- Fail2ban for SSH
- Automatic security updates
- No root login
- Tailscale ACLs for service access

## Cost Breakdown

| Item | Monthly |
|------|---------|
| Vultr VPS (1GB) | $6.00 |
| Domain (optional) | ~$1.00 |
| **Total** | ~$7.00 |

## Future Enhancements

- [ ] Add Caddy as reverse proxy with auto-SSL
- [ ] Headscale-UI for web management
- [ ] Grafana for VPS metrics
- [ ] Automated backups of Headscale DB to home
- [ ] n8n for advanced automation workflows

## References

- [Headscale Docs](https://headscale.net/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [ntfy](https://ntfy.sh/)
- [changedetection.io](https://changedetection.io/)
- [Restic REST Server](https://github.com/restic/rest-server)
- [Vultr](https://www.vultr.com/)
