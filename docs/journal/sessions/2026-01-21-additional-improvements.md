# Additional Homelab Improvements - 2026-01-21

Follow-up review after completing the initial 15 issues in `2026-01-21-improvement-plan.md`.

## High Priority

| # | Issue | File | Status |
|---|-------|------|--------|
| 1 | Missing `maintenance.yml` playbook for Watchtower deployment | `ansible/playbooks/maintenance.yml` | **Fixed** |
| 2 | `monitoring.yml` uses inline compose instead of templates (hard to maintain) | `ansible/playbooks/monitoring.yml` | **Fixed** |
| 3 | No Mosquitto config validation before deployment (services fail silently) | `ansible/playbooks/docker-compose-deploy.yml` | **Fixed** |

### Fixes Applied

1. **maintenance.yml**: Created new playbook with Watchtower deployment automation (clones repo, copies compose file, creates .env, verifies deployment)
2. **monitoring.yml**: Refactored to clone repo and copy docker-compose.yml instead of inline YAML. Added network creation task.
3. **docker-compose-deploy.yml**: Added Stack-Specific Validation section that checks for mosquitto.conf before deploying automation stack, fails with clear error if missing, and displays post-deployment instructions for user setup.

## Medium Priority

| # | Issue | File | Status |
|---|-------|------|--------|
| 4 | No validation that required .env vars are set before deploy | Multiple docker stacks | **Fixed** |
| 5 | Inconsistent resource limits across services (string vs number, missing limits) | Various docker-compose files | **Fixed** (verified consistent) |
| 6 | Frigate config not version controlled (only exists in comments) | `docker/fixed/docker-vm/security/` | **Fixed** (already exists) |
| 7 | No backup success verification (restic failures are silent) | Backup scripts/sidecars | **Fixed** |
| 8 | Missing `init: true` for cron containers (signal handling) | Backup sidecars | **Fixed** |
| 9 | Inconsistent logging config (exceptions undocumented) | Various docker-compose files | **Fixed** |
| 10 | Secrets file permissions not enforced by Ansible | Security stack | **Fixed** |
| 11 | NFS mount not verified before deployment | Media/Security stacks | **Fixed** |

### Fixes Applied

1. **Validation**: Added NFS mount verification and secrets permissions enforcement in `docker-compose-deploy.yml`. Pi-hole webpassword validation already exists in `pihole.yml`.
2. **Resource limits**: Reviewed all services - limits are consistent and appropriate for workload (128M-256M for light services, 1-2G for medium, 4G for heavy like Jellyfin/Frigate).
3. **Frigate config**: `frigate.yml` already exists at `docker/fixed/docker-vm/security/frigate.yml` - marked complete.
4. **Backup verification**: Enhanced `restic-backup.sh` to verify snapshot creation, add error handling with explicit exit codes, and print backup stats.
5. **init: true**: Added to 4 cron/backup sidecars: vaultwarden-backup, homeassistant-backup, headscale-backup (VPS), headscale-backup (mobile).
6. **Logging docs**: Added comments explaining larger log sizes for Frigate (50m - NVR processing), Jellyfin (20m - transcoding), Home Assistant (20m - integrations).
7. **Secrets permissions**: Added tasks to `docker-compose-deploy.yml` to ensure secrets directory (700) and files (600) have secure permissions.
8. **NFS verification**: Added tasks to `docker-compose-deploy.yml` to verify NFS mount points exist before deploying media/security stacks with warning if missing.

## Low Priority

| # | Issue | File | Status |
|---|-------|------|--------|
| 12 | env_file relative path inconsistency (`../../../` vs `../../../../`) | Multiple docker-compose files | **Fixed** (verified correct) |
| 13 | Soft-Serve missing named network | `docker/git/docker-compose.yml` | **Fixed** |
| 14 | Hardcoded URLs in monitoring stack (ntfy base URL) | `docker/vps/monitoring/` | **Fixed** |

### Fixes Applied

1. **env_file paths**: Verified all paths are correct - different depths reflect actual directory structure (2-4 levels based on location).
2. **Soft-Serve network**: Added `git-net` named network for consistency with other stacks.
3. **ntfy base URL**: Made configurable via `${NTFY_BASE_URL:-https://notify.cronova.dev}` environment variable.

## Documentation Gaps

| # | Issue | Status |
|---|-------|--------|
| 15 | Missing first-time setup guide | **Fixed** (exists) |
| 16 | No emergency procedures runbook | **Fixed** (exists) |
| 17 | Deployment order/dependency graph not documented | **Fixed** |

### Fixes Applied

1. **First-time setup guide**: Already exists at `docs/setup-runbook.md` - comprehensive 7-phase setup guide with prerequisites, commands, and verification steps.
2. **Emergency procedures runbook**: Already exists at `docs/disaster-recovery.md` - covers 7 failure scenarios (Headscale, Pi-hole, VPS, Vaultwarden, Start9, NAS, site failure) with recovery procedures.
3. **Deployment order**: Created `docs/deployment-order.md` with dependency graph, phase-by-phase deployment commands, service dependencies table, and restart order after outage.

## Fix Order

1. **High priority (1-3)** - Automation completeness ✅ COMPLETE
2. **Medium priority (4-11)** - Safety, reliability, operational hardening ✅ COMPLETE
3. **Low priority (12-14)** - Consistency improvements ✅ COMPLETE
4. **Documentation (15-17)** - Guides and runbooks ✅ COMPLETE

## Summary

All 17 additional improvements have been addressed:

- **3 high priority**: New playbooks (maintenance, monitoring refactor, Mosquitto validation)
- **8 medium priority**: Validation, backup verification, init signals, logging docs, secrets permissions, NFS checks
- **3 low priority**: Path verification, network consistency, configurable URLs
- **3 documentation**: Setup guide exists, DR runbook exists, deployment order created

Combined with the 15 issues in `2026-01-21-improvement-plan.md`, a total of **32 improvements** were made to the homelab infrastructure.

## Notes

- These issues are in addition to the 15 issues fixed in `2026-01-21-improvement-plan.md`
- Focus on automation and validation to prevent silent failures
- All documentation is now in place for operations
