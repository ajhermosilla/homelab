# Homelab Improvement Plan - 2026-02-04

Code review findings from deep analysis of docker/, ansible/, and docs/ directories.

## Critical Issues (Deploy-Blocking)

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 1 | VPS Restic IP mismatch (100.64.0.20 vs 100.64.0.100) | `docker/vps/backup/README.md` | 21, 40, 46 | **Fixed** |
| 2 | Mobile Pi-hole IP mismatch (.5 vs .10) | `docker/mobile/rpi5/.env.example` | 14, 18 | **Fixed** |
| 3 | Missing `mosquitto.conf` file | `docker/fixed/docker-vm/automation/` | - | N/A (exists) |
| 4 | Missing/incomplete `frigate.yml` config | `docker/fixed/docker-vm/security/` | - | N/A (exists) |
| 5 | HOMELAB_ROOT not documented in .env files | multiple .env.example files | - | **Fixed** |

## High Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 6 | Stack dependency not documented (automation → security) | `docker/fixed/docker-vm/security/docker-compose.yml` | 193 | N/A (exists) |
| 7 | NFS mount IP hardcoded in playbook warning | `ansible/playbooks/docker-compose-deploy.yml` | 144-145 | **Fixed** |
| 8 | Camera RTSP credentials in plaintext | `docker/fixed/docker-vm/security/frigate.yml` | 101-104 | **Fixed** |
| 9 | Restic password var inconsistency (PASSWORD vs PASSWORD_FILE) | multiple docker-compose files | - | **Fixed** |
| 10 | NAS download path symlink not in nfs-server playbook | `ansible/playbooks/nfs-server.yml` | 39 | **Fixed** |

## Medium Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 11 | Proxmox vs OPNsense IP ambiguity (.10 vs .14) | `docker/vps/monitoring/monitors.md` | 31 | **Fixed** |
| 12 | Missing certificate renewal cron example | `docker/fixed/docker-vm/networking/caddy/Caddyfile` | 110 | **Fixed** |
| 13 | Docker image version not pinned (watchtower:latest) | `docker/fixed/docker-vm/maintenance/docker-compose.yml` | 11 | **Fixed** |
| 14 | Caddy loose version (2.8 vs specific) | multiple Caddyfiles | - | **Fixed** |
| 15 | Vaultwarden signups default could be clearer | `docker/fixed/docker-vm/security/docker-compose.yml` | 61 | **Fixed** |
| 16 | NFS media export missing no_root_squash | `ansible/playbooks/nfs-server.yml` | 33 | **Fixed** |
| 17 | Samba credentials visible in docker inspect | `docker/fixed/nas/storage/docker-compose.yml` | 42 | **Fixed** |
| 18 | OpenClaw VM local IP comment missing | `ansible/inventory.yml` | 50 | N/A (exists) |

## Low Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 19 | Mobile Pi-hole uses port 8080 vs 8053 (inconsistent) | `docker/mobile/rpi5/networking/pihole/docker-compose.yml` | 32 | **Fixed** |
| 20 | Backup volume path naming (BACKUP_DATA vs BACKUP_PATH) | multiple | - | **Fixed** |
| 21 | Jellyfin cache not on tmpfs (slow transcoding) | `docker/fixed/docker-vm/media/docker-compose.yml` | 37 | **Fixed** |
| 22 | Network topology doc incomplete | `docs/network-topology.md` | 82+ | N/A (complete) |

---

## Fixes Applied

### Critical

1. **VPS Restic IP**: Changed all references from 100.64.0.x to actual IP 100.77.172.46
2. **Mobile Pi-hole IP**: Changed HOST_IP from 192.168.8.10 to 192.168.8.5, updated Tailscale IP references
3. **mosquitto.conf**: Already exists with complete configuration (false positive)
4. **frigate.yml**: Already exists with complete configuration (false positive)
5. **HOMELAB_ROOT**: Added to security and automation .env.example files

### High Priority

1. **Stack dependency**: Documentation already exists at lines 195-203 (false positive)
2. **NFS IP configurable**: Added `nas_ip` variable to docker-compose-deploy.yml playbook
3. **Camera credentials**: Changed from placeholder syntax to proper env vars (FRIGATE_REOLINK_*, FRIGATE_TAPO_*)
4. **Restic password**: Documented consistency requirement - both stacks must use same password
5. **NFS symlinks**: Added symlink creation tasks to nfs-server.yml (media, downloads, backup, frigate)

### Medium Priority

1. **OPNsense IP**: Fixed monitors.md from 100.64.0.14 to 100.79.230.235 (actual Tailscale IP)
2. **Certificate renewal**: Updated Caddyfile to note Headscale limitation
3. **Version pinning**: Pinned watchtower:1.7.1, alpine:3.19 for backup sidecars, documented changedetection:latest rationale
4. **Caddy version**: Pinned to 2.8.4 (fixed) and 2.8.4-alpine (VPS)
5. **Vaultwarden signups**: Added security comment explaining default=false
6. **NFS no_root_squash**: Added comment explaining why media export doesn't need it (read-only)
7. **Samba credentials**: Enhanced warning with mitigations and alternative image suggestion
8. **OpenClaw local IP**: Already had comment (false positive)

### Low Priority

1. **Mobile Pi-hole port**: Added comment explaining 8080 vs 8053 difference (intentional)
2. **Backup naming convention**: Documented BACKUP_PATH (source) vs BACKUP_DATA (destination) in restic-backup.sh
3. **Jellyfin cache**: Added commented tmpfs option for faster transcoding
4. **Network topology**: Already complete (487 lines, all sections present)

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
