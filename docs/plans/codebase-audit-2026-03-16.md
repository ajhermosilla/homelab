# Codebase Audit — Round 2 (2026-03-16)

**Status**: Active — second pass after fixing 10/18 items from first audit
**Scope**: Docker Compose (all hosts), scripts, Ansible, shared backup scripts

---

## High Priority

### ~~1. Immich images use `release` tag — unversioned~~ (FIXED 2026-03-16)

- **File**: `docker/fixed/docker-vm/photos/docker-compose.yml`
- **Lines**: 11, 68
- **Issue**: `ghcr.io/immich-app/immich-server:release` and `immich-machine-learning:release` — not pinned
- **Risk**: Watchtower could pull a breaking update (Immich has had breaking migrations)
- **Fix**: Pin to current version (check `docker inspect` for running version)

### ~~2. DERP missing NET_BIND_SERVICE cap~~ (FIXED 2026-03-16)

- **File**: `docker/vps/networking/derp/docker-compose.yml`
- **Lines**: 12-13
- **Issue**: `cap_drop: [ALL]` with no `cap_add`, but binds to ports 3478/udp and 8443
- **Risk**: May fail on container restart if Docker re-evaluates caps
- **Fix**: Add `cap_add: [NET_BIND_SERVICE]`

### ~~3. DERP env var mismatch~~ (FIXED 2026-03-16)

- **File**: `docker/vps/networking/derp/docker-compose.yml` line 37 vs `.env.example` line 8
- **Issue**: Compose uses `DERP_DOMAIN`, .env.example defines `DERP_HOSTNAME`
- **Fix**: Align naming in both files

### ~~4. Glances missing resource limits~~ (VERIFIED 2026-03-16 — already has 256M/0.5 CPU)

- **File**: `docker/fixed/nas/monitoring/docker-compose.yml`
- **Issue**: Only NAS service without `deploy.resources.limits`
- **Fix**: Add `memory: 256M`, `cpus: '0.5'`

### ~~5. backup-verify.sh missing new sidecars~~ (FIXED 2026-03-16)

- **File**: `scripts/backup-verify.sh`
- **Issue**: Tests 5 services but now 7 exist (missing caddy-backup, pihole-backup)
- **Fix**: Add test cases for caddy and pihole repos

### 6. Ansible docker.yml missing NAS data-root

- **File**: `ansible/playbooks/docker.yml` line 90
- **Issue**: Sets `storage-driver: overlay2` globally but NAS needs `data-root: /data/docker`
- **Risk**: On NAS rebuild, Docker defaults to `/var/lib/docker` which only has 6GB
- **Fix**: Add NAS-specific daemon.json with `data-root`

### 7. Ansible backup.yml hardcodes x86_64

- **File**: `ansible/playbooks/backup.yml` line 46
- **Issue**: Downloads `restic_0.16.4_linux_amd64.bz2` — breaks on ARM64 (RPi 5)
- **Fix**: Use `{{ ansible_architecture }}` mapping (amd64/arm64)

---

## Medium Priority

### 8. Prometheus HA token placeholder — needs user action

- **File**: `docker/fixed/docker-vm/monitoring/prometheus.yml`
- **Issue**: `<HA_LONG_LIVED_TOKEN>` placeholder not replaced — HA metrics not scraped
- **Fix**: Generate HA long-lived token, add to .env, reference in prometheus.yml

### ~~9. Sonarr/Radarr/Prowlarr backup label misleading~~ (FIXED 2026-03-16)

- **File**: `docker/fixed/docker-vm/media/docker-compose.yml`
- **Issue**: `com.cronova.backup=true` label but no backup sidecars
- **Fix**: Either remove labels or add backup sidecars (configs are re-downloadable, low priority)

### ~~10. ntfy uses `v2` tag — major only~~ (FIXED 2026-03-16 → v2.19.1)

- **File**: `docker/vps/monitoring/docker-compose.yml` line 55
- **Fix**: Pin to specific minor version

### ~~11. Forgejo uses `11` tag — major only~~ (FIXED 2026-03-16 → 11.0)

- **File**: `docker/fixed/nas/git/docker-compose.yml` line 11
- **Fix**: Pin to specific minor version (e.g., `11.0`)

### ~~12. HOMELAB_ROOT missing from .env.example~~ (FIXED 2026-03-16)

- **Files**: `docker/fixed/nas/backup/.env.example`, `docker/fixed/nas/paas/.env.example`
- **Fix**: Add `HOMELAB_ROOT=/opt/homelab/repo` to both

### ~~13. restic-backup.sh uses grep for JSON parsing~~ (FIXED 2026-03-16 → jq)

- **File**: `docker/shared/backup/restic-backup.sh` line 69
- **Issue**: `grep -o '"short_id":"[^"]*"'` — fragile if restic output format changes
- **Fix**: Use `jq` if available, or document the dependency

---

## Low Priority

### 14. TZ env format inconsistency

- **Files**: Multiple NAS compose files
- **Issue**: Mix of list (`- TZ=`) and map (`TZ:`) YAML notation
- **Fix**: Standardize to list format

### 15. Boot orchestrator doesn't verify critical services healthy

- **File**: `scripts/docker-boot-orchestrator.sh` line 227
- **Issue**: Only counts running containers, doesn't verify Caddy/Pi-hole are healthy
- **Fix**: Add `wait_for_healthy` calls for caddy and pihole after phase 4

### 16. pihole.yml resolv.conf not persistent

- **File**: `ansible/playbooks/pihole.yml` line 71
- **Issue**: Direct `/etc/resolv.conf` modification can be overwritten by DHCP renewal
- **Fix**: Use `resolvectl` or persist in DHCP client config

---

## Previously Fixed (Round 1 — 2026-03-15)

Items 1-9 from `codebase-audit-2026-03-15.md`: image pinning, services.md, dns-architecture,
deployment-order, completed plans, boot orchestrator paths verified, Ansible NAS stacks documented,
Watchtower labels, Pi-hole + Caddy backup sidecars.
