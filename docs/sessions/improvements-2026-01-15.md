# Improvements Identified - 2026-01-15

Comprehensive codebase review after completing hardware documentation.

## Critical (Fix Now)

- [ ] **1. Update architecture-review.md domains**
  - File: `docs/architecture-review.md`
  - Issue: References old domains (nanduti.io, verava.net)
  - Action: Update to cronova.dev + verava.ai
  - Lines: 130-484 (Domain Coexistence Strategy, Caddyfile examples, costs)

- [ ] **2. Fix Frigate location in services.md**
  - File: `docs/services.md:77`
  - Issue: Lists Frigate under NAS services
  - Action: Move to Docker VM, NAS only exports NFS

## High Priority

- [ ] **3. Create fixed homelab docker-compose files (Docker VM)**
  - Missing: `docker/fixed/docker-vm/`
  - Services needed:
    - networking/pihole/docker-compose.yml
    - networking/caddy/docker-compose.yml
    - media/docker-compose.yml (Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent)
    - automation/docker-compose.yml (Home Assistant, Mosquitto)
    - security/docker-compose.yml (Vaultwarden, Frigate)

- [ ] **4. Create fixed homelab docker-compose files (NAS)**
  - Missing: `docker/fixed/nas/`
  - Services needed:
    - storage/docker-compose.yml (Samba, Syncthing)
    - backup/docker-compose.yml (Restic REST)
    - NFS export configuration

## Medium Priority

- [ ] **5. Resolve port 8080 conflict**
  - File: `docs/services.md:121`
  - Issue: qBittorrent and Pi-hole alt both use 8080
  - Decision needed: qBittorrent→6881 or Pi-hole alt→8053
  - Note: VPS already uses 8053 for Pi-hole

- [ ] **6. Document NUT (UPS graceful shutdown)**
  - Files: `hardware.md:292`, `fixed-homelab.md:474`
  - Issue: Marked TODO, not implemented
  - Action: Add NUT configuration to NAS docker-compose or system config

- [ ] **7. Create monitoring strategy document**
  - Missing: Uptime Kuma checks + ntfy notifications
  - Content needed:
    - Service monitor list
    - ntfy topic configuration
    - Alert thresholds

- [ ] **8. Create VLAN documentation**
  - Missing: OPNsense IoT isolation strategy
  - Content needed:
    - VLAN design (IoT, Guest, Management)
    - Firewall rules between VLANs
    - Camera isolation

- [ ] **9. Create backup test procedure**
  - Missing: Validation that DR runbook works
  - Content needed:
    - Monthly restore test checklist
    - Backup verification steps
    - Test result documentation

- [ ] **10. Document certificate strategy**
  - File: `docs/caddy-config.md:402-421`
  - Issue: Two options listed, no decision made
  - Decision needed: Tailscale HTTPS vs Internal CA

## Low Priority

- [ ] **11. Archive or update domain-research.md**
  - File: `docs/domain-research.md`
  - Issue: References superseded domains (nanduti.io, verava.net)
  - Action: Add notice that it's superseded by domain-strategy.md

- [ ] **12. Document NAS PSU model**
  - File: `docs/hardware.md:145`
  - Issue: Still TBD
  - Action: Verify and document actual PSU model

## Progress Tracking

| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | Update architecture-review.md domains | Pending | |
| 2 | Fix Frigate location in services.md | Pending | |
| 3 | Docker VM docker-compose files | Pending | |
| 4 | NAS docker-compose files | Pending | |
| 5 | Port 8080 conflict | Pending | |
| 6 | NUT configuration | Pending | |
| 7 | Monitoring strategy | Pending | |
| 8 | VLAN documentation | Pending | |
| 9 | Backup test procedure | Pending | |
| 10 | Certificate strategy | Pending | |
| 11 | Archive domain-research.md | Pending | |
| 12 | NAS PSU model | Pending | |

## Session Notes

Started: 2026-01-15
Focus: Fix critical/high items first, then medium priority
