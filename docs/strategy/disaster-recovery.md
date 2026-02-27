# Disaster Recovery Runbook

Procedures for recovering from failures across all homelab environments.

## Quick Reference — Emergency Cheat Sheet

**Recovery priority order:**

1. **Headscale** (VPS) — mesh network dies without it
2. **Pi-hole** (Docker VM) — DNS resolution
3. **Caddy** (Docker VM) — reverse proxy for all services
4. **Vaultwarden** (Docker VM) — password access
5. **Home Assistant** (Docker VM) — automations
6. Everything else

**SSH access:**

| Host | Command | User |
|------|---------|------|
| VPS | `ssh vps` | `linuxuser` |
| Docker VM | `ssh docker-vm` | `augusto` |
| NAS | `ssh nas` | `augusto` |
| Proxmox | `ssh proxmox` | `root` |

**Restic REST server:**
```
http://augusto:<PASS>@192.168.0.12:8000/augusto/<service>
```

**ntfy alerts:** `https://notify.cronova.dev` (topics: `cronova-critical`, `cronova-warning`, `cronova-info`)

**Compose file locations:**
- Docker VM: `/opt/homelab/repo/docker/fixed/docker-vm/`
- NAS: `/opt/homelab/repo/docker/fixed/nas/`
- VPS: `/opt/homelab/headscale/`, `/opt/homelab/caddy/`

---

## Backup Architecture

### How Backups Work

All backups use **Restic** with a centralized REST server on the NAS. Each backed-up service has a dedicated **sidecar container** that runs the shared backup script on a cron schedule.

```
[Vaultwarden Sidecar]──┐
[HA Sidecar]────────────┼──► Restic REST Server (NAS :8000) ──► /mnt/purple/backup/restic/
[Coolify Sidecar]───────┘
                              ▲
[Headscale Sidecar]──► Local backup on VPS (separate — hourly tar.gz)
```

**Components:**

| Component | Details |
|-----------|---------|
| REST server | `restic/rest-server:0.14.0` on NAS, port 8000 |
| Data path | `/mnt/purple/backup/restic/` (WD Purple 2TB) |
| Auth | htpasswd file, `--private-repos` (forces `/username/` prefix) |
| Shared script | `docker/shared/backup/restic-backup.sh` |
| Default retention | 7 daily, 4 weekly, 12 monthly |
| Integrity check | Weekly on Sundays (automatic in backup script) |

### Backup Schedule

All times in PYT (America/Asuncion).

| Service | Container | Schedule | Repository | What's Backed Up |
|---------|-----------|----------|------------|------------------|
| Headscale | headscale-backup | Hourly | VPS local (`/backup/`) | SQLite DB + noise key + config |
| Vaultwarden | vaultwarden-backup | 2:00 AM daily | `/augusto/vaultwarden` | vaultwarden-data volume |
| Home Assistant | homeassistant-backup | 2:30 AM daily | `/augusto/homeassistant` | homeassistant-config volume |
| Coolify | coolify-backup | 3:30 AM daily | `/augusto/coolify` | PostgreSQL dumps + SSH keys |

**Home Assistant exclusions:** `*.log`, `*.db-shm`, `*.db-wal`, `home-assistant_v2.db`

### Backup Storage — Current State

| Target | Location | Contents | Status |
|--------|----------|----------|--------|
| Restic REST (NAS) | `/mnt/purple/backup/restic/` | Vaultwarden, HA, Coolify | Active (WD Purple 2TB, **97% full**) |
| VPS local | `/backup/` in headscale-backup container | Headscale SQLite + config | Active (hourly) |
| Google Drive (encrypted) | `gdrive-crypt:homelab/` | Restic repos + Headscale backups | Active (4:30 AM daily, rclone crypt) |

**Known gaps — documented honestly:**

- **WD Purple at 97% capacity** — Restic pruning keeps it in check, but monitor closely
- **WD Red Plus 8TB** installed in NAS but partition needs recovery/reformatting (see `journal/red-8tb-recovery-2026-02-22.md`)
- **Offsite backup configured** — verify monthly that GDrive sync is current and restorable
- **3-2-1 strategy partially complete** — offsite configured; still needs: (1) Red 8TB reformatted, (2) second 8TB drive

