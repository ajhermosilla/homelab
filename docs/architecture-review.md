# Architecture Review

Comprehensive analysis of homelab architecture with domain coexistence strategy. Reviewed 2026-01-14.

## Executive Summary

| Aspect | Status | Confidence |
|--------|--------|------------|
| Architecture Design | Excellent | High |
| Service Selection (22) | Well-balanced | High |
| Network Topology | Clear | High |
| Documentation | 75% complete | Medium |
| Deployment Readiness | 10% (mostly pending) | Low |
| Redundancy Model | Strong | High |
| Security Model | Sound | High |

**Verdict:** Architecture is conceptually excellent but requires clarification on implementation details before deployment.

---

## Current Architecture Overview

### Three-Tier Distributed Model

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
└────────────────────────────────────────┬────────────────────────┘
                                         │
              ┌──────────────────────────┼───────────────────┐
              │                          │                   │
         [Tethering]             [Home ISP/WiFi]     [Vultr VPS]
              │                          │            100.64.0.100
              │                          │
    [Samsung A13]                [Home Router]        [DERP Relay]
              │                   192.168.1.0/24      [Pi-hole]
              │                          │            [Uptime Kuma]
         [Beryl AX]              [Mini PC - Proxmox]  [ntfy]
        192.168.8.1               192.168.1.10        [changedetection]
        /         \                      │            [Restic REST]
       /           \             [OPNsense VM]
    MacBook   RPi 5-Headscale   192.168.1.1
  192.168.8.10  192.168.8.5           │
    [Mobile Kit]                 [vmbr0 - LAN]
                                       │
                       ┌───────────────┼────────────┐
                       │               │            │
                  [Docker VM]    [RPi 4-Start9]  [Old PC/NAS]
                  192.168.1.10   192.168.1.11    192.168.1.12
```

### Environment Summary

| Environment | Hardware | Role | Key Services |
|-------------|----------|------|--------------|
| **Mobile Kit** | RPi 5, MacBook, Beryl AX | Sovereign, portable | Headscale, Pi-hole, soft-serve |
| **Fixed Homelab** | Mini PC, RPi 4, NAS | Always-on, home | Media, Bitcoin, storage, automation |
| **VPS** | Vultr US ($6/mo) | Helper only | DERP, monitoring, scraping |

---

## Strengths

### What's Working Well

| Strength | Description |
|----------|-------------|
| **Three-tier redundancy** | Mobile, Fixed, VPS operate independently |
| **Privacy-first model** | Data stays home, VPS is helper-only |
| **Mesh sovereignty** | Headscale on RPi 5, not vendor lock-in |
| **Service diversity** | Good balance: media, automation, bitcoin, storage |
| **Hardware selection** | Appropriate specs for each role |
| **Documentation** | Comprehensive diagrams and references |

### Key Design Wins

1. **Headscale on RPi 5** - Carry your mesh in your backpack
2. **VPS as helper** - If VPS dies, mesh keeps working
3. **Pi-hole everywhere** - Consistent DNS/ad-blocking across environments
4. **Start9 for Bitcoin** - Maximum sovereignty, privacy-first
5. **Syncthing over Nextcloud** - Peer-to-peer, no central server

---

## Gaps & Issues Identified

### Critical (Fix Before Deployment)

| Issue | Impact | Solution | Status |
|-------|--------|----------|--------|
| **Headscale backup only daily** | Lose DB = re-register ALL devices | Increase to hourly, add restore testing | ✅ Fixed |
| **No disaster recovery runbook** | Can't recover from failures | Document recovery procedures | ✅ Fixed |
| **Caddy reverse proxy undefined** | Can't expose services externally | Create Caddyfile with subdomain mappings | ✅ Fixed |
| **MQTT missing** | Home Assistant ↔ Frigate broken | Add Mosquitto to Docker VM | ✅ Fixed |

### High Priority

| Issue | Impact | Solution |
|-------|--------|----------|
| **Old PC/NAS specs TBD** | Can't plan storage/UPS properly | Document hardware |
| **VPS RAM tight (~150MB headroom)** | May OOM under load | Audit actual usage, consider upgrade |
| **No docker-compose files** | Can't deploy services | Create compose files for each environment |
| **Certificate strategy unclear** | SSL/TLS for public services | Document Caddy auto-SSL with domains |

### Medium Priority

| Issue | Impact | Solution |
|-------|--------|----------|
| **No VLAN documentation** | IoT isolation unclear | Document OPNsense VLAN strategy |
| **Monitoring alerts undefined** | Don't know when things break | Configure Uptime Kuma + ntfy |
| **Backup testing absent** | Untested backups = no backups | Create restore test procedure |
| **Port 8080 conflict** | qBittorrent vs Pi-hole alt | Reassign one service |

### Low Priority (Future)

| Issue | Impact | Solution |
|-------|--------|----------|
| **Tailscale IP assignment policy** | New device confusion | Document IP allocation scheme |
| **Bitcoin pruning strategy** | Disk may fill up | Document blockchain management |
| **Syncthing limitations** | No WebDAV/CalDAV | Accept limitation or add solution |

---

## Domain Coexistence Strategy

### The Two-Domain Model

| Domain | Purpose | Audience |
|--------|---------|----------|
| **nanduti.io** | Personal homelab infrastructure | You, family |
| **verava.net** | Business, customer-facing | Customers, public |

### Why Two Domains?

```
┌─────────────────────────────────────────────────────────────────┐
│                     SEPARATION OF CONCERNS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  nanduti.io                          verava.net                  │
│  ───────────                         ──────────                  │
│  • Personal infrastructure           • Professional presence     │
│  • Homelab services                  • Customer-facing apps      │
│  • Geek cred                         • Business credibility      │
│  • Guarani cultural flex             • Easy to spell/remember    │
│  • ~$30/year                         • ~$12/year                 │
│                                                                  │
│  "ssh admin@nanduti.io"              "Visit verava.net"          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Subdomain Architecture

