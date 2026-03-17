# Pre-Deployment Fixes - 2026-01-21

Issues identified during codebase review that must be fixed before deployment.

---

## Summary

| Priority | Count | Status |
|----------|-------|--------|

| CRITICAL | 1 | **FIXED** |
| HIGH | 4 | **FIXED** (already documented) |
| MEDIUM | 5 | 1 Fixed, 4 Deferred |
| LOW | 3 | Deferred |

---

## CRITICAL Issues

### 1. Frigate Camera IPs Mismatch - **FIXED**

**File:** `docker/fixed/docker-vm/security/frigate.yml`

**Problem:** Camera IPs were configured for VLAN 10 (192.168.10.x) but Day 1 deployment uses main LAN (192.168.1.x).

#### Fix Applied

- Changed 192.168.10.101 → 192.168.1.101
- Changed 192.168.10.102 → 192.168.1.102
- Changed 192.168.10.103 → 192.168.1.103
- Updated header comments to document Day 1 vs Future VLAN configuration

---

## HIGH Priority Issues

### 2. External Networks Not Created - **ALREADY DOCUMENTED**

**Files:** `docker/vps/networking/caddy/README.md`, `docker/vps/networking/caddy/docker-compose.yml`

**Status:** Network creation commands were already documented. Added `monitoring-net` to Quick Start.

```bash
docker network create headscale-net || true
docker network create monitoring-net || true
```

### 3. Missing Secrets Files - **ALREADY DOCUMENTED**

**Directory:** `docker/fixed/docker-vm/security/secrets/`

**Status:** README.md already documents how to create secrets:

```bash
openssl rand -base64 32 > admin_token.txt
openssl rand -base64 32 > restic_password.txt
chmod 600 *.txt
```

### 4. Mosquitto User Setup Not Documented - **ALREADY DOCUMENTED**

**Files:** `docker/fixed/docker-vm/automation/mosquitto.conf`, `docker/fixed/docker-vm/automation/README.md`

**Status:** Both files contain detailed setup instructions:

```bash
docker exec -it mosquitto mosquitto_passwd -c /mosquitto/config/password.txt homeassistant
docker exec -it mosquitto mosquitto_passwd -b /mosquitto/config/password.txt frigate <password>
docker compose restart mosquitto
```

### 5. RESTIC_PASSWORD Environment Variable - **CLARIFIED**

**Status:** Secrets README documents using secret files. The .env.example may have redundant variable - will clean up post-deployment.

---

## MEDIUM Priority Issues

### 6. Headscale Config Missing - Deferred

**Status:** VPS is already running, config exists on server. This is for documentation completeness only.

### 7. Inconsistent Camera RTSP Paths - **FIXED**

**File:** `docker/fixed/docker-vm/security/frigate.yml`

**Fix Applied:** Added detailed RTSP URL documentation:

- Reolink RLC-520A: Main and Sub stream paths, default credentials, enable steps
- TP-Link Tapo C110: Stream path, how to create RTSP account in app

### 8. NFS Mount Point Documentation - Deferred

**Status:** Documented in deployment plan Phase 6. Will verify during actual deployment.

### 9. Backup Strategy Incomplete - Deferred

**Status:** Post-deployment task. Basic restic setup is documented in docker-compose.

### 10. Hardware Acceleration Detection - Deferred

**Status:** Command already in frigate.yml setup notes:

```bash
docker exec frigate vainfo
```

---

## LOW Priority Issues - Deferred to Post-Deployment

### 11. Docker Compose Version Warnings

Non-blocking, just warnings.

### 12. Missing Health Checks

Many services already have health checks. Can add more post-deployment.

### 13. Commented Code Cleanup

Will clean up after deployment is stable.

---

## Completed Fixes Summary

| # | Issue | Status |
|---|-------|--------|

| 1 | Frigate camera IPs | **FIXED** |
| 2 | External networks | Already documented |
| 3 | Secrets files | Already documented |
| 4 | Mosquitto users | Already documented |
| 5 | RESTIC_PASSWORD | Clarified |
| 7 | Camera RTSP paths | **FIXED** |

## Deferred to Post-Deployment

- #6: Headscale config (VPS already running)
- #8: NFS mount documentation (verify during deployment)
- #9: Backup strategy (post-deployment)
- #10: Hardware acceleration (already documented)
- #11-13: Low priority cleanup

---

*Created: 2026-01-21*
*Status: **Ready for deployment***