### Notification Integration

Backup success/failure notifications use `scripts/backup-notify.sh`:
- Failures → `cronova-critical` (urgent priority)
- Success → `cronova-info` (default priority)
- Script sends to `https://notify.cronova.dev` with service-specific tags

---

## Recovery Scenarios

### Scenario 1: VPS Failure

**Impact:** Headscale (mesh network), Uptime Kuma (monitoring), ntfy (notifications), public Caddy endpoints

**Symptoms:** Tailscale clients show "Unable to connect to coordination server", no ntfy alerts

**Recovery:**

```bash
# 1. Provision new Vultr instance (Debian, $6/mo, any region)
# 2. Initial setup
ssh root@NEW_IP
apt update && apt upgrade -y
apt install -y docker.io docker-compose-plugin

# 3. Create user and deploy
useradd -m -s /bin/bash linuxuser
usermod -aG docker linuxuser

# 4. Clone homelab repo
su - linuxuser
git clone git@github.com:ajhermosilla/homelab.git /opt/homelab
# Or from Forgejo if accessible: git@git.cronova.dev:augusto/homelab.git

# 5. Restore Headscale from backup
# If NAS accessible, copy backups from NAS:
scp augusto@nas:/backup/headscale/*.tar.gz /tmp/
tar -xzf /tmp/headscale_latest.tar.gz -C /opt/homelab/headscale/config/

# 6. Create .env files from .env.example templates
cd /opt/homelab/headscale && cp .env.example .env
# Edit .env with secrets from Vaultwarden

# 7. Start services
cd /opt/homelab/headscale && docker compose up -d
cd /opt/homelab/caddy && docker compose up -d

# 8. Update DNS — point hs.cronova.dev, notify.cronova.dev to NEW_IP (Cloudflare)

# 9. Install Tailscale and join mesh
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --login-server=https://hs.cronova.dev

# 10. Deploy remaining VPS services (uptime-kuma, ntfy)
```

### Scenario 2: Docker VM Failure

**Impact:** All Docker VM services (20+ containers) — Pi-hole, Caddy, Frigate, HA, Vaultwarden, etc.

**Recovery:**

```bash
# 1. Recreate VM in Proxmox (VM 101)
#    - 4 vCPU, 9GB RAM, 100GB disk
#    - vmbr1 only (LAN), static IP 192.168.0.10
#    - Install Debian 13

# 2. Install Docker
ssh augusto@docker-vm
sudo apt update && sudo apt install -y docker.io docker-compose-plugin
sudo usermod -aG docker augusto

# 3. Clone repo
sudo mkdir -p /opt/homelab && sudo chown augusto:augusto /opt/homelab
git clone git@git.cronova.dev:augusto/homelab.git /opt/homelab/repo

# 4. Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --login-server=https://hs.cronova.dev

# 5. Set up NFS mounts
sudo mkdir -p /mnt/nas/{frigate,media,downloads,photos}
# Add fstab entries (see docs/guides/nfs-setup.md)
sudo mount -a

# 6. Create .env files for each stack from .env.example
# Secrets are in Vaultwarden (cached on devices if Vaultwarden is down)

# 7. Run boot orchestrator
sudo /opt/homelab/repo/scripts/docker-boot-orchestrator.sh
# This starts all 10 stacks in correct dependency order

# 8. Restore Vaultwarden data from Restic
export RESTIC_REPOSITORY="rest:http://augusto:PASS@192.168.0.12:8000/augusto/vaultwarden"
export RESTIC_PASSWORD="<password>"
restic restore latest --target /tmp/vaultwarden-restore --tag vaultwarden
docker stop vaultwarden
# Copy restored data into vaultwarden-data volume
docker run --rm -v vaultwarden-data:/data -v /tmp/vaultwarden-restore:/restore alpine \
    sh -c "rm -rf /data/* && cp -a /restore/data/* /data/"
docker start vaultwarden

# 9. Restore Home Assistant config similarly
export RESTIC_REPOSITORY="rest:http://augusto:PASS@192.168.0.12:8000/augusto/homeassistant"
restic restore latest --target /tmp/ha-restore --tag homeassistant
docker stop homeassistant
docker run --rm -v homeassistant-config:/config -v /tmp/ha-restore:/restore alpine \
    sh -c "rm -rf /config/* && cp -a /restore/config/* /config/"
docker start homeassistant
```