#### nanduti.io (Personal Infrastructure)

```
nanduti.io
├── hs.nanduti.io        → Headscale (RPi 5)
├── dns.nanduti.io       → Pi-hole (all environments)
├── git.nanduti.io       → soft-serve (MacBook)
├── home.nanduti.io      → Home Assistant (Docker VM)
├── media.nanduti.io     → Jellyfin (Docker VM)
├── vault.nanduti.io     → Vaultwarden (Docker VM) [PUBLIC]
├── status.nanduti.io    → Uptime Kuma (VPS) [PUBLIC]
├── notify.nanduti.io    → ntfy (VPS) [PUBLIC]
├── btc.nanduti.io       → Start9 (RPi 4)
├── nas.nanduti.io       → Syncthing/Samba (NAS)
└── watch.nanduti.io     → changedetection (VPS)
```

#### verava.net (Business)

```
verava.net
├── www.verava.net       → Company landing page
├── api.verava.net       → Customer APIs
├── app.verava.net       → Web application / SaaS
├── docs.verava.net      → Documentation
└── demo.verava.net      → Sales demos
```

### Service Access Model

| Service | Public | Tailscale | Rationale |
|---------|--------|-----------|-----------|
| **Vaultwarden** | Yes | Yes | Need passwords everywhere |
| **Uptime Kuma** | Yes (read-only) | Yes | Public status page |
| **ntfy** | Yes | Yes | Push notifications from anywhere |
| **Jellyfin** | No | Yes | Media is personal |
| **Home Assistant** | No | Yes | Home automation is private |
| **Start9** | No | Yes | Bitcoin = maximum privacy |
| **soft-serve** | No | Yes | Code is private |
| **Syncthing** | No | Yes | Files are private |
| **www.verava.net** | Yes | No | Public website |
| **api.verava.net** | Yes | No | Customer API |

---

## DNS Architecture with Domains

### Cloudflare Configuration

```
┌──────────────────────────────────────────────────────────────────┐
│                     Cloudflare DNS                                │
│                   (Registrar + DNS + CDN)                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  nanduti.io                          verava.net                   │
│  ───────────                         ──────────                   │
│  A      @     → VPS_IP               A      @     → VPS_IP        │
│  A      *     → VPS_IP (wildcard)    A      *     → VPS_IP        │
│  AAAA   @     → VPS_IPv6             AAAA   @     → VPS_IPv6      │
│  AAAA   *     → VPS_IPv6             AAAA   *     → VPS_IPv6      │
│                                                                   │
│  Proxy: Orange cloud (CDN) for public services                   │
│  Proxy: Grey cloud (DNS only) for Tailscale services             │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Traffic Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                    │
│                                                                          │
│         nanduti.io (homelab)              verava.net (business)          │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                          [Cloudflare DNS]
                                 │
                          [VPS - Caddy]
                         100.64.0.100
                    ┌──────────┴──────────┐
                    │                     │
              [Public Services]    [Tailscale Mesh]
              ─────────────────    ────────────────
              status.nanduti.io    All internal
              notify.nanduti.io    services via
              vault.nanduti.io     100.64.0.x
              www.verava.net
              api.verava.net
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    │                     │                     │
             [Mobile Kit]          [Fixed Homelab]        [VPS Helper]
             RPi 5 + MacBook       Mini PC + RPi 4        Vultr US
             100.64.0.1-2          + NAS                  100.64.0.100
                                   100.64.0.10-12
```

