# Improvement Opportunities - 2026-01-16

Post-security audit improvement opportunities identified after completing 24/24 documentation items and 21/22 security fixes.

## Summary

| Priority | Count | Effort |
|----------|-------|--------|
| Quick Wins | 6 | < 1 hour each |
| Medium | 8 | 1-2 hours each |
| Lower | 5 | 2+ hours each |

---

## Quick Wins (High Impact, Low Effort)

### 1. Add Health Checks to Missing Services

**Effort:** 30 min | **Impact:** High

9 compose files lack healthchecks for automatic restart on silent failures.

| File | Services |
|------|----------|
| `docker/fixed/nas/storage/docker-compose.yml` | Samba, Syncthing |
| `docker/fixed/nas/backup/docker-compose.yml` | Restic REST |
| `docker/vps/backup/docker-compose.yml` | Restic REST |
| `docker/vps/scraping/docker-compose.yml` | changedetection |
| `docker/vps/networking/pihole/docker-compose.yml` | Pi-hole |
| `docker/fixed/docker-vm/networking/pihole/docker-compose.yml` | Pi-hole |
| `docker/mobile/rpi5/networking/pihole/docker-compose.yml` | Pi-hole |
| `docker/vps/networking/derp/docker-compose.yml` | DERP relay |
| `docker/fixed/docker-vm/networking/caddy/docker-compose.yml` | Caddy |
| `docker/vps/networking/caddy/docker-compose.yml` | Caddy |

**Template:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:PORT/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

---

### 2. Add Service Dependencies (`depends_on`)

**Effort:** 20 min | **Impact:** High

Services may start out-of-order, causing initialization failures.

| Service | Depends On |
|---------|------------|
| Frigate | Mosquitto |
| Home Assistant | Mosquitto |
| Jellyfin | NFS mount |
| Sonarr | Prowlarr |
| Radarr | Prowlarr |

**Template:**
```yaml
depends_on:
  mosquitto:
    condition: service_healthy
```

---

### 3. Add Logging Limits

**Effort:** 15 min | **Impact:** High

Unbounded container log growth will fill disk. No compose files have logging configuration.

**Template (add to all services):**
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

---

### 4. Add Container Labels

**Effort:** 30 min | **Impact:** Medium

No labels in any compose file. Labels enable filtering, organization, and automation.

**Template:**
```yaml
labels:
  - "com.cronova.environment=vps"      # vps|fixed|mobile
  - "com.cronova.category=networking"  # networking|media|security|automation|backup
  - "com.cronova.critical=true"        # for critical services
  - "com.cronova.backup=true"          # services to backup
```

---

### 5. Create Per-Service READMEs

**Effort:** 45 min | **Impact:** Medium

8 docker directories lack setup documentation.

| Directory | Missing README |
|-----------|---------------|
| `docker/fixed/docker-vm/media/` | *arr stack integration, setup |
| `docker/fixed/docker-vm/automation/` | MQTT setup, HA config |
| `docker/fixed/docker-vm/security/` | Frigate setup, camera config |
| `docker/fixed/nas/storage/` | Samba/Syncthing setup |
| `docker/fixed/nas/backup/` | Restic REST setup |
| `docker/vps/scraping/` | changedetection setup |
| `docker/vps/backup/` | Restic REST setup |
| `docker/vps/networking/` | Headscale/DERP/Caddy setup |

---

### 6. Document Network Topology

**Effort:** 45 min | **Impact:** Medium

`docker/README.md` discusses network strategy but lacks:
- Visualization of how networks connect between compose files
- Explicit list of which services talk to which networks
- Documented ports/interfaces for inter-service communication

**Create:** `docs/network-topology.md` with diagram

---

## Medium Priority

### 7. Missing Ansible Playbooks

**Effort:** 1-2 hours | **Impact:** High

Current playbooks: `common.yml`, `docker.yml`, `tailscale.yml`

**Missing:**
| Playbook | Purpose |
|----------|---------|
| `backup.yml` | Deploy restic, configure cronjobs |
| `monitoring.yml` | Deploy Uptime Kuma, ntfy, configure monitors |
| `update.yml` | System and container update automation |
| `pihole.yml` | Deploy Pi-hole to all hosts |
| `caddy.yml` | Deploy Caddy, manage certificates |
| `nfs-server.yml` | Configure NFS exports on NAS |
| `docker-compose-deploy.yml` | Deploy compose files to hosts |

