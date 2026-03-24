# Incident Report: Power Outage + Git Reset Config Wipe

**Date**: 2026-03-24
**Duration**: ~2 hours (power restoration + troubleshooting)
**Severity**: High — multiple critical services down, cameras offline, Authelia SSO broken
**Trigger**: Power disconnection at home (manual NAS restart required)

---

## Summary

A power disconnection took the NAS offline. The NAS did not auto-restart (known BIOS limitation — boots from USB). After manual restart, 16 of 36 Docker VM containers failed to start due to cascading effects from a previous `git reset --hard` that had wiped local `.env` secrets, Authelia password hashes, and Frigate camera configurations.

**Three distinct failures surfaced:**

1. **NAS offline** — power loss, no auto-restart (BIOS/USB boot issue)
2. **Authelia crash loop** — password hashes replaced with repo placeholders after `git reset --hard`
3. **Immich migration failure** — pinned v2.5.6 incompatible with DB upgraded to v2.6.1 by Watchtower
4. **Frigate unhealthy** — camera IPs and zone coordinates replaced with `<REDACTED>` placeholders

---

## Timeline (PYT, UTC-3)

| Time | Event |
|------|-------|
| ~09:30 | Power disconnection at home |
| ~09:30 | NAS goes offline (no UPS, no auto-restart) |
| ~09:30 | Docker VM: 16 NFS-dependent containers stop working |
| 09:45 | Investigation begins — Mac on phone hotspot, Docker VM reachable via Tailscale |
| 09:50 | Docker VM has internet (OPNsense OK), but NAS (192.168.0.12) unreachable |
| 09:55 | NAS manually restarted (power button) |
| 10:00 | NAS back online — all 19 containers healthy |
| 10:05 | Docker VM: NFS mounts partially restored (only /srv/frigate) |
| 10:10 | `mount -a` fails for media/downloads/photos NFS (exports don't exist yet — 8TB recovery pending) |
| 10:15 | Start remaining Docker VM stacks — Authelia crash loop detected |
| 10:20 | Root cause: `users_database.yml` has placeholder hashes (from `git reset --hard` during filter-repo) |
| 10:35 | Regenerated Argon2 hashes for both users, restarted Authelia — healthy |
| 10:40 | Documents + Photos stacks fail: `RESTIC_PASSWORD` missing from `.env` (same git reset cause) |
| 10:42 | Restored RESTIC_PASSWORD to documents and photos `.env` files |
| 10:45 | All stacks starting — Immich server still crash-looping |
| 10:50 | Root cause: DB has migration from v2.6.1, but server pinned to v2.5.6 |
| 10:55 | Switched Immich to `release` tag (v2.6.1) — healthy |
| 11:00 | Frigate unhealthy — camera IPs are `<REDACTED>` placeholders |
| 11:05 | Restored real camera IPs and zone coordinates from `frigate-zones-real.local` |
| 11:10 | Frigate restarted — healthy, cameras green |
| 11:15 | **Full recovery: 36/36 Docker VM + 19/19 NAS containers healthy** |

---

## Root Causes

### 1. Power Outage (no UPS)

Home power disconnection. The NAS boots from USB (ASUS BIOS can't detect SSD UEFI) and does not auto-restart after power loss. Manual power button press required.

**Impact**: NAS offline until physically restarted. Docker VM NFS-dependent containers fail.

### 2. Git Reset Config Wipe (the real problem)

Multiple `git filter-repo` operations (for secrets purge and domain strategy purge) required `git reset --hard origin/main` on deployed hosts to sync with the rewritten history. This overwrote:

- **Authelia `users_database.yml`**: real Argon2 password hashes → placeholder `$REPLACE_WITH_REAL_HASH`
- **Frigate `frigate.yml`**: real camera IPs → `<CAMERA_FRONT_IP>` placeholders, real zone coordinates → `<REDACTED>`
- **Documents `.env`**: RESTIC_PASSWORD removed (added by `:?` validation, not in repo)
- **Photos `.env`**: same RESTIC_PASSWORD issue

These changes were silent — containers continued running with cached config until restarted (by this power outage).

### 3. Immich Version Mismatch

Watchtower auto-upgraded Immich from v2.5.6 to v2.6.1 before we pinned the version. The DB received migration `1773242919341-EncodedVideoAssetFiles` from v2.6.1. When we pinned to v2.5.6, the server couldn't start because it didn't recognize the newer migration.

### 4. NFS Mounts Not Configured

Only `/srv/frigate` NFS export exists on the NAS. Media, downloads, and photos exports are planned for after the 8TB recovery. Docker VM fstab has `nofail` so these fail silently, but containers expecting the mounts start with the root filesystem instead.

---

## Actions Taken

| # | Action | Result |
|---|--------|--------|
| 1 | Manually restarted NAS | NAS online, 19 containers healthy |
| 2 | NFS remount (`mount -a`) | Only frigate mount succeeded (others don't exist yet) |
| 3 | Regenerated Authelia Argon2 hashes via Docker | Authelia healthy |
| 4 | Restored RESTIC_PASSWORD to documents + photos `.env` | Stacks started |
| 5 | Switched Immich from v2.5.6 to v2.6.1 (matching DB) | Immich healthy (PR #45) |
| 6 | Restored camera IPs + zone coordinates in frigate.yml | Frigate healthy, cameras online |

---

## Cascading Failure Analysis

```text
Power Outage
  → NAS offline (no UPS, no auto-restart)
    → Docker VM NFS mounts fail
      → 16 containers stop/crash
        → Containers restart after NAS returns
          → Authelia crash loop (placeholder hashes from git reset)
            → Authelia-dependent services can't start
          → Immich crash loop (DB ahead of pinned version)
          → Frigate unhealthy (redacted camera IPs from git reset)
          → Documents/Photos fail (missing RESTIC_PASSWORD from git reset)

Root problem: git reset --hard wiped local configs silently.
Containers ran with cached config until power outage forced restarts.
```

---

## Prevention Plan

### P0 — Immediate

#### 1. Never Run `git reset --hard` on Deployed Hosts

The `git reset --hard origin/main` pattern after `filter-repo` destroys local configuration that differs from the repo (secrets, redacted values, pinned versions).

**Alternative**: After a filter-repo force push, on deployed hosts use:

```bash
git fetch origin
git checkout origin/main -- .  # checkout files without resetting HEAD
```

Or better: use Ansible to deploy, which applies repo changes but preserves `.env` files and local overrides.

#### 2. Backup `.env` Files Before Any Git Reset

```bash
# On deployed host, before git operations:
mkdir -p /tmp/env-backup-$(date +%Y%m%d)
find /opt/homelab/repo/docker -name ".env" -exec cp --parents {} /tmp/env-backup-$(date +%Y%m%d)/ \;
```

Add this to MEMORY.md as a gotcha.

#### 3. Pin Immich to Correct Version — DONE

Updated from v2.5.6 to v2.6.1 matching DB migration state (PR #45).

#### 4. Document Frigate Local Config Restoration

The `frigate-zones-real.local` file (gitignored) contains real camera IPs and zone coordinates. After any git reset, these must be manually restored. Consider an Ansible task for this.

### P1 — Short Term

#### 5. UPS for NAS

The NAS has no UPS. A power flicker takes it offline and requires manual restart. The UPS purchase is already on the pending list.

#### 6. NAS Auto-Restart After Power Loss

ASUS BIOS: check for "Restore on AC Power Loss" setting. Current behavior is "stay off" after power loss. If the BIOS supports it, enable "Power On" after AC restore.

#### 7. Ansible-Based Deployment

Instead of `git pull && docker compose up` on deployed hosts, use Ansible playbooks that:

- Pull latest repo changes
- Preserve `.env` files (never overwrite)
- Apply local overrides (camera IPs, zone coordinates)
- Restart only changed containers

This eliminates the entire class of "git reset wiped my config" incidents.

#### 8. `.env` Backup in Restic

The `backup-env.sh` script exists but only covers Docker VM. Extend to NAS stacks. Add to the offsite sync so `.env` files are backed up to Google Drive.

---

## Lessons Learned

1. **`git reset --hard` is a deployment anti-pattern.** It wipes everything that differs from the repo — including secrets, local overrides, and version pins. Every `filter-repo` force push has caused downstream issues on deployed hosts.

2. **Redacted configs in the repo create a deployment trap.** Camera IPs, zone coordinates, and password hashes are redacted for the public repo but needed for deployment. The gap between "what's in git" and "what's deployed" grows with each security scrub.

3. **Silent config drift is dangerous.** Containers continued running with cached old configs after the git reset. The problems only surfaced when containers restarted (power outage). This could have been weeks later with harder-to-diagnose symptoms.

4. **Immich version pinning must match DB state.** Watchtower upgraded the DB before we pinned the server version. Always check `docker logs` for the running version before pinning.

5. **A UPS would have prevented this entire incident.** The NAS going offline was the trigger. A $40 UPS riding through a brief power disconnection would have avoided 2 hours of troubleshooting.

---

## References

- Previous incidents: `incident-2026-03-05-isp-outage.md`, `incident-2026-03-18-wan-nat-outage.md`
- Frigate zones backup: `docker/fixed/docker-vm/security/frigate-zones-real.local`
- `.env` backup script: `docker/shared/backup/backup-env.sh`
- NAS boot issue: documented in MEMORY.md ("NAS boots from USB — ASUS BIOS can't detect SSD UEFI")