### Caddy Reverse Proxy Config (Proposed)

```caddyfile
# nanduti.io - Public services
vault.nanduti.io {
    reverse_proxy 100.64.0.10:8843
}

status.nanduti.io {
    reverse_proxy localhost:3001
}

notify.nanduti.io {
    reverse_proxy localhost:80
}

# verava.net - Business services
www.verava.net {
    root * /var/www/verava
    file_server
}

api.verava.net {
    reverse_proxy localhost:8080
}

# Catch-all redirect
nanduti.io {
    redir https://status.nanduti.io
}

verava.net {
    redir https://www.verava.net
}
```

---

## Unified Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                    │
│                                                                          │
│              nanduti.io                      verava.net                  │
│         (Personal Homelab)              (Business/Customers)             │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                          ┌──────┴──────┐
                          │ Cloudflare  │
                          │  DNS + CDN  │
                          └──────┬──────┘
                                 │
                          ┌──────┴──────┐
                          │ VPS (Caddy) │
                          │100.64.0.100 │
                          │             │
                          │ • DERP      │
                          │ • Pi-hole   │
                          │ • Uptime    │
                          │ • ntfy      │
                          │ • change    │
                          │   detection │
                          │ • Restic    │
                          └──────┬──────┘
                                 │
                          [Tailscale Mesh]
                           100.64.0.0/10
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
   ┌──────┴──────┐        ┌──────┴──────┐        ┌──────┴──────┐
   │ Mobile Kit  │        │Fixed Homelab│        │   (VPS)     │
   │             │        │             │        │  Already    │
   │ RPi 5       │        │ Mini PC     │        │  shown      │
   │ 100.64.0.1  │        │ (Proxmox)   │        │  above      │
   │ • Headscale │        │ 100.64.0.10 │        │             │
   │ • Pi-hole   │        │             │        └─────────────┘
   │             │        │ ┌─────────┐ │
   │ MacBook     │        │ │OPNsense │ │
   │ 100.64.0.2  │        │ │  VM     │ │
   │ • soft-serve│        │ └─────────┘ │
   │             │        │             │
   │ Beryl AX    │        │ ┌─────────┐ │
   │ 192.168.8.1 │        │ │Docker VM│ │
   │             │        │ │Pi-hole  │ │
   │ Samsung A13 │        │ │Caddy    │ │
   │ (tether)    │        │ │Jellyfin │ │
   └─────────────┘        │ │*arr     │ │
                          │ │HA       │ │
                          │ │Vault    │ │
                          │ └─────────┘ │
                          │             │
                          │ RPi 4       │
                          │ 100.64.0.11 │
                          │ • Start9    │
                          │ • Bitcoin   │
                          │ • Lightning │
                          │             │
                          │ NAS         │
                          │ 100.64.0.12 │
                          │ • Samba     │
                          │ • Syncthing │
                          │ • Frigate   │
                          │ • Restic    │
                          └─────────────┘
