# Disaster Recovery Runbook

Procedures for recovering from failures across all homelab environments. Created 2026-01-14.

## Critical Services Priority

```
┌─────────────────────────────────────────────────────────────────┐
│                    RECOVERY PRIORITY ORDER                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. HEADSCALE (VPS)       ← Mesh dies without this              │
│  2. Pi-hole (any)         ← DNS resolution                      │
│  3. VPS Services          ← Public endpoints                    │
│  4. Vaultwarden           ← Password access                     │
│  5. Everything else       ← Nice to have                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Backup Strategy

### What's Backed Up

| Service | Data Location | Backup Target | Frequency | Retention |
|---------|---------------|---------------|-----------|-----------|
| **Headscale** | `/etc/headscale/` | NAS + Cloud | Hourly | 30 days |
| **Pi-hole** | `/etc/pihole/` | NAS | Daily | 7 days |
| **Vaultwarden** | `/var/lib/vaultwarden/` | NAS + Cloud | Hourly | 30 days |
| **Home Assistant** | `/config/` | NAS | Daily | 14 days |
| **Start9** | Built-in backup | NAS | Weekly | 4 weeks |
| **Frigate** | Config only | NAS | Daily | 7 days |
| **soft-serve** | Git repos | NAS | Daily | 14 days |

### Backup Locations

```
┌─────────────────────────────────────────────────────────────────┐
│                      BACKUP TOPOLOGY                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Services]                                                      │
│      │                                                           │
│      ├──► [NAS - Primary Backup]                                │
│      │    /backups/                                              │
│      │    ├── headscale/                                         │
│      │    ├── pihole/                                            │
│      │    ├── vaultwarden/                                       │
│      │    ├── homeassistant/                                     │
│      │    ├── start9/                                            │
│      │    └── soft-serve/                                        │
│      │                                                           │
│      └──► [Cloud - Critical Only]                               │
│           ├── headscale/ (B2/Backblaze or similar)              │
│           └── vaultwarden/                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Backup Scripts

#### Headscale Backup (Hourly Cron)

```bash
#!/bin/bash
# /opt/scripts/backup-headscale.sh
# Run: 0 * * * * /opt/scripts/backup-headscale.sh

TIMESTAMP=$(date +%Y%m%d_%H%M)
BACKUP_DIR="/mnt/nas/backups/headscale"
SOURCE="/etc/headscale"

# Create backup
tar -czf "${BACKUP_DIR}/headscale_${TIMESTAMP}.tar.gz" \
    -C /etc headscale/

# Keep only last 720 backups (30 days * 24 hours)
ls -t ${BACKUP_DIR}/headscale_*.tar.gz | tail -n +721 | xargs -r rm

# Sync critical to cloud (if configured)
# rclone sync ${BACKUP_DIR} b2:homelab-backups/headscale --max-age 24h
```

#### Vaultwarden Backup (Hourly Cron)

```bash
#!/bin/bash
# /opt/scripts/backup-vaultwarden.sh
# Run: 30 * * * * /opt/scripts/backup-vaultwarden.sh

TIMESTAMP=$(date +%Y%m%d_%H%M)
BACKUP_DIR="/mnt/nas/backups/vaultwarden"
SOURCE="/var/lib/vaultwarden"

# Stop container briefly for consistent backup
docker stop vaultwarden

# Create backup
tar -czf "${BACKUP_DIR}/vaultwarden_${TIMESTAMP}.tar.gz" \
    -C /var/lib vaultwarden/

# Restart container
docker start vaultwarden

# Keep only last 720 backups
ls -t ${BACKUP_DIR}/vaultwarden_*.tar.gz | tail -n +721 | xargs -r rm
```

---

## Scenario 1: Headscale Failure

### Symptoms
- Tailscale clients show "Unable to connect to coordination server"
- New devices cannot join mesh
- Existing connections may work briefly (cached)

### Impact
- **Critical**: All mesh networking degraded
- Existing peer-to-peer connections continue working
- No new connections or re-authentication possible

### Recovery Procedure

#### Option A: Restore on VPS (Primary Location)

