# Low Priority Audit Fixes — Batch Plan 2026-03-18

50 LOW items from codebase audit round 3, grouped into safe local-only batches.

## Batch A — Docker: Backup sidecar healthchecks (7 items)

Add `pgrep crond || exit 1` healthcheck to all backup sidecars:

| Sidecar | File |
|---------|------|
| caddy-backup | docker/fixed/docker-vm/networking/caddy/docker-compose.yml |
| pihole-backup | docker/fixed/docker-vm/networking/pihole/docker-compose.yml |
| homeassistant-backup | docker/fixed/docker-vm/automation/docker-compose.yml |
| vaultwarden-backup | docker/fixed/docker-vm/security/docker-compose.yml |
| paperless-backup | docker/fixed/docker-vm/documents/docker-compose.yml |
| immich-backup | docker/fixed/docker-vm/photos/docker-compose.yml |
| coolify-backup | docker/fixed/nas/paas/docker-compose.backup.yml |

Status: [ ] Not started

## Batch B — Docker: Minor fixes (9 items)

| # | Fix | File |
|---|-----|------|
| 1 | `depends_on` → `service_healthy` for HA-backup | automation/docker-compose.yml |
| 2 | `depends_on` → `service_healthy` for vaultwarden-backup | security/docker-compose.yml |
| 3 | `depends_on` → `service_healthy` for immich-valkey | photos/docker-compose.yml |
| 4 | Remove `backup=true` label from Jellyfin (no sidecar) | media/docker-compose.yml |
| 5 | Add `:ro` to Samba smb.conf mount | nas/storage/docker-compose.yml |
| 6 | Add `watchtower.enable=false` to Forgejo | nas/git/docker-compose.yml |
| 7-10 | Fix wrong images in services.md (vaultwarden-backup, Immich DB, Samba, Syncthing) | docs/architecture/services.md |
| 11 | Fix duplicate row numbers in services.md | docs/architecture/services.md |

Status: [ ] Not started

## Batch C — Scripts: Quality fixes (8 items)

| # | Fix | File |
|---|-----|------|
| 1 | Extract helper function in backup-verify.sh (7 duplicated patterns) | scripts/backup-verify.sh |
| 2 | grep→jq for JSON parsing | docker/shared/backup/immich-db-backup.sh |
| 3 | grep→jq for snapshot counting (line 95) | docker/shared/backup/restic-backup.sh |
| 4 | Add `\|\| true` after curl (don't fail if ntfy down) | scripts/backup-notify.sh |
| 5 | Suppress password echo to stdout | scripts/nas-prep-env.sh |
| 6 | Pin OpenClaw version (`state: present`) | ansible/playbooks/openclaw.yml |
| 7 | Change `template` to `copy` module | ansible/playbooks/nfs-server.yml |
| 8 | Add `--help` flag | scripts/docker-boot-orchestrator.sh |

Status: [ ] Not started

## Batch D — Docs: Remaining cleanup (10 items)

| # | Fix | File |
|---|-----|------|
| 1 | Samba image → `dockurr/samba:4.23.5` | docs/architecture/services.md |
| 2 | Add *arr Guarani names (japysaka, taanga, aoao) | docs/architecture/services.md + reference/guarani-naming |
| 3 | Remaining 33→35 container count refs | docs/architecture/fixed-homelab.md |
| 4 | Documents port 8000→8010 | docs/architecture/fixed-homelab.md |
| 5 | Fix broken relative path | docs/architecture/mobile-homelab.md |
| 6 | Mark verava.ai status | docs/strategy/domain-strategy.md |
| 7 | Update stale upstream recommendation | docs/strategy/dns-architecture.md |
| 8 | Verify Immich host fix (NAS→Docker VM) | docs/reference/guarani-naming-convention |
| 9 | Add Javya/Katupyry deploy paths | docs/architecture/services.md |
| 10 | Documents stack port discrepancy | docs/architecture/services.md |

Status: [ ] Not started

## Batch E — Ansible: Minor fixes (3 items)

| # | Fix | File |
|---|-----|------|
| 1 | Remove `git force:yes` | ansible/playbooks/monitoring.yml |
| 2 | Remove `git force:yes` | ansible/playbooks/maintenance.yml |
| 3 | Document SSH key requirement | ansible/playbooks/dotfiles.yml |

Status: [ ] Not started

## Recommended Order

A → B → D → C → E

All local-only — no remote deployment needed. Deploy at next maintenance window.