```

---

## Improvement Roadmap

### Phase 1: Critical Fixes (Before Deployment) ✅ COMPLETE

| # | Task | Deliverable | Status |
|---|------|-------------|--------|
| 1 | Increase Headscale backup frequency | Backup sidecar in docker-compose | ✅ Done |
| 2 | Create disaster recovery runbook | `docs/disaster-recovery.md` | ✅ Done |
| 3 | Add MQTT broker to services | Update `services.md`, compose file | ✅ Done |
| 4 | Document Caddy configuration | `docs/caddy-config.md` | ✅ Done |

### Phase 2: High Priority (During Deployment)

| # | Task | Deliverable | Priority |
|---|------|-------------|----------|
| 5 | Document NAS hardware specs | Update `hardware.md` | High |
| 6 | Create mobile kit compose files | `docker/mobile/rpi5/` | High |
| 7 | Create VPS compose files | `docker/vps/` | High |
| 8 | Audit VPS RAM usage | Document actual consumption | High |
| 9 | Plan domain DNS records | Update `domain-research.md` | High |

### Phase 3: Medium Priority (Post-Deployment)

| # | Task | Deliverable | Priority |
|---|------|-------------|----------|
| 10 | Document VLAN strategy | `docs/network-security.md` | Medium |
| 11 | Configure monitoring alerts | Uptime Kuma + ntfy rules | Medium |
| 12 | Create backup test procedure | `docs/backup-testing.md` | Medium |
| 13 | Resolve port 8080 conflict | Update `services.md` | Medium |

### Phase 4: Future Enhancements

| # | Task | Deliverable | Priority |
|---|------|-------------|----------|
| 14 | Tailscale IP allocation policy | Document in `hardware.md` | Low |
| 15 | Bitcoin node management guide | `docs/bitcoin-node.md` | Low |
| 16 | Ansible playbooks | `ansible/` directory | Low |
| 17 | Unified network diagram tool | Draw.io or Mermaid | Low |

---

## Service Inventory (22 Services)

### By Category

| Category | Services | Count |
|----------|----------|-------|
| Networking | Headscale, Pi-hole (x3), Caddy, DERP | 6 |
| Media | Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent | 5 |
| Bitcoin | Bitcoin Core, LND, Electrum Server | 3 |
| Storage | Samba, Syncthing | 2 |
| Security | Vaultwarden, Frigate | 2 |
| Automation | Home Assistant | 1 |
| Monitoring | Uptime Kuma, ntfy | 2 |
| Backup | Restic REST (x2) | 2 |
| Scraping | changedetection | 1 |
| Development | soft-serve | 1 |

### Missing Services (To Add)

| Service | Purpose | Location | Priority |
|---------|---------|----------|----------|
| **Mosquitto** | MQTT broker for HA ↔ Frigate | Docker VM | Critical |
| **Prometheus** | Metrics collection (optional) | Docker VM | Low |
| **Grafana** | Metrics visualization (optional) | Docker VM | Low |

---

## Cost Summary

### Monthly

| Item | Cost |
|------|------|
| VPS (Vultr) | $6.00 |
| Domain (nanduti.io) | $2.50 |
| Domain (verava.net) | $1.00 |
| **Total** | **~$9.50/mo** |

### Annual

| Item | Cost |
|------|------|
| VPS | $72.00 |
| nanduti.io | $30.00 |
| verava.net | $12.00 |
| **Total** | **~$114/yr** |

---

## Critical Success Factors

These MUST work for the architecture to function:

| Factor | Dependency | Backup Plan |
|--------|------------|-------------|
| Headscale DB | Entire mesh | Hourly backups to NAS + VPS |
| Unbound on OPNsense | Privacy DNS | Fallback to public DNS |
| Restic encryption keys | All backups | Store in Vaultwarden + paper |
| Tailscale connectivity | Inter-device comms | DERP relay on VPS |
| OPNsense WAN passthrough | Network isolation | Alternative: bridge mode |

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-14 | nanduti.io for homelab | Guarani "web" metaphor, cultural flex |
| 2026-01-14 | verava.net for business | Professional, easy to spell |
| 2026-01-14 | Both domains via Cloudflare | At-cost pricing, DNS + CDN included |
| 2026-01-14 | Public: vault, status, notify | Need access from anywhere |
| 2026-01-14 | Private: media, home, bitcoin | Personal/sensitive data |

---

## Next Actions

| Priority | Action | Blocks |
|----------|--------|--------|
| 1 | Purchase nanduti.io + verava.net | Nothing |
| 2 | Create disaster recovery runbook | Nothing |
| 3 | Create Caddy config documentation | Domain purchase |
| 4 | Add MQTT to service inventory | Nothing |
| 5 | Create mobile kit compose files | PSU arrival |

---

## References

- [Cloudflare Registrar](https://www.cloudflare.com/products/registrar/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Headscale Documentation](https://headscale.net/)
- [Tailscale DERP](https://tailscale.com/kb/1118/custom-derp-servers/)
- [Mosquitto MQTT](https://mosquitto.org/)