```bash
# 1. SSH to VPS
ssh linuxuser@vps

# 2. Check Headscale container status
docker ps -a | grep headscale
docker logs headscale --tail 50

# 3. If config corrupted, restore from backup
cd /opt/homelab/headscale
docker compose down
LATEST_BACKUP=$(ls -t /mnt/nas/backups/headscale/*.tar.gz | head -1)
sudo tar -xzf ${LATEST_BACKUP} -C ./config/
docker compose up -d

# 4. Verify
docker exec headscale headscale nodes list
docker exec headscale headscale users list
```

#### Option B: Rebuild VPS from Scratch

```bash
# 1. Provision new VPS (Vultr, Debian)
# 2. Basic setup
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget docker.io docker-compose-plugin

# 3. Deploy Headscale via Docker Compose
mkdir -p /opt/homelab/headscale && cd /opt/homelab/headscale
# Copy docker-compose.yml and config from repo

# 4. Restore configuration from backup
LATEST_BACKUP=$(ls -t /mnt/nas/backups/headscale/*.tar.gz | head -1)
# Or download from cloud: rclone copy b2:homelab-backups/headscale/latest.tar.gz /tmp/
sudo tar -xzf ${LATEST_BACKUP} -C ./config/

# 5. Start service
docker compose up -d

# 6. Verify all nodes reconnect
docker exec headscale headscale nodes list
```

#### Option C: Emergency Alternative Host

If VPS is unavailable:

```bash
# 1. SSH to VPS
ssh admin@vps.cronova.dev

# 2. Install Headscale on VPS (temporary)
wget https://github.com/juanfont/headscale/releases/latest/download/headscale_linux_amd64.deb
sudo dpkg -i headscale_linux_amd64.deb

# 3. Restore config from cloud backup
rclone copy b2:homelab-backups/headscale/latest.tar.gz /tmp/
sudo tar -xzf /tmp/latest.tar.gz -C /etc/

# 4. Update config for VPS IP
sudo nano /etc/headscale/config.yaml
# Change server_url to VPS public IP

# 5. Update DNS
# Point hs.cronova.dev to VPS IP (Cloudflare)

# 6. Start service
sudo systemctl enable headscale
sudo systemctl start headscale

# 7. Force clients to reconnect
# On each client: tailscale up --login-server=https://hs.cronova.dev
```

### Prevention
- Hourly backups to NAS
- Daily sync to cloud storage
- Monitor with Uptime Kuma (check every 60s)

---

## Scenario 2: Pi-hole Failure

### Symptoms
- DNS resolution fails
- Devices show "DNS server not responding"
- Web browsing stops working

### Impact
- **High**: No DNS = no internet (feels like)
- Tailscale mesh still works (uses IPs internally)

### Recovery Procedure

#### Quick Fix: Use Backup DNS

```bash
# On affected device, temporarily use public DNS
# Linux/Mac
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Or configure router DHCP to use 1.1.1.1 temporarily
```

#### Restore Pi-hole

```bash
# 1. SSH to Pi-hole host
ssh admin@pihole.local

# 2. Check Pi-hole status
pihole status
docker logs pihole

# 3. If container issue, restart
docker restart pihole

# 4. If data corrupted, restore
docker stop pihole
LATEST_BACKUP=$(ls -t /mnt/nas/backups/pihole/*.tar.gz | head -1)
sudo tar -xzf ${LATEST_BACKUP} -C /etc/
docker start pihole

# 5. Verify
pihole -t  # Watch live queries
dig @localhost google.com
```

#### Rebuild Pi-hole (Docker)

```bash
# 1. Pull fresh image
docker pull pihole/pihole:latest

# 2. Remove old container (keeps data if volumes correct)
docker rm -f pihole

# 3. Recreate from compose
cd /opt/docker/networking
docker compose up -d pihole

# 4. Restore config if needed
docker exec -it pihole pihole -r  # Repair
```

### Prevention
- Run Pi-hole on multiple hosts (Mobile + Fixed + VPS)
- Configure DHCP with multiple DNS servers
- Daily config backups

---

## Scenario 3: VPS Failure

### Symptoms
- Public services unreachable (status.cronova.dev, notify.cronova.dev)
- DERP relay unavailable (Tailscale direct connections still work)
- Uptime Kuma alerts stop (ironic)