### Scenario 3: NAS Failure

**Impact:** Forgejo (git), Coolify (PaaS), Samba (file shares), Syncthing (sync), Restic REST (backup target), NFS exports (Frigate recordings, media)

**Recovery:**

```bash
# 1. NAS boots from USB (Generic Flash Disk 3.7GB) — must stay plugged in
#    Boot flow: USB UEFI → GRUB → kernel/initramfs → SSD LVM root
#    If USB is lost, use SystemRescue 12.03 on Lexar 128GB USB to rebuild boot

# 2. Once booted, check Docker
ssh augusto@nas
sudo systemctl status docker
# Docker data-root is /data/docker (NOT /var/lib/docker)

# 3. If Docker corruption (ghost containers):
sudo systemctl stop docker docker.socket containerd
sudo sh -c 'rm -rf /data/docker/containers/*'
sudo systemctl start containerd && sudo systemctl start docker
# Named volumes survive in /data/docker/volumes/

# 4. Clone/pull repo
cd /opt/homelab/repo && git pull
# Or fresh clone: git clone git@git.cronova.dev:augusto/homelab.git /opt/homelab/repo

# 5. Recreate all containers from compose files
cd /opt/homelab/repo/docker/fixed/nas/backup && docker compose up -d
cd /opt/homelab/repo/docker/fixed/nas/git && docker compose up -d
cd /opt/homelab/repo/docker/fixed/nas/storage && docker compose up -d
cd /opt/homelab/repo/docker/fixed/nas/monitoring && docker compose up -d

# 6. Coolify has its own compose at /data/coolify/source/
cd /data/coolify/source
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 7. Verify NFS exports are active for Docker VM
sudo exportfs -ra
```

### Scenario 4: Vaultwarden Corruption

**Impact:** Password access (cached copies work temporarily on devices)

**Recovery:**

```bash
ssh docker-vm

# 1. Stop the corrupted container
cd /opt/homelab/repo/docker/fixed/docker-vm/security
docker compose stop vaultwarden

# 2. Restore from Restic
export RESTIC_REPOSITORY="rest:http://augusto:<PASS>@192.168.0.12:8000/augusto/vaultwarden"
export RESTIC_PASSWORD="<password>"

# List snapshots to pick the right one
restic snapshots --tag vaultwarden

# Restore latest
restic restore latest --target /tmp/vw-restore --tag vaultwarden

# 3. Replace volume contents
docker run --rm -v vaultwarden-data:/data -v /tmp/vw-restore:/restore alpine \
    sh -c "rm -rf /data/* && cp -a /restore/data/* /data/"

# 4. Restart
docker compose start vaultwarden

# 5. Verify
curl -s https://vault.cronova.dev/alive
# Clean up
rm -rf /tmp/vw-restore
```

### Scenario 5: Home Assistant Corruption

**Recovery:**

```bash
ssh docker-vm

# 1. Stop HA
cd /opt/homelab/repo/docker/fixed/docker-vm/automation
docker compose stop homeassistant

# 2. Restore from Restic
export RESTIC_REPOSITORY="rest:http://augusto:<PASS>@192.168.0.12:8000/augusto/homeassistant"
export RESTIC_PASSWORD="<password>"

restic restore latest --target /tmp/ha-restore --tag homeassistant

# 3. Replace volume contents
docker run --rm -v homeassistant-config:/config -v /tmp/ha-restore:/restore alpine \
    sh -c "rm -rf /config/* && cp -a /restore/config/* /config/"

# 4. Restart
docker compose start homeassistant

# 5. Verify
curl -s https://jara.cronova.dev | head -5
rm -rf /tmp/ha-restore
```

### Scenario 6: Complete Site Failure (Power/Fire/Theft)

**What survives:** VPS keeps running (Headscale, Uptime Kuma, ntfy, Caddy)

**Recovery plan:**

1. VPS services continue operating — mesh network and external monitoring intact
2. Once power/access restored, boot Proxmox (auto-boot on AC power loss)
3. OPNsense VM starts first (start order 1), then Docker VM (start order 2, 30s delay)
4. Docker boot orchestrator runs automatically — starts all 13 phases
5. NAS boots from USB — all containers recreated from compose files
6. If hardware destroyed: rebuild from Forgejo repo + Restic backups on NAS

