---
date: 2026-04-01
draft: true
authors:
  - augusto
categories:
  - Homelab
  - Operations
tags:
  - backup
  - restic
  - docker
  - disaster-recovery
---

# I Tested Every Backup in My 68-Service Homelab — Here's What Broke

Most homelabbers set up backups and never test them. I know because I was one of them — until a Pi-hole container refused to rebuild its database after an ISP outage, and I realized my "working" backup had a permission bug that would have made recovery impossible.

So I wrote a script that tests everything. Here's what it found.

<!-- more -->

## The Setup

My homelab runs 68 services across three hosts: a Docker VM (36 containers), a NAS (19 containers), and a VPS (12 containers). Backups use [Restic](https://restic.net/) with dedicated sidecar containers — one per critical service, each running on a nightly cron schedule, shipping snapshots to a REST server on the NAS. An offsite sync pushes everything to encrypted Google Drive at 4:30 AM.

The 3-2-1 rule is technically satisfied: live data on Docker VM (copy 1), Restic snapshots on NAS (copy 2), encrypted offsite on Google Drive (copy 3). Two media types, one offsite. Textbook.

But does any of it actually *work*?

## The Script

[`backup-verify.sh`](https://github.com/ajhermosilla/homelab/blob/main/scripts/backup-verify.sh) runs 8 test suites:

1. **Repository health** — `restic check` on the entire repo
2. **Snapshot freshness** — are snapshots recent enough? (Headscale: 2h, everything else: 25h)
3. **Headscale restore** — extract the SQLite DB, verify it opens
4. **Vaultwarden restore** — extract the vault, verify the DB is readable
5. **Home Assistant restore** — extract config, verify `configuration.yaml` exists
6. **Paperless-ngx restore** — extract data, verify document directory structure
7. **Immich DB restore** — verify the PostgreSQL dump isn't corrupted
8. **Offsite sync** — verify Google Drive has recent data via rclone

Each test gets a pass/fail/skip result. The script runs monthly on the first Sunday, with a `--full` flag for quarterly deep restore drills.

The key function is simple:

```bash
check_snapshot() {
    local tag="$1" max_hours="$3"
    local snapshot
    snapshot=$(restic snapshots --tag "$tag" --json | jq -r '.[-1].time // empty')
    # ... check age against max_hours
}
```

Seven services get checked. If any snapshot is stale, the script flags it. No silent failures.

## What Broke

### Pi-hole couldn't rebuild its own database

After an ISP outage knocked everything offline, Pi-hole came back up but its gravity database (the blocklist) was corrupted — missing tables, FTL couldn't query them. Simple fix, right? Just run `pihole -g` to rebuild.

```text
Error: unable to open database "/etc/pihole/gravity.db": unable to open database file
```

The container runs with `cap_drop: ALL` for security hardening (every container in my homelab does). But `pihole -g` runs as root and needs to *create* a file owned by the `pihole` user. Without `DAC_OVERRIDE`, root inside the container can't write to directories owned by other users.

The backup sidecar had the same issue — it couldn't *read* the Pi-hole config files to back them up.

**The fix:** Add `DAC_OVERRIDE` and `FOWNER` capabilities to the Pi-hole container. Two lines in the compose file:

```yaml
cap_add:
  - DAC_OVERRIDE
  - FOWNER
```

This wasn't caught by monitoring (the container was "healthy" — FTL was listening on port 53 and forwarding queries fine). It wasn't caught by the backup sidecar (it was also missing the capability). It was only caught when I actually tried to rebuild the database after an incident.

### The pattern repeated

The same `DAC_OVERRIDE` issue hit the Authelia backup sidecar — it couldn't read root-owned files in the Authelia data volume. The Pi-hole backup sidecar had been fixed earlier with the same cap. It's a recurring pattern: `cap_drop: ALL` is the right security default, but you need to test that your backup and recovery processes still *work* with reduced capabilities.

## What I Learned

**Backups are not disaster recovery.** Having snapshots on disk is table stakes. What matters is:

- Can the backup sidecar *read* the data it's supposed to back up?
- Can the restore process *write* the data back?
- Does the application *start* after restore?

Each of these can fail independently, and none of them are tested by checking "is the backup container running?"

**Container hardening breaks recovery if you don't test it.** `cap_drop: ALL` is a security best practice — I run it on every single container. But capabilities that seem unnecessary at runtime (`DAC_OVERRIDE`, `FOWNER`) might be critical for backup and recovery operations. The only way to find out is to actually test the restore.

**Test the boring stuff.** I spent time on Mermaid diagrams, MkDocs themes, and Tailscale mesh optimization. Meanwhile, a two-line capability fix would have saved me an hour of debugging during an actual outage. The script exists to make sure I never skip the boring stuff again.

## Try It

The full script is at [`scripts/backup-verify.sh`](https://github.com/ajhermosilla/homelab/blob/main/scripts/backup-verify.sh) in my [homelab repo](https://github.com/ajhermosilla/homelab). The backup sidecar pattern (one Restic container per service, cron-based, with healthchecks) is in every Docker Compose file under [`docker/fixed/docker-vm/`](https://github.com/ajhermosilla/homelab/tree/main/docker/fixed/docker-vm).

If you're running Restic backups in your homelab, ask yourself: when was the last time you actually *restored* from one?

---

*I run a 68-service homelab from Paraguay. The full infrastructure is documented at [docs.cronova.dev](https://docs.cronova.dev) and the code is public at [github.com/ajhermosilla/homelab](https://github.com/ajhermosilla/homelab).*