### Impact
- **Medium**: Public services down
- Tailscale mesh continues (peer-to-peer)
- No external notifications (ntfy)

### Recovery Procedure

#### Option A: Vultr Recovery

```bash
# 1. Check Vultr console
# https://my.vultr.com/

# 2. If VM crashed, try restart from console

# 3. If disk corrupt, restore from snapshot
# Vultr Dashboard > Snapshots > Restore

# 4. SSH and verify services
ssh admin@vps.cronova.dev
docker ps
docker compose -f /opt/docker/monitoring/docker-compose.yml up -d
```

#### Option B: Rebuild VPS

```bash
# 1. Create new Vultr instance
# - Ubuntu 24.04 LTS
# - $6/mo plan
# - US region

# 2. Initial setup
ssh root@NEW_IP
apt update && apt upgrade -y
apt install -y docker.io docker-compose-plugin

# 3. Clone homelab repo
git clone git@github.com:cronova/homelab.git /opt/homelab

# 4. Decrypt secrets
cd /opt/homelab
sops -d secrets/vps.enc.yaml > .env

# 5. Deploy services
cd /opt/docker/vps
docker compose up -d

# 6. Update DNS
# Point status.cronova.dev, notify.cronova.dev to NEW_IP

# 7. Re-join Tailscale
tailscale up --login-server=https://hs.cronova.dev

# 8. Update Uptime Kuma monitors
```

### Prevention
- Weekly Vultr snapshots
- All configs in git (homelab repo)
- Secrets encrypted with SOPS

---

## Scenario 4: Vaultwarden Failure

### Symptoms
- Password manager clients show sync errors
- Cannot access passwords
- Browser extensions fail

### Impact
- **Critical for productivity**: No password access
- Can use cached passwords on devices temporarily

### Recovery Procedure

```bash
# 1. SSH to Docker host
ssh admin@docker.home.cronova.dev

# 2. Check container
docker logs vaultwarden
docker inspect vaultwarden

# 3. If container crashed, restart
docker restart vaultwarden

# 4. If data corrupted, restore from backup
docker stop vaultwarden
LATEST_BACKUP=$(ls -t /mnt/nas/backups/vaultwarden/*.tar.gz | head -1)
sudo rm -rf /var/lib/vaultwarden/*
sudo tar -xzf ${LATEST_BACKUP} -C /var/lib/
docker start vaultwarden

# 5. Verify
curl -I https://vault.cronova.dev
# Test login in browser
```

### Emergency Access
- Export passwords periodically to encrypted file
- Store master password in physical safe
- Keep KeePassXC backup of critical passwords

### Prevention
- Hourly backups (data changes frequently)
- Cloud backup for offsite copy
- Regular export to encrypted backup

---

## Scenario 5: Start9 (Bitcoin Node) Failure

### Symptoms
- Bitcoin/Lightning services unavailable
- Electrum wallet cannot connect
- Start9 web UI inaccessible

### Impact
- **Medium**: Bitcoin services down
- No financial loss (funds safe on blockchain)
- Wallet access via other Electrum servers temporarily

### Recovery Procedure

```bash
# 1. Access Start9 directly (keyboard/monitor on RPi 4)
# Or SSH if still accessible

# 2. Check Start9 status
# Web UI: http://start9.local

# 3. If services crashed, restart via UI
# Services > Bitcoin Core > Restart

# 4. If OS corrupt, reflash
# Download Start9 OS: https://start9.com/latest
# Flash to SD card
# Restore from Start9 backup (stored on NAS)

# 5. Restore wallet
# Import seed phrase (stored securely offline)
```

### Prevention
- Weekly Start9 backups to NAS
- Seed phrases stored offline (paper/metal)
- Don't keep large amounts on hot wallet

---

## Scenario 6: NAS Failure

### Symptoms
- Syncthing sync fails
- Frigate recordings unavailable
- Backups failing

### Impact
- **Medium**: Storage and backups affected
- Services continue running (data on local disks)

### Recovery Procedure

#### Disk Failure (Single Disk)

