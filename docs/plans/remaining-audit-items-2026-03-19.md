# Remaining Audit Items — 2026-03-19

Unfixed items from audit rounds 0-2 that were not addressed in round 3 or subsequent sessions. Cross-referenced to eliminate items already fixed but not marked.

## HIGH Priority (2 items)

| # | Item | Source | File | Fix |
|---|------|--------|------|-----|
| 1 | Ansible docker.yml missing NAS data-root config | R2 #6 | ansible/playbooks/docker.yml | Add `data-root: /data/docker` for NAS (default `/var/lib/docker` is only 6GB) |
| 2 | Ansible backup.yml hardcodes x86_64 | R2 #7 | ansible/playbooks/backup.yml | Use `ansible_architecture` fact instead of hardcoded arch |

## MEDIUM Priority (5 items)

| # | Item | Source | File | Fix |
|---|------|--------|------|-----|
| 3 | Jellyfin not on caddy-net | R1 #10 | docker/fixed/docker-vm/media/docker-compose.yml | Intentional (excluded from Authelia). Add comment documenting why. |
| 4 | `read_only: true` underused | R1 #11 | Various | Add to changedetection, pihole (test first) |
| 5 | DERP env vars hardcoded | R1 #12 | docker/vps/networking/derp/docker-compose.yml | Move DERP_DOMAIN to .env substitution |
| 6 | Inconsistent healthcheck patterns | R1 #13 | Various | Standardize: wget for Alpine, curl for Debian, dig for DNS |
| 7 | Missing cap_drop on 5 VPS/NAS services | R0 | Various | Add `cap_drop: ALL` + required `cap_add` to DERP, Headscale, headscale-backup, VPS Pi-hole, NAS Glances |

## LOW Priority (8 items)

| # | Item | Source | File | Fix |
|---|------|--------|------|-----|
| 8 | Boot orchestrator doesn't verify critical services | R2 #15 | scripts/docker-boot-orchestrator.sh | Add healthcheck wait after each phase |
| 9 | pihole.yml resolv.conf not persistent | R2 #16 | ansible/playbooks/pihole.yml | Document as known limitation |
| 10 | TZ env format inconsistency | R2 #14 | Various compose files | Standardize to map notation `TZ:` |
| 11 | Move completed plans to journal | R1 #15 | docs/plans/ | Move forgejo-mirror, igpu-passthrough, nas-deployment to journal |
| 12 | Document cap_add rationale per service | R1 #17 | Various compose files | Add inline comments explaining each cap |
| 13 | Stale repo URL in docker-compose-deploy.yml | R0 | ansible/playbooks/docker-compose-deploy.yml | Change GitHub URL to Forgejo |
| 14 | Forgejo monitor uses IP instead of domain | R0 | scripts/setup-uptime-kuma.py | Change `http://100.82.77.97:3000` to `https://git.cronova.dev` |
| 15 | Glances API port on 0.0.0.0 | R0 | docker/fixed/nas/monitoring/docker-compose.yml | Bind to 127.0.0.1 |

## Safe to Fix Remotely (away from home)

All items are local code/config edits — no remote deployment needed. Deploy at next maintenance window.

## Fix Order

1. HIGH #1-2: Ansible fixes (NAS data-root, x86_64)
2. MEDIUM #7: Add cap_drop to 5 services
3. MEDIUM #3, #5: Jellyfin comment, DERP env vars
4. LOW #13-14: Stale URLs
5. LOW #12: Add cap_add comments
6. Remaining LOW items