---

### 8. Service Startup Checklist

**Effort:** 1 hour | **Impact:** High

No end-to-end workflow documented for starting services across all 3 environments.

**Missing:**
- Service startup order across environments
- Health check commands for each service
- Verification steps (curl endpoints, port checks)
- Rollback procedures if something fails

**Create:** `docs/service-startup-guide.md`

---

### 9. Backup Configuration Gaps

**Effort:** 1 hour | **Impact:** Medium

`docs/disaster-recovery.md` exists but missing:
- Backup verification cronjob
- Automated backup scheduling
- Backup encryption key storage procedure
- Offsite backup verification automation

---

### 10. Image Pull Policies

**Effort:** 30 min | **Impact:** Medium

No compose files define `pull_policy`. Stale images persist on restart.

**Recommendation:** Add `pull_policy: always` to critical services (Headscale, Vaultwarden, Pi-hole).

---

### 11. Restic Backup Sidecar for Backup Infrastructure

**Effort:** 1 hour | **Impact:** Medium

Headscale has backup sidecar (good model). Restic REST instances have no automated backup.

---

### 12. Service Lifecycle Documentation

**Effort:** 1 hour | **Impact:** Medium

Missing:
- Blue-green deployment strategy
- Update verification procedure
- Zero-downtime update guidance
- Rollback procedures

---

### 13. Compose File Version Strategy

**Effort:** 15 min | **Impact:** Low

Versions range implicitly. Explicitly define `version: "3.9"` for `depends_on: condition:` support.

---

### 14. Incomplete Docker Network Documentation

**Effort:** 1 hour | **Impact:** Medium

Missing:
- Network isolation strategy (external networks?)
- Inter-service communication matrix

---

## Lower Priority

### 15. Prometheus/Grafana Monitoring Stack

**Effort:** 2+ hours | **Impact:** Medium

Currently only Uptime Kuma (endpoint monitoring). Missing metrics collection (CPU, memory, disk, network).

**Benefits:**
- Historical performance metrics
- Capacity planning data
- Alert thresholds on resource utilization

---

### 16. Disaster Recovery Testing Automation

**Effort:** 2+ hours | **Impact:** Medium

Missing:
- Automated monthly restore test
- ntfy notification of test results
- Test environment documentation

---

### 17. Service Upgrade Strategy

**Effort:** 2 hours | **Impact:** Low

Document for each service:
- Release notes source
- Update frequency
- Test procedure
- Rollback procedure

**Create:** `docs/service-upgrade-strategy.md`

---

### 18. Capacity Planning

**Effort:** 2 hours | **Impact:** Low

Missing:
- CPU/memory requirements per service
- Expected disk usage (Frigate recordings, media)
- Network bandwidth estimates
- Growth projections
- Upgrade triggers

**Create:** `docs/capacity-planning.md`

---

### 19. Remaining Security Fix (#20)

**Status:** Acceptable risk

**Issue:** Containers running as root

**Note:** Many containers require root. Would need per-service analysis and testing.

---

## Recommended Order

1. **Health checks + depends_on** - Critical for reliability
2. **Logging limits** - Prevent disk issues
3. **Labels** - Organization
4. **Per-service READMEs** - Knowledge transfer
5. **Service startup checklist** - Deployment confidence
6. **Ansible playbooks** - Automation
7. **Network diagram** - System understanding

---

## Files to Create

| File | Purpose |
|------|---------|
| `docs/network-topology.md` | Network visualization |
| `docs/service-startup-guide.md` | Deployment workflow |
| `docs/service-upgrade-strategy.md` | Update procedures |
| `docs/capacity-planning.md` | Resource planning |
| `ansible/playbooks/backup.yml` | Backup automation |
| `ansible/playbooks/monitoring.yml` | Monitoring deployment |
| `docker/*/README.md` (8 files) | Per-service documentation |

---

## Related Documents

- `docs/sessions/2026-01-16.md` - Session summary
- `docs/sessions/improvements-2026-01-16.md` - Completed improvements (24/24)
- `docs/sessions/security-fixes-2026-01-16.md` - Security audit (21/22 complete)
- `docs/security-hardening.md` - Security best practices
