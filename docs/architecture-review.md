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
              │                          │            100.77.172.46
              │                          │
    [Samsung A13]                [Home Router]        [DERP Relay]
              │                   192.168.0.0/24      [Pi-hole]
              │                          │            [Uptime Kuma]
         [Beryl AX]              [Mini PC - Proxmox]  [ntfy]
        192.168.8.1               192.168.0.237       [changedetection]
        /         \                      │            [Restic REST]
       /           \             [OPNsense VM]
    MacBook                192.168.0.1
  192.168.8.10  192.168.8.5           │
    [Mobile Kit]                 [vmbr0 - LAN]
                                       │
                       ┌───────────────┼────────────┐
                       │               │            │
                  [Docker VM]    [RPi 4-Start9]  [Old PC/NAS]
                  192.168.0.10   192.168.0.11    192.168.0.12
```

### Environment Summary

| Environment | Hardware | Role | Key Services |
|-------------|----------|------|--------------|
| **Mobile Kit** | MacBook, Beryl AX, Samsung A13 | On-demand, portable | soft-serve |
| **Fixed Homelab** | Mini PC, RPi 4, NAS | Always-on (24/7) | Media, Bitcoin, storage, automation |
| **VPS** | Vultr US ($6/mo) | Always-on (24/7) | Headscale, DERP, monitoring |

---

## Strengths

### What's Working Well

| Strength | Description |
|----------|-------------|
| **Three-tier redundancy** | Mobile, Fixed, VPS operate independently |
| **Privacy-first model** | Data stays home, VPS is helper-only |
| **Mesh sovereignty** | Headscale self-hosted on VPS, not vendor lock-in |
| **Service diversity** | Good balance: media, automation, bitcoin, storage |
| **Hardware selection** | Appropriate specs for each role |
| **Documentation** | Comprehensive diagrams and references |

### Key Design Wins

1. **Headscale on VPS** - 24/7 mesh coordination, mobile kit can be off
2. **Mobile kit on-demand** - Saves energy/heat, mesh still works when off
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
| **cronova.dev** | Personal homelab infrastructure | You, family |
| **verava.ai** | Business, customer-facing | Customers, public |

### Why Two Domains?

```
┌─────────────────────────────────────────────────────────────────┐
│                     SEPARATION OF CONCERNS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  cronova.dev                          verava.ai                  │
│  ───────────                         ──────────                  │
│  • Personal infrastructure           • Professional presence     │
│  • Homelab services                  • Customer-facing apps      │
│  • Geek cred                         • Business credibility      │
│  • Guarani cultural flex             • Easy to spell/remember    │
│  • ~$30/year                         • ~$12/year                 │
│                                                                  │
│  "ssh admin@cronova.dev"              "Visit verava.ai"          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Subdomain Architecture

#### cronova.dev (Personal Infrastructure)

```
cronova.dev
├── hs.cronova.dev        → Headscale (VPS)
├── dns.cronova.dev       → Pi-hole (all environments)
├── git.cronova.dev       → soft-serve (MacBook)
├── jara.cronova.dev      → Home Assistant (Docker VM)
├── yrasema.cronova.dev     → Jellyfin (Docker VM)
├── vault.cronova.dev     → Vaultwarden (Docker VM) [PUBLIC]
├── status.cronova.dev    → Uptime Kuma (VPS) [PUBLIC]
├── notify.cronova.dev    → ntfy (VPS) [PUBLIC]
├── btc.cronova.dev       → Start9 (RPi 4)
├── nas.cronova.dev       → Syncthing/Samba (NAS)
└── watch.cronova.dev     → changedetection (VPS)
```

#### verava.ai (Business)

