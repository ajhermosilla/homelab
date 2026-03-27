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

Most homelabbers set up backups and never test them. I was one of them — right up until an ISP outage corrupted my Pi-hole database, and I discovered that my "working" backup couldn't actually restore anything. The backup container didn't even have permission to read the files it was supposed to protect.

That's when I wrote a script to test everything. Here's what it found.

<!-- more -->

## The Setup

My homelab runs 68 services across three hosts: a Docker VM with 36 containers, a NAS with 19, and a VPS with 12. Each critical service has a dedicated Restic backup sidecar — a small container that wakes up on a cron schedule, takes a snapshot, and ships it to a REST server on the NAS. At 4:30 AM, an offsite sync encrypts everything and pushes it to Google Drive.

On paper, the 3-2-1 rule is satisfied. Live data (copy 1), Restic snapshots on the NAS (copy 2), encrypted Google Drive (copy 3). Two media types, one offsite. Textbook stuff.

But "on paper" doesn't help you when your DNS is down and your family can't stream Netflix on a Friday night.

## The Script

[`backup-verify.sh`](https://github.com/ajhermosilla/homelab/blob/main/scripts/backup-verify.sh) runs 8 test suites on the first Sunday of every month:

1. **Repository health** — `restic check` on the entire repo
2. **Snapshot freshness** — is each snapshot recent enough? (Headscale: 2h max age, everything else: 25h)
3. **Headscale restore** — extract the SQLite DB, verify it actually opens
4. **Vaultwarden restore** — extract the vault, verify the DB is readable
5. **Home Assistant restore** — extract config, check that `configuration.yaml` exists
6. **Paperless-ngx restore** — extract data, verify the document directory structure is intact
7. **Immich DB restore** — verify the PostgreSQL dump isn't corrupted
8. **Offsite sync** — confirm Google Drive has recent data via rclone

Each test gets a pass, fail, or skip. There's also a `--full` flag for quarterly deep restore drills where I actually spin up the restored data and verify the application starts.

The core logic is straightforward:

```bash
check_snapshot() {
    local tag="$1" max_hours="$3"
    local snapshot
    snapshot=$(restic snapshots --tag "$tag" --json | jq -r '.[-1].time // empty')
    # ... check age against max_hours
}
```

Seven services get checked. If anything is stale, the script flags it. No more silent failures.

## What Broke

### Pi-hole couldn't rebuild its own database

It started with a routine ISP outage. Power came back, containers restarted, and everything looked fine — except Pi-hole's gravity database was corrupted. Missing tables, FTL couldn't query the blocklists. No big deal, I thought. Just run `pihole -g` to rebuild it.

```text
Error: unable to open database "/etc/pihole/gravity.db": unable to open database file
```

Here's the thing: every container in my homelab runs with `cap_drop: ALL` for security hardening. It's a good practice — drop all Linux capabilities and only add back what you need. But `pihole -g` runs as root and needs to *create* a file owned by the `pihole` user. Without the `DAC_OVERRIDE` capability, root inside the container can't write to directories owned by other users.

The backup sidecar had the exact same problem — it couldn't even *read* the Pi-hole config files it was supposed to back up. So not only was the database broken, the backup was silently empty.

**The fix was two lines:**

```yaml
cap_add:
  - DAC_OVERRIDE
  - FOWNER
```

What makes this insidious is that nothing flagged it. The container was "healthy" — FTL was listening on port 53 and forwarding DNS queries just fine. Monitoring showed green. The backup sidecar was running. It just couldn't do its job.

### The same bug, again

Weeks later, the exact same `DAC_OVERRIDE` issue bit the Authelia backup sidecar — it couldn't read root-owned files in the Authelia data volume. Same pattern, same two-line fix.

This is what makes `cap_drop: ALL` tricky. It's absolutely the right security default. But it creates a gap between "the service runs fine" and "the service can be backed up and restored." The only way to close that gap is to actually test the full cycle.

## What I Learned

**Backups are not disaster recovery.** Having snapshots sitting on a disk somewhere is table stakes. What actually matters is whether your restore pipeline works end to end:

- Can the backup sidecar *read* the data it's supposed to protect?
- Can the restore process *write* the data back to where it needs to go?
- Does the application actually *start* with the restored data?

Each of these can fail independently, and none of them are tested by checking "is the backup container running?"

**Security hardening breaks recovery if you don't test it.** Capabilities that seem unnecessary at runtime — `DAC_OVERRIDE`, `FOWNER` — might be critical for backup and recovery operations. You won't know until you try, and you don't want to find out during an actual incident.

**Test the boring stuff first.** I'll be honest: I spent weeks on Mermaid diagrams, MkDocs themes, and Tailscale mesh optimization. Meanwhile, a two-line capability fix would have saved me an hour of panicked debugging during a real outage. The verification script exists so I never skip the boring stuff again.

## Try It Yourself

The full script is at [`scripts/backup-verify.sh`](https://github.com/ajhermosilla/homelab/blob/main/scripts/backup-verify.sh) in my [homelab repo](https://github.com/ajhermosilla/homelab). The backup sidecar pattern — one Restic container per service, cron-based, with healthchecks — is in every Docker Compose file under [`docker/fixed/docker-vm/`](https://github.com/ajhermosilla/homelab/tree/main/docker/fixed/docker-vm).

If you're running Restic backups in your homelab, here's a question worth sitting with: when was the last time you actually *restored* from one?

---

*I run a 68-service homelab from Paraguay, powered by Docker, Ansible, and a lot of late nights. The full infrastructure is documented at [docs.cronova.dev](https://docs.cronova.dev) and the code is public at [github.com/ajhermosilla/homelab](https://github.com/ajhermosilla/homelab).*