**If NAS is also destroyed:**
- Git history: clone from GitHub mirror (TODO: set up Forgejo → GitHub mirror)
- Compose files: in this git repo
- Secrets: in Vaultwarden (cached on devices) + .env.example templates
- Restic data: restore from Google Drive offsite (see below)

**Restoring from Google Drive offsite:**
```bash
# 1. Install rclone, restore rclone.conf from Vaultwarden backup
brew install rclone  # or apt install rclone
# Recreate rclone config with crypt password + salt from Vaultwarden

# 2. Download Restic repos
rclone copy gdrive-crypt:homelab/restic /tmp/restic-restore

# 3. Restore individual services
export RESTIC_PASSWORD="<from Vaultwarden>"
restic -r /tmp/restic-restore/augusto/vaultwarden snapshots
restic -r /tmp/restic-restore/augusto/vaultwarden restore latest --target /tmp/vw-data

# 4. Download Headscale backups
rclone copy gdrive-crypt:homelab/headscale /tmp/headscale-restore
```

### Scenario 7: Restic Password Lost

**All backups become unrecoverable.** Restic encryption is AES-256 — no backdoor.

**Prevention:**
- Password stored in Vaultwarden
- Physical copy in secure location
- RESTIC_PASSWORD is identical across all stacks (one password to remember, but one password to lose)

---

## Verification

### Automated Scripts

| Script | Purpose | Location |
|--------|---------|----------|
| `scripts/backup-verify.sh` | Monthly backup audit (6 test suites) | Docker VM |
| `scripts/backup-verify.sh --full` | Quarterly full restore drill | Docker VM |
| `scripts/backup-notify.sh` | ntfy notifications for backup events | Docker VM |

### Verification Schedule

| Task | Frequency | Procedure |
|------|-----------|-----------|
| Repository health check | Weekly (auto, Sundays) | Built into `restic-backup.sh` |
| Snapshot freshness | Monthly (1st Sunday) | `backup-verify.sh` |
| Test restore (Headscale, Vaultwarden, HA) | Monthly (1st Sunday) | `backup-verify.sh` |
| Full restore drill | Quarterly | `backup-verify.sh --full` |

See `docs/guides/backup-test-procedure.md` for detailed test procedures.

### Notifications

- Backup failures → ntfy `cronova-critical` (urgent)
- Backup success → ntfy `cronova-info` (default)
- Monthly verification results → ntfy `cronova-info`

---

## Critical Warnings

- **RESTIC_PASSWORD** is identical across all stacks — lose it = lose all backups
- **rclone crypt password + salt** — lose either = Google Drive data unreadable (store both in Vaultwarden)
- **Restoring from offsite requires ALL THREE:** rclone crypt password, rclone crypt salt, AND RESTIC_PASSWORD
- **NAS Purple 2TB at 97%** — Restic pruning manages space, but monitor closely
- **WD Red 8TB partition recovery still pending** — media storage not yet available
- **Forgejo runs on NAS** — if NAS dies, git history is only on local clones (set up GitHub mirror)
- **NAS boots from USB** — Generic Flash Disk 3.7GB must stay plugged in

---

## Post-Incident Template

```markdown
## Incident: [Service] Failure

**Date:** YYYY-MM-DD
**Duration:** X hours
**Severity:** Critical/High/Medium/Low

### What Happened
[Description]

### Impact
[What was affected]

### Timeline
- HH:MM — Issue detected
- HH:MM — Investigation started
- HH:MM — Root cause identified
- HH:MM — Recovery complete

### Root Cause
[Why it happened]

### Resolution
[What fixed it]

### Action Items
- [ ] Prevent recurrence
- [ ] Improve monitoring
- [ ] Update runbook
```

---

## References

- [Restic Documentation](https://restic.readthedocs.io/)
- [Restic REST Server](https://github.com/restic/rest-server)
- [Headscale Documentation](https://headscale.net/)
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Home Assistant Backup](https://www.home-assistant.io/common-tasks/general/#backups)
- [ntfy Documentation](https://docs.ntfy.sh/)