```bash
# 1. Check disk status
sudo smartctl -a /dev/sdX
cat /proc/mdstat  # If using RAID

# 2. SnapRAID can recover single disk failure
snapraid status
snapraid fix -d diskX

# 3. Replace failed disk
# Power down, swap disk
# Rebuild: snapraid fix
```

#### Complete NAS Failure

```bash
# 1. Install fresh Debian on replacement hardware
# 2. Install mergerfs + snapraid
# 3. Restore data from cloud backup (if critical)
# 4. Rebuild from service hosts (they have local copies)
```

### Prevention
- SnapRAID parity for disk failure protection
- Critical data also in cloud
- Monitor disk health with smartmontools

---

## Scenario 7: Complete Site Failure

### Symptoms
- All services at one location unreachable
- Power outage, fire, theft, etc.

### Impact
- **Variable**: Depends on which site

### Mobile Kit Lost/Stolen

```bash
# 1. Revoke Tailscale keys immediately
headscale nodes delete rpi5-mobile
headscale nodes delete macbook

# 2. Change all passwords (via backup Vaultwarden export)

# 3. Rebuild from:
#    - Git repo (homelab configs)
#    - Cloud backup (Headscale DB)
#    - New hardware
```

### Fixed Homelab Down

```bash
# 1. VPS continues operating
# 2. Mobile kit can become temporary primary
# 3. Rebuild when power/access restored
```

### VPS Provider Failure

```bash
# 1. Spin up on different provider (DigitalOcean, Hetzner)
# 2. Restore from git repo
# 3. Update DNS
```

---

## Recovery Checklist

### Before Any Recovery

- [ ] Identify the failure scope
- [ ] Check if recent backup exists
- [ ] Document what happened (for post-mortem)
- [ ] Communicate with family/users if extended downtime

### After Recovery

- [ ] Verify service functionality
- [ ] Check backup jobs running
- [ ] Update monitoring if IPs changed
- [ ] Document any config changes
- [ ] Schedule post-mortem review

---

## Backup Verification Schedule

| Task | Frequency | Procedure |
|------|-----------|-----------|
| List backups | Weekly | `ls -la /mnt/nas/backups/*/` |
| Test restore | Monthly | Restore Headscale to test VM |
| Verify cloud sync | Weekly | Check rclone logs |
| Test DR procedure | Quarterly | Full recovery drill |

### Monthly Backup Test Script

```bash
#!/bin/bash
# /opt/scripts/test-backup-restore.sh

echo "=== Backup Verification $(date) ==="

# Check backup freshness
for service in headscale vaultwarden pihole; do
    LATEST=$(ls -t /mnt/nas/backups/${service}/*.tar.gz 2>/dev/null | head -1)
    if [ -z "$LATEST" ]; then
        echo "FAIL: No backup for ${service}"
    else
        AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST")) / 3600 ))
        if [ $AGE -gt 48 ]; then
            echo "WARN: ${service} backup is ${AGE} hours old"
        else
            echo "OK: ${service} backup is ${AGE} hours old"
        fi
    fi
done

# Test Headscale restore (to temp directory)
echo "Testing Headscale restore..."
LATEST_HS=$(ls -t /mnt/nas/backups/headscale/*.tar.gz | head -1)
rm -rf /tmp/headscale-test
mkdir -p /tmp/headscale-test
tar -xzf ${LATEST_HS} -C /tmp/headscale-test
if [ -f /tmp/headscale-test/headscale/config.yaml ]; then
    echo "OK: Headscale backup valid"
else
    echo "FAIL: Headscale backup corrupt"
fi
rm -rf /tmp/headscale-test
```

---

## Emergency Contacts

| Service | Support |
|---------|---------|
| Vultr | support@vultr.com |
| Cloudflare | Dashboard tickets |
| Start9 | community.start9.com |
| Tailscale/Headscale | GitHub issues |

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
- HH:MM - Issue detected
- HH:MM - Investigation started
- HH:MM - Root cause identified
- HH:MM - Recovery complete

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

- [Headscale Documentation](https://headscale.net/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Start9 Documentation](https://docs.start9.com/)
- [SnapRAID Manual](https://www.snapraid.it/manual)
