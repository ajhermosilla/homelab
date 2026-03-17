# Codebase & Documentation Audit — 2026-03-15

**Status**: Active — findings to be fixed incrementally
**Scope**: All Docker Compose files, documentation, scripts, and Ansible across Docker VM, NAS, and VPS

---

## High Priority

### ~~1. Image pinning — 4 services using `latest` tags~~ (FIXED 2026-03-15)

Services without pinned versions:

| Service | Image | Host | Notes |
|---------|-------|------|-------|

| cadvisor | `gcr.io/cadvisor/cadvisor:latest` | Docker VM | Pin to stable release |
| dozzle | `amir20/dozzle:latest` | Docker VM | Pin to stable release |
| bentopdf | `ghcr.io/alam00000/bentopdf:latest` | Docker VM | Pin to stable release |
| homepage | `ghcr.io/gethomepage/homepage:latest` | Docker VM | Pin to stable release |

**Excluded from this finding**: sonarr, radarr, prowlarr use `latest` intentionally.
LinuxServer.io removed the old pinned tags (sonarr:4.0, radarr:5.0) from Docker Hub.
Their `latest` tag tracks the current stable release and is managed responsibly.
Watchtower handles updates. This is the recommended approach for LinuxServer.io images.

### ~~2. Pi-hole + Caddy configs not backed up~~ (FIXED 2026-03-16)

Critical infrastructure without backup sidecars:

- **Pi-hole**: `/etc/pihole` config (DNS rules, blocklists, 23 local DNS entries)
- **Caddy**: `/data` and `/config` (TLS certificates, ACME state)

Both are recoverable but tedious to recreate manually.

### ~~3. Missing Watchtower labels~~ (FIXED 2026-03-16)

~13 services lack explicit `com.centurylinklabs.watchtower.enable` label.
Without it, Watchtower's default behavior applies (update everything).
Services that should explicitly opt out: critical infrastructure (DNS, Caddy, Headscale).

Affected: forgejo, glances, syncthing, javya services, VPS caddy, derp, pihole,
uptime-kuma, ntfy, changedetection, playwright.

### ~~4. services.md missing VPS services~~ (FIXED 2026-03-15)

`docs/architecture/services.md` doesn't document:

- AdGuard + Unbound (yvága stack) — deployed and active
- Scraping stack (changedetection + playwright) — deployed and active
- VPS backup stack (restic-rest) — deployed and active

### ~~5. dns-architecture.md outdated~~ (FIXED 2026-03-16)

Doesn't document the yvága pipeline (AdGuard → Unbound → root servers).
Still references "Pi-hole on VPS" as the primary VPS DNS, but AdGuard is now
the actual DNS resolver on VPS with Pi-hole as a secondary/legacy entry.

### ~~6. deployment-order.md missing yvága + DERP commands~~ (FIXED 2026-03-16)

DERP relay appears in the dependency diagram but deployment commands section
skips it entirely. Should add DERP deployment step after Pi-hole (VPS).

### ~~7. Completed plans still in `/docs/plans/`~~ (FIXED 2026-03-16)

Plans that are done but not moved to journal/reference:

- `igpu-passthrough-plan-2026-02-25.md` — iGPU passthrough completed 2026-03-02
- `nas-deployment-plan.md` — NAS fully deployed
- `javya-deploy-nas-2026-03-02.md` — Javya deployed on NAS
- `frigate-improvement-plan-2026-03-02.md` — Phase 1 complete (iGPU + OpenVINO)
- `forgejo-github-mirror-2026-03-02.md` — Push mirror active

### ~~8. docker-boot-orchestrator.sh — verify stack paths~~ (VERIFIED 2026-03-16 — all 11 paths OK)

Script references stack paths that may not match actual directory structure.
Needs verification against current compose file locations on Docker VM.

### ~~9. docker-compose-deploy.yml — missing NAS stacks~~ (FIXED 2026-03-16)

Ansible playbook `docker-compose-deploy.yml` lists NAS stacks but is missing:

- Coolify (tajy) — may be intentional (Coolify manages itself)
- Javya — deployed via `~/deploy/javya/`, not from repo path
- Katupyry — deployed via Coolify

Document why these are excluded if intentional.

---

## Medium Priority

### 10. Jellyfin not on caddy-net

Jellyfin exposes port 8096 directly instead of going through Caddy reverse proxy.
This is intentional (excluded from Authelia — mobile/TV clients can't handle redirects),
but should be documented as a deliberate exception.

### 11. `read_only: true` underused

Only 5 services use read-only rootfs. Stateless services that could benefit:

- changedetection (VPS)
- pihole containers
- cadvisor already has it

### 12. DERP environment variables hardcoded

`docker/vps/networking/derp/docker-compose.yml` has multiple `DERP_*` env vars
hardcoded in the compose file instead of using `.env` substitution.

### 13. Inconsistent healthcheck patterns

Mix of tools across stacks:

- `wget` (BusyBox containers — must use `127.0.0.1`, not `localhost`)
- `curl` (full distro containers)
- `nc` (DERP)
- `dig`/`drill` (DNS services)
- `python3 urllib` (immich-ml)

Not necessarily wrong, but should document the pattern: use whatever tool
is available in the container image.

### 14. VPS restic-rest missing `cap_add`

NAS version has `cap_add: [DAC_OVERRIDE]` but VPS version doesn't.
Should be consistent.

---

## Low Priority

### 15. Move completed plans to `/docs/journal/`

Separate active plans from completed ones for clarity.

### 16. Standardize env var required pattern

Mix of `:?` (required, fails if missing) and `:-` (default value) across stacks.
Critical passwords/tokens should use `:?`, optional config should use `:-`.

### 17. Document cap_add rationale per service

Each `cap_add` entry should have a comment explaining why it's needed.
Already done in some places (pihole, forgejo) but not consistently.

### 18. Add `depends_on` with health condition to changedetection → playwright

Currently changedetection starts without waiting for playwright health.

---

## Patterns Done Well

These are solid across the entire codebase:

- All services have healthchecks
- All services have resource limits (memory + CPU)
- All services have logging configuration (json-file with max-size/max-file)
- All services have `cap_drop: [ALL]` + `security_opt: [no-new-privileges:true]`
- All stacks have `.env.example` files
- Proper dependency chains with `service_healthy` conditions
- Consistent labeling with `com.cronova.environment` and `com.cronova.category`
- Backup sidecars for critical stateful services (VW, HA, Paperless, Immich)
- Secrets properly gitignored with `.env.example` templates committed

---

## Image Tagging Policy

**Pinned versions** (default): Use specific version tags for reproducibility.
Example: `postgres:17-alpine`, `adguard/adguardhome:v0.107.73`

**`latest` tag acceptable** when:

- The image maintainer manages `latest` as a stable release channel (LinuxServer.io)
- Old version tags are removed from registries (sonarr, radarr, prowlarr)
- Watchtower is enabled to handle updates automatically
- The service is non-critical and can tolerate automatic updates

**Never use `latest`** on: DNS (pihole, adguard, unbound), headscale, databases (postgres),
or any service where an unexpected update could cause an outage.
