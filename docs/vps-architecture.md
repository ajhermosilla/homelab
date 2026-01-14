# VPS Architecture

Cloud helper node for NAT traversal, monitoring, and scraping - no personal data at rest.

**Key principle:** Headscale runs on RPi 5 (mobile kit). VPS is a helper, not critical infrastructure. If VPS dies, your mesh still works.

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

### Tier 1: Network Helpers (No Personal Data)

| Service | Port | Purpose | RAM |
|---------|------|---------|-----|
| DERP Relay | 443, 3478 | Tailscale NAT traversal relay | ~30MB |
| Uptime Kuma | 3001 | Monitor homelab externally | ~100MB |
| ntfy | 80 | Push notifications | ~50MB |

*Note: Headscale runs on RPi 5 (mobile kit), not here.*

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
    [DERP Relay]      [Uptime Kuma]    [changedetection]
    (NAT helper)         [ntfy]         [Browserless]
                            |
                     [Tailscale Mesh]
                            |
        +-------------------+-------------------+
        |                                       |
   [Mobile Kit]                          [Fixed Homelab]
   RPi 5 (HEADSCALE) + MacBook           Mini PC + RPi 4
   100.64.0.1-2                          100.64.0.10-11
```

**Flow:** RPi 5 runs Headscale (coordination). VPS DERP relay helps when direct connections fail (NAT/firewall).

## Privacy Model

### What VPS Sees (Helper Only)

- DERP relay traffic (encrypted, can't read contents)
- Which websites you monitor for changes
- Encrypted backup blobs (client-side encryption)
- Uptime check results (is X online?)

### What VPS Never Sees

- Actual file contents
- Passwords, documents, media
- Traffic between mesh devices (WireGuard encrypted)
- Backup contents (you hold the keys)
- Mesh coordination metadata (that's on RPi 5)

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
    ├── derp/
    │   └── docker-compose.yml  # DERP relay
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
| 4 | Deploy DERP relay | Pending |
| 5 | Deploy Uptime Kuma + ntfy | Pending |
| 6 | Deploy changedetection.io | Pending |
| 7 | Configure Restic REST server | Pending |
| 8 | Join VPS to Tailscale (RPi 5 Headscale) | Pending |
| 9 | Configure DERP in Headscale | Pending |

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
- [ ] Grafana for VPS metrics
- [ ] n8n for advanced automation workflows
- [ ] Additional DERP relays in other regions

## References

- [Tailscale DERP](https://tailscale.com/kb/1118/custom-derp-servers/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [ntfy](https://ntfy.sh/)
- [changedetection.io](https://changedetection.io/)
- [Restic REST Server](https://github.com/restic/rest-server)
- [Vultr](https://www.vultr.com/)
