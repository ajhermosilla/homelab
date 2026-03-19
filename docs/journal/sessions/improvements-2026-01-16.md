# Improvement Plan - 2026-01-16

Comprehensive codebase review findings and action plan.

## Summary

| Priority | Count | Status |
|----------|-------|--------|
| Critical | 7 | **Complete** |
| High | 5 | **Complete** |
| Medium | 12 | **Complete** |
| **Total**|**24**|**24 done** |

---

## Critical Priority (Blocks Deployment)

Must be fixed before any deployment attempt.

| # | Issue | Location | Status |
|---|-------|----------|--------|
| 1 | Missing `frigate.yml` config | `docker/fixed/docker-vm/security/` | [x] |
| 2 | Missing `mosquitto.conf` | `docker/fixed/docker-vm/automation/` | [x] |
| 3 | Missing Caddyfile (fixed homelab) | `docker/fixed/docker-vm/networking/caddy/` | [x] |
| 4 | Missing `htpasswd` for Restic REST (NAS) | `docker/fixed/nas/backup/` | [x] |
| 5 | Missing `htpasswd` for Restic REST (VPS) | `docker/vps/backup/` | [x] |
| 6 | Mobile Headscale deprecated | `docker/mobile/rpi5/networking/headscale/` | [x] |
| 7 | Port 80 conflict: Pi-hole → 8053 | `docker/fixed/docker-vm/networking/` | [x] |

---

## High Priority (Incomplete Setup)

Complete before testing services.

| # | Issue | Location | Status |
|---|-------|----------|--------|
| 8 | Missing `.env.example` files | All docker directories | [x] |
| 9 | Docker network isolation undefined | `docker/README.md` | [x] |
| 10 | Headscale `config/config.yaml` template | `docker/vps/networking/headscale/config/` | [x] |
| 11 | NFS mount procedure not documented | `docs/nfs-setup.md` | [x] |
| 12 | OPNsense setup guide missing | `docs/opnsense-setup.md` | [x] |

---

## Medium Priority (Documentation Gaps)

Complete before production use.

| # | Issue | Location | Status |
|---|-------|----------|--------|
| 13 | qBittorrent port conflict (8080 vs 6881) | `docs/services.md` | [x] |
| 14 | NAS symlink creation not documented | `docs/fixed-homelab.md` | [x] |
| 15 | Uptime Kuma monitors not seeded | `docker/vps/monitoring/monitors.md` | [x] |
| 16 | Backup verification script not deployed | `scripts/backup-verify.sh` | [x] |
| 17 | Service matrix (what runs where) missing | `docs/services.md` | [x] |
| 18 | Setup runbook for fresh deployment | `docs/setup-runbook.md` | [x] |
| 19 | Proxmox setup guide missing | `docs/proxmox-setup.md` | [x] |
| 20 | TLS/SSL strategy in compose vs docs | `Caddyfile` updated | [x] |
| 21 | Tailscale IP allocation policy | `docs/hardware.md` | [x] |
| 22 | Ansible playbooks referenced but empty | `ansible/` | [x] |
| 23 | Top-level README needs navigation | `README.md` | [x] |
| 24 | Docker directory README missing | `docker/README.md` | [x] |

---

## Action Plan

### Phase 1: Critical Config Files (Complete)

1. ~~Create `frigate.yml` - camera configuration template~~
2. ~~Create `mosquitto.conf` - MQTT broker config~~
3. ~~Create Caddyfile for fixed homelab~~
4. ~~Document htpasswd creation for Restic REST~~
5. ~~Deprecate mobile Headscale (moved to VPS)~~
6. ~~Resolve port 80 conflict (Pi-hole → 8053)~~

### Phase 2: Environment Templates (Complete)

1. ~~Create `.env.example` for all docker directories~~ (14 files)
2. ~~Document Docker network strategy~~ (`docker/README.md`)
3. ~~Create Headscale config.yaml template~~ (`config/config.yaml.example`)
4. ~~Create NFS setup guide~~ (`docs/nfs-setup.md`)
5. ~~Create OPNsense setup guide~~ (`docs/opnsense-setup.md`)

### Phase 3: Remaining Medium Priority (Future)

1. Proxmox setup guide
2. Setup runbook (full deployment)
3. qBittorrent port conflict resolution
4. Service matrix documentation
5. Uptime Kuma monitor seeding
6. Backup verification scripts

### Phase 4: Polish (Future)

1. Tailscale IP allocation policy
2. Ansible playbooks
3. Top-level README improvements
4. Docker directory README

---

## Notes

- VPS Headscale docker-compose and backup.sh already created (2026-01-16)
- Network diagram with both switches completed (2026-01-16)
- VLAN design documented with port assignments
- Mobile kit now on-demand operation (Headscale moved to VPS)

---

## Related Documents

- `docs/sessions/2026-01-16.md` - Session summary
- `docs/sessions/improvements-2026-01-15.md` - Previous improvements (all complete)