```
verava.ai
├── www.verava.ai       → Company landing page
├── api.verava.ai       → Customer APIs
├── app.verava.ai       → Web application / SaaS
├── docs.verava.ai      → Documentation
└── demo.verava.ai      → Sales demos
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
| **www.verava.ai** | Yes | No | Public website |
| **api.verava.ai** | Yes | No | Customer API |

---

## DNS Architecture with Domains

### Cloudflare Configuration

```
┌──────────────────────────────────────────────────────────────────┐
│                     Cloudflare DNS                                │
│                   (Registrar + DNS + CDN)                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  cronova.dev                          verava.ai                   │
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
│         cronova.dev (homelab)              verava.ai (business)          │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                          [Cloudflare DNS]
                                 │
                          [VPS - Caddy]
                         100.77.172.46
                    ┌──────────┴──────────┐
                    │                     │
              [Public Services]    [Tailscale Mesh]
              ─────────────────    ────────────────
              status.cronova.dev    All internal
              notify.cronova.dev    services via
              vault.cronova.dev     100.64.0.x
              www.verava.ai
              api.verava.ai
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    │                     │                     │
             [Mobile Kit]          [Fixed Homelab]        [VPS Helper]
             MacBook + Beryl AX    Mini PC + RPi 4        Vultr US
             100.64.0.1-2          + NAS                  100.77.172.46
                                   100.68.63.168+
```

### Caddy Reverse Proxy Config (Proposed)

```caddyfile
# cronova.dev - Public services
vault.cronova.dev {
    reverse_proxy 100.68.63.168:8843
}

status.cronova.dev {
    reverse_proxy localhost:3001
}

notify.cronova.dev {
    reverse_proxy localhost:80
}

# verava.ai - Business services
www.verava.ai {
    root * /var/www/verava
    file_server
}

api.verava.ai {
    reverse_proxy localhost:8080
}

# Catch-all redirect
cronova.dev {
    redir https://status.cronova.dev
}

verava.ai {
    redir https://www.verava.ai
}
```

---

## Unified Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                    │
│                                                                          │
│              cronova.dev                      verava.ai                  │
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
                          │100.77.172.46│
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
   │             │        │ Mini PC     │        │  shown      │
   │             │        │ (Proxmox)   │        │  above      │
   │             │        │100.78.12.241│        │             │
   │             │        │             │        └─────────────┘
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
                          │ RPi 5       │
                          │ 192.168.0.20│
                          │ • OpenClaw  │
                          │             │
                          │ RPi 4       │
                          │ 100.64.0.11 │
                          │ • Start9    │
                          │ • Bitcoin   │
                          │ • Lightning │
                          │             │
                          │ NAS         │
                          │ 100.82.77.97 │
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
| 6 | Create mobile kit compose files | `docker/mobile/` | High |
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

## Service Inventory (24 Services)

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
| Domain (cronova.dev) | Already owned |
| Domain (verava.ai) | ~$5.00 |
| **Total** | **~$11/mo** |

### Annual

| Item | Cost |
|------|------|
| VPS | $72.00 |
| cronova.dev | Already owned |
| verava.ai | ~$60.00 |
| **Total** | **~$132/yr** |

---

## Critical Success Factors

These MUST work for the architecture to function:

| Factor | Dependency | Backup Plan |
|--------|------------|-------------|
| Headscale DB | Entire mesh | Hourly backups to NAS + VPS |
| Unbound on OPNsense | Privacy DNS | Fallback to public DNS |
| Restic encryption keys | All backups | Store in Vaultwarden + paper |
| Tailscale connectivity | Inter-device comms | DERP relay on VPS |
| OPNsense WAN bridged (vmbr0) | Network isolation | Bridged approach, no passthrough needed |

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-14 | cronova.dev for homelab | Already owned, established brand, $0 additional cost |
| 2026-01-14 | verava.ai for business | AI-first positioning, modern TLD |
| 2026-01-14 | Both domains via Cloudflare | At-cost pricing, DNS + CDN included |
| 2026-01-14 | Public: vault, status, notify | Need access from anywhere |
| 2026-01-14 | Private: media, home, bitcoin | Personal/sensitive data |

---

## Next Actions

| Priority | Action | Blocks |
|----------|--------|--------|
| 1 | Purchase verava.ai | Nothing |
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
