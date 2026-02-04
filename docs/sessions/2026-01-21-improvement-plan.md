# Homelab Improvement Plan - 2026-01-21

Codebase review identified issues in Ansible playbooks, Docker Compose files, and documentation.

## Critical Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 1 | `ansible_connection_timeout` is not a valid Ansible parameter (should be `ansible_connect_timeout`) | `ansible/inventory.yml` | 82 | **Fixed** |
| 2 | Caddy references external networks (`headscale-net`, `monitoring-net`) not created by any task | `ansible/playbooks/caddy.yml` | 178-191 | **Fixed** |
| 3 | Path construction used `environment_type` instead of host-specific paths, breaking deployments | `ansible/playbooks/docker-compose-deploy.yml` | 19-42, 66-82 | **Fixed** |
| 4 | Relative path `../../../shared/backup/restic-backup.sh` will fail when executed from different directories | `docker/fixed/docker-vm/security/docker-compose.yml` | 158 | **Fixed** |
| 5 | Undefined variables with inconsistent naming (`restic_user`, `restic_pass`, `restic_password`) | `ansible/playbooks/backup.yml` | 11-14 | **Fixed** |

### Fixes Applied

1. **inventory.yml**: Changed `ansible_connection_timeout` to `ansible_connect_timeout`
2. **caddy.yml**: Added `community.docker.docker_network` tasks to create external networks before deployment
3. **docker-compose-deploy.yml**: Added `stack_paths` dictionary mapping host groups to correct directory paths (`vps`, `fixed/docker-vm`, `fixed/nas`, `mobile/rpi5`). Renamed `fixed_stacks` to `docker_vm_stacks`, `nas_stacks` to `storage_stacks`.
4. **security/docker-compose.yml**: Changed relative path to use `${HOMELAB_ROOT:-/opt/homelab/repo}` environment variable
5. **backup.yml**: Renamed variables to `restic_repo_user`, `restic_repo_pass`, `restic_password`. Added validation task with clear error message.

## High Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 6 | No `.env` files present (only `.env.example`) - fresh deployments will fail | All docker directories | - | **N/A** (handled by docker-compose-deploy.yml) |
| 7 | Pi-hole password defaults to empty string (insecure) | `ansible/playbooks/pihole.yml` | 22-31 | **Fixed** |
| 8 | NFS export paths hardcoded (`/srv/media`, `/srv/downloads`), may not exist | `ansible/playbooks/nfs-server.yml` | 12-39 | **Fixed** |
| 9 | `ignore_errors: true` masks firewall rule failures | `ansible/playbooks/common.yml` | 87-105 | **Fixed** |
| 10 | Missing Headscale playbook for VPS deployment | `ansible/playbooks/headscale.yml` | - | **Fixed** |

### Fixes Applied

6. **docker-compose-deploy.yml**: Already has task to create `.env` from `.env.example` if not exists (lines 127-134)
7. **pihole.yml**: Added `assert` task requiring `webpassword` variable with clear error message
8. **nfs-server.yml**: Made paths configurable via `nfs_data_root` and `nfs_purple_root` variables (default to `/mnt/data` and `/mnt/purple`). Added mount point validation with warning if drives not mounted.
9. **common.yml**: Replaced `ignore_errors: true` with proper conditional check for `tailscale0` interface existence
10. **headscale.yml**: Created new playbook with full deployment automation (config, docker-compose, backup script, user creation)

## Medium Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 11 | Hardcoded IPs should use environment variables or container names | Multiple docker-compose files | - | **Acceptable** (defaults with env var override) |
| 12 | Dead code: `docker_compose_version: "2"` variable defined but never used | `ansible/inventory.yml` | 93 | **Fixed** |
| 13 | Inconsistent Tailscale IP addressing between docs and configs | Multiple files | - | **Fixed** |

### Fixes Applied

11. **Hardcoded IPs**: Reviewed - IPs are used as sensible defaults with `${VAR:-default}` pattern allowing override via .env files. Acceptable design.
12. **inventory.yml**: Removed unused `docker_compose_version: "2"` variable from `docker_hosts` group
13. **Tailscale IPs**: Fixed Docker VM IP references to 100.68.63.168 in:
    - `docker/fixed/docker-vm/networking/pihole/docker-compose.yml` (DNS records comments)
    - `docker/fixed/docker-vm/networking/caddy/Caddyfile` (header comment)

## Low Priority Issues

| # | Issue | File | Line | Status |
|---|-------|------|------|--------|
| 14 | Relative paths in docker-compose assume specific working directories | Multiple files | - | **Fixed** |
| 15 | Session docs in README may reference deleted files | `README.md` | 85 | **Verified OK** |

### Fixes Applied

14. **Relative paths**: Fixed backup script mount in `docker/fixed/docker-vm/automation/docker-compose.yml` to use `${HOMELAB_ROOT:-/opt/homelab/repo}` pattern (same as security stack fix)
15. **README references**: Verified all referenced session files exist (`2026-01-16.md`, `improvements-2026-01-16.md`)

## Summary

All 15 issues have been addressed:
- **5 Critical**: Fixed
- **5 High Priority**: Fixed (1 N/A - already handled)
- **3 Medium Priority**: Fixed (1 acceptable as-is)
- **2 Low Priority**: Fixed (1 verified OK)

## Notes

- All fixes should be tested with `ansible-playbook --check` (dry-run) before applying
- Docker Compose changes should be validated with `docker compose config`
- Document any breaking changes that require manual intervention
