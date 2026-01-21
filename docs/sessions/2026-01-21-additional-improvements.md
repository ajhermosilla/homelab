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
| 4 | No validation that required .env vars are set before deploy | Multiple docker stacks | Pending |
| 5 | Inconsistent resource limits across services (string vs number, missing limits) | Various docker-compose files | Pending |
| 6 | Frigate config not version controlled (only exists in comments) | `docker/fixed/docker-vm/security/` | Pending |
| 7 | No backup success verification (restic failures are silent) | Backup scripts/sidecars | Pending |
| 8 | Missing `init: true` for cron containers (signal handling) | Backup sidecars | Pending |
| 9 | Inconsistent logging config (exceptions undocumented) | Various docker-compose files | Pending |
| 10 | Secrets file permissions not enforced by Ansible | Security stack | Pending |
| 11 | NFS mount not verified before deployment | Media/Security stacks | Pending |

## Low Priority

| # | Issue | File | Status |
|---|-------|------|--------|
| 12 | env_file relative path inconsistency (`../../../` vs `../../../../`) | Multiple docker-compose files | Pending |
| 13 | Soft-Serve missing named network | `docker/git/docker-compose.yml` | Pending |
| 14 | Hardcoded URLs in monitoring stack (ntfy base URL) | `docker/vps/monitoring/` | Pending |

## Documentation Gaps

| # | Issue | Status |
|---|-------|--------|
| 15 | Missing first-time setup guide | Pending |
| 16 | No emergency procedures runbook | Pending |
| 17 | Deployment order/dependency graph not documented | Pending |

## Fix Order

1. **High priority (1-3)** - Automation completeness
2. **Medium priority (4-11)** - Safety, reliability, operational hardening
3. **Low priority (12-14)** - Consistency improvements
4. **Documentation (15-17)** - Guides and runbooks

## Notes

- These issues are in addition to the 15 issues fixed in `2026-01-21-improvement-plan.md`
- Focus on automation and validation to prevent silent failures
- Documentation gaps can be addressed incrementally
