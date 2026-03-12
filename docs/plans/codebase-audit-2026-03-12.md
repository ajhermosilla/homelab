# Codebase Audit Findings — 2026-03-12

Full audit of compose files, documentation, Ansible, and scripts. Filtered for remote-fixable items.

## Compose Hardening

### Missing `cap_drop: [ALL]`

| Service | File | Notes |
|---------|------|-------|
| DERP relay | `docker/vps/networking/derp/docker-compose.yml` | Has `security_opt` and `read_only`, missing cap_drop |
| Headscale | `docker/vps/networking/headscale/docker-compose.yml` | Has `cap_add: NET_ADMIN`, missing cap_drop |
| Headscale-backup | `docker/vps/networking/headscale/docker-compose.yml` | Missing cap_drop |
| VPS Pi-hole | `docker/vps/networking/pihole/docker-compose.yml` | Has `cap_add: NET_ADMIN`, missing cap_drop |
| NAS Glances | `docker/fixed/nas/monitoring/docker-compose.yml` | Also missing `security_opt: [no-new-privileges:true]` |

### Port Bindings (0.0.0.0 → 127.0.0.1)

Services with admin/API ports exposed to all interfaces that should be localhost-only:

| Service | File | Current | Fix |
|---------|------|---------|-----|
| Syncthing Web UI | `docker/fixed/nas/storage/docker-compose.yml` | `8384:8384` | `127.0.0.1:8384:8384` |
| Glances API | `docker/fixed/nas/monitoring/docker-compose.yml` | `61208:61208` | `127.0.0.1:61208:61208` |
| Uptime Kuma | `docker/vps/monitoring/docker-compose.yml` | `3001:3001` | `127.0.0.1:3001:3001` |
| changedetection | `docker/vps/scraping/docker-compose.yml` | `5000:5000` | `127.0.0.1:5000:5000` |

**Note:** NAS Restic REST (`8000:8000`) and VPS Restic REST (`8000:8000`) are also on 0.0.0.0 — docs recommend Tailscale-only, but backup clients may rely on LAN access. Evaluate before changing.

**Note:** NAS Forgejo (`3000:3000`, `2222:22`) — intentionally on 0.0.0.0 for LAN git access.

## Documentation Staleness

### NAS Container Count

Multiple docs say 12, actual is 19 (includes Javya 3, Katupyry 3, offsite-sync):

| File | Line | Current | Fix |
|------|------|---------|-----|
| `docs/README.md` | ~13 | 12 containers | 19 |
| `docs/architecture/hardware.md` | ~67, ~248 | 11/12 containers | 19 |
| `docs/architecture/fixed-homelab.md` | ~11 | 12 containers | 19 |
| `docs/architecture/services.md` | ~167 | 12 containers | 19 |

### Javya Deploy Plan

- `docs/plans/javya-deploy-nas-2026-03-02.md` still marked "Pending"
- Should be "Deployed" — Javya is live at `javya.cronova.dev`

### Services.md Numbering

- Service matrix has duplicate row #32 (Samba appears twice)
- Rows need renumbering from #32 onward

## Ansible

### Stale Repo URL

- `ansible/playbooks/docker-compose-deploy.yml` line 15: `homelab_repo` points to `https://github.com/ajhermosilla/homelab.git`
- Should be `git@git.cronova.dev:augusto/homelab.git` (Forgejo is canonical)

## Scripts

### setup-uptime-kuma.py

- Line ~176: Forgejo monitor uses `http://100.82.77.97:3000` — should be `https://git.cronova.dev`
- Line ~148: VPS Pi-hole monitors localhost — intentional (Uptime Kuma runs on VPS)

## Already Completed (This Session)

- [x] Headscale split DNS for remote access
- [x] Healthchecks for 7 missing services
- [x] Pin 7 critical image tags
- [x] VPS Pi-hole v6 + Restic REST version bumps
- [x] Sync headscale config example with live
- [x] Fix Watchtower exclusion list in security doc
