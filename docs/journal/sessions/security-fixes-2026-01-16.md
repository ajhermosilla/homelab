# Security Fix Plan - 2026-01-16

Security audit findings and remediation plan.

## Summary

| Severity | Count | Status |
|----------|-------|--------|

| Critical | 2 | **2 Done** |
| High | 8 | **8 Done** |
| Medium | 12 | **11 Done** |
| **Total**|**22**|**21 done** |

---

## Critical (Blocks Deployment)

| # | Issue | Location | Status |
|---|-------|----------|--------|

| 1 | Default password `changeme` fallback | `docker/mobile/rpi5/networking/pihole/docker-compose.yml` | [x] |
| 2 | Placeholder creds `USER:PASS` in frigate config | `docker/fixed/docker-vm/security/frigate.yml` | [x] |

---

## High Priority

| # | Issue | Location | Status |
|---|-------|----------|--------|

| 3 | `privileged: true` on Home Assistant | `docker/fixed/docker-vm/automation/docker-compose.yml` | [x] |
| 4 | `privileged: true` on Frigate | `docker/fixed/docker-vm/security/docker-compose.yml` | [x] |
| 5 | No `security_opt: no-new-privileges` | All docker-compose files (14 files) | [x] |
| 6 | No resource limits on media stack | `docker/fixed/docker-vm/media/docker-compose.yml` | [x] |
| 7 | No resource limits on changedetection | `docker/vps/scraping/docker-compose.yml` | [x] |
| 8 | Using `:latest` image tags | Multiple docker-compose files | [x] |
| 9 | qBittorrent default creds in comments | `docker/fixed/docker-vm/media/docker-compose.yml` | [x] |
| 10 | changedetection no auth enforcement | `docker/vps/scraping/docker-compose.yml` | [x] |

---

## Medium Priority

| # | Issue | Location | Status |
|---|-------|----------|--------|

| 11 | CORS wildcard `*` | `docker/vps/networking/caddy/Caddyfile` | [x] |
| 12 | Samba credentials in command | `docker/fixed/nas/storage/docker-compose.yml` | [x] |
| 13 | Pi-hole default password (fixed) | `docker/fixed/docker-vm/networking/pihole/docker-compose.yml` | [x] |
| 14 | Pi-hole default password (VPS) | `docker/vps/networking/pihole/docker-compose.yml` | [x] |
| 15 | Restic REST example with plaintext creds | `docker/vps/backup/docker-compose.yml` | [x] |
| 16 | No health checks on services | Multiple docker-compose files | [x] |
| 17 | SOPS age key placeholder | `.sops.yaml` | [x] |
| 18 | NFS security options not documented | `docs/nfs-setup.md` | [x] |
| 19 | Credential examples in comments | Multiple files | [x] |
| 20 | Containers running as root | Multiple services | [ ] |
| 21 | Missing cap_drop on containers | All docker-compose files | [x] |
| 22 | Network topology in public docs | `docs/fixed-homelab.md`, `docs/hardware.md` | [x] |

---

## Fix Details

### Critical #1: Pi-hole Default Password (Mobile)

**File:** `docker/mobile/rpi5/networking/pihole/docker-compose.yml`

#### Current

```yaml
WEBPASSWORD: ${PIHOLE_PASSWORD:-changeme}
```

**Fix:** Remove default, require env var

```yaml
WEBPASSWORD: ${PIHOLE_PASSWORD:?PIHOLE_PASSWORD required}
```

---

### Critical #2: Frigate Placeholder Credentials

**File:** `docker/fixed/docker-vm/security/frigate.yml`

#### Current

```yaml
- path: rtsp://USER:PASS@192.168.10.101:554/...
```

**Fix:** Use environment variable substitution or clear placeholder

```yaml
- path: rtsp://${CAM_USER}:${CAM_PASS}@192.168.10.101:554/...
```

---

### High #3-4: Remove Privileged Mode

#### Files

- `docker/fixed/docker-vm/automation/docker-compose.yml`
- `docker/fixed/docker-vm/security/docker-compose.yml`

**Fix:** Replace `privileged: true` with specific device access

```yaml
# Instead of privileged: true
devices:
  - /dev/dri:/dev/dri  # For hardware acceleration
```

---

### High #5: Add security_opt to All Services

**Fix:** Add to every service in all docker-compose files:

```yaml
security_opt:
  - no-new-privileges:true
```

---

### High #6-7: Add Resource Limits

**Fix:** Add to media stack and changedetection:

```yaml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '2'
```

---

### High #8: Pin Image Versions

#### Current → Fixed

| Service | Current | Fixed |
|---------|---------|-------|

| pihole | `pihole/pihole:latest` | `pihole/pihole:2024.07.0` |
| headscale | `headscale/headscale:latest` | `headscale/headscale:0.23.0` |
| vaultwarden | `vaultwarden/server:latest` | `vaultwarden/server:1.32.0` |
| jellyfin | `jellyfin/jellyfin:latest` | `jellyfin/jellyfin:10.9.11` |
| homeassistant | `homeassistant/home-assistant:latest` | `homeassistant/home-assistant:2024.12` |
| caddy | `caddy:latest` | `caddy:2.8` |
| soft-serve | `charmcli/soft-serve:latest` | `charmcli/soft-serve:0.8` |

---

### High #9: Remove Default Credentials from Comments

**File:** `docker/fixed/docker-vm/media/docker-compose.yml`

**Fix:** Remove `admin/adminadmin` reference, add secure setup note

---

### High #10: Enforce changedetection Auth

**File:** `docker/vps/scraping/docker-compose.yml`

**Fix:** Add auth enforcement note and password requirement

---

### Medium #11: Fix CORS Wildcard

**File:** `docker/vps/networking/caddy/Caddyfile`

#### Current

```text
Access-Control-Allow-Origin "*"
```

**Fix:**

```text
Access-Control-Allow-Origin "https://cronova.dev"
```

---

## Action Plan

### Phase 1: Critical (Do First)

1. Fix Pi-hole default password
2. Fix Frigate placeholder credentials

### Phase 2: High Priority

1. Remove privileged mode from HA and Frigate
2. Add security_opt to all services
3. Add resource limits
4. Pin image versions
5. Remove credential comments
6. Enforce changedetection auth

### Phase 3: Medium Priority

1. Fix CORS
2. Fix Samba credentials
3. Add health checks
4. Document remaining items

---

## Notes

- Some items require looking up current stable versions
- `privileged: true` removal needs testing to ensure HA/Frigate still work
- Network topology exposure is acceptable for personal public repo (low risk)
- SOPS placeholder is expected until secrets are actually encrypted

---

## Related Documents

- `docs/security-hardening.md` - Security best practices
- `docs/sessions/improvements-2026-01-16.md` - Previous improvements
