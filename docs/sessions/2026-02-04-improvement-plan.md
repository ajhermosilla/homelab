# Homelab Improvement Plan - 2026-02-04

Code review findings from deep analysis of docker/, ansible/, and docs/ directories.

## Critical Issues (Deploy-Blocking)

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 1 | VPS Restic IP mismatch (100.64.0.20 vs 100.64.0.100) | `docker/vps/backup/README.md` | 21, 40, 46 | Pending |
| 2 | Mobile Pi-hole IP mismatch (.5 vs .10) | `docker/mobile/rpi5/.env.example` | 14, 18 | Pending |
| 3 | Missing `mosquitto.conf` file | `docker/fixed/docker-vm/automation/` | - | Pending |
| 4 | Missing/incomplete `frigate.yml` config | `docker/fixed/docker-vm/security/` | - | Pending |
| 5 | HOMELAB_ROOT not documented in .env files | multiple .env.example files | - | Pending |

## High Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 6 | Stack dependency not documented (automation → security) | `docker/fixed/docker-vm/security/docker-compose.yml` | 193 | Pending |
| 7 | NFS mount IP hardcoded in playbook warning | `ansible/playbooks/docker-compose-deploy.yml` | 144-145 | Pending |
| 8 | Camera RTSP credentials in plaintext | `docker/fixed/docker-vm/security/frigate.yml` | 101-104 | Pending |
| 9 | Restic password var inconsistency (PASSWORD vs PASSWORD_FILE) | multiple docker-compose files | - | Pending |
| 10 | NAS download path symlink not in nfs-server playbook | `ansible/playbooks/nfs-server.yml` | 39 | Pending |

## Medium Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 11 | Proxmox vs OPNsense IP ambiguity (.10 vs .14) | `docker/vps/monitoring/monitors.md` | 31 | Pending |
| 12 | Missing certificate renewal cron example | `docker/fixed/docker-vm/networking/caddy/Caddyfile` | 110 | Pending |
| 13 | Docker image version not pinned (watchtower:latest) | `docker/vps/maintenance/docker-compose.yml` | 11 | Pending |
| 14 | Caddy loose version (2.8 vs specific) | multiple Caddyfiles | - | Pending |
| 15 | Vaultwarden signups default could be clearer | `docker/fixed/docker-vm/security/docker-compose.yml` | 61 | Pending |
| 16 | NFS media export missing no_root_squash | `ansible/playbooks/nfs-server.yml` | 33 | Pending |
| 17 | Samba credentials visible in docker inspect | `docker/fixed/nas/storage/docker-compose.yml` | 42 | Pending |
| 18 | OpenClaw VM local IP comment missing | `ansible/inventory.yml` | 50 | Pending |

## Low Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 19 | Mobile Pi-hole uses port 8080 vs 8053 (inconsistent) | `docker/mobile/rpi5/networking/pihole/docker-compose.yml` | 32 | Pending |
| 20 | Backup volume path naming (BACKUP_DATA vs BACKUP_PATH) | multiple | - | Pending |
| 21 | Jellyfin cache not on tmpfs (slow transcoding) | `docker/fixed/docker-vm/media/docker-compose.yml` | 37 | Pending |
| 22 | Network topology doc incomplete | `docs/network-topology.md` | 82+ | Pending |

---

## Fixes Applied

### Critical

*(To be filled as issues are resolved)*

### High Priority

*(To be filled as issues are resolved)*

### Medium Priority

*(To be filled as issues are resolved)*

---

## Action Plan

### Phase 1: Critical Fixes (Today)
1. Fix VPS Restic IP references
2. Fix Mobile Pi-hole IP references
3. Create mosquitto.conf from template
4. Create/complete frigate.yml base config
5. Document HOMELAB_ROOT in all .env.example files

### Phase 2: High Priority (Today if time permits)
1. Add stack dependency documentation
2. Make NFS IP configurable in playbook
3. Move camera credentials to environment variables
4. Standardize Restic password variable naming
5. Add downloads symlink to nfs-server playbook

### Phase 3: Medium Priority (Later)
1. Pin all Docker image versions
2. Add certificate renewal documentation
3. Improve Vaultwarden defaults
4. Fix NFS export options consistency

### Phase 4: Low Priority (Backlog)
1. Documentation cleanup
2. Performance optimizations
3. Naming consistency

---

*Created: 2026-02-04*
*Last updated: 2026-02-04*
