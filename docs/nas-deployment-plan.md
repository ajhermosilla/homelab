# NAS Deployment Plan

Step-by-step guide to deploy the DIY NAS (Mini-ITX build from 2013).

## Hardware Summary

| Component | Model |
|-----------|-------|
| Case | Cooler Master Elite 120 Advanced |
| Motherboard | ASUS P8H77-I (LGA 1155) |
| CPU | Intel Core i3-3220T (35W TDP) |
| RAM | Kingston HyperX 8GB DDR3 |
| PSU | picoPSU-160-XT + 220W brick |

**Drives:**
| Drive | Size | Purpose | Mount |
|-------|------|---------|-------|
| Lexar NQ110 SSD | 240GB | Debian OS, Docker | / |
| WD Purple | 2TB | Frigate recordings (NFS) | /mnt/purple |
| WD Red Plus | 8TB | Media, data, backups | /mnt/red8 |

---

## Remote Preparation (Do Before Going Home)

Complete these tasks remotely before the deployment day:

### 1. Generate Tailscale Auth Key
```bash
# SSH to VPS
ssh linuxuser@100.77.172.46

# Generate pre-auth key (expires in 1 hour, single use)
# Note: Headscale 0.28.0 dropped the --user flag
docker exec headscale headscale preauthkeys create --expiration 1h

# Save the key! You'll need it during NAS setup
```

### 2. Verify OPNsense DHCP Reservation
- Login to OPNsense via Tailscale: https://100.79.230.235
- Services → DHCPv4 → LAN
- Add reservation: MAC → 192.168.1.12 (get MAC from NAS motherboard sticker)

### 3. Prepare USB Boot Drive
- Debian 12 netinst ISO already downloaded
- Flash to USB with: `sudo dd if=debian.iso of=/dev/sdX bs=4M status=progress`

### 4. Pre-generate Passwords
```bash
# Samba password
openssl rand -base64 24

# Restic htpasswd password
openssl rand -base64 24
```

Save these securely (Vaultwarden) before going home.

---

## Pre-Deployment Checklist

### Hardware Ready
- [ ] NAS assembled and tested (powers on)
- [ ] All 3 drives installed (SSD, Purple, Red)
- [ ] Ethernet cable to MokerLink switch port 4
- [ ] Power connected to UPS
- [ ] USB keyboard + monitor for initial setup

### Network Ready
- [ ] MokerLink port 4 configured as VLAN 1 access
- [ ] OPNsense DHCP reservation: 192.168.1.12 → NAS MAC
- [ ] Pi-hole DNS entry: nas.home → 192.168.1.12

### Software Ready
- [ ] Debian 12 ISO on USB (prepared already)
- [ ] Tailscale auth key from Headscale

---

## Phase 1: Debian Installation

### Boot from USB
1. Connect USB keyboard, monitor, Debian USB
2. Power on NAS
3. Press F8 (or DEL) for boot menu
4. Select USB drive

### Installation Options
| Setting | Value |
|---------|-------|
| Language | English |
| Location | Paraguay |
| Hostname | nas |
| Domain | (blank) |
| Root password | (set strong password) |
| Username | augusto |
| Timezone | America/Asuncion |
| Partitioning | Use entire disk (Lexar SSD) |
| Software | SSH server, standard utilities (no desktop) |

### Post-Install (First Boot)

```bash
# Login as root

# Update system
apt update && apt upgrade -y

# Install essentials
apt install -y sudo curl wget git vim htop tmux

# Add user to sudo
usermod -aG sudo augusto

# Set static IP (if DHCP reservation not working)
nano /etc/network/interfaces
# auto enp0s25
# iface enp0s25 inet static
#   address 192.168.1.12
#   netmask 255.255.255.0
#   gateway 192.168.1.1
#   dns-nameservers 192.168.1.1

# Reboot
reboot
```

---

## Phase 2: Drive Setup

### Identify Drives

```bash
# List all drives
lsblk -f

# Expected:
# sda - Lexar 240GB (boot, ext4)
# sdb - WD Purple 2TB
# sdc - WD Red Plus 8TB

# Check drive health
sudo smartctl -a /dev/sdb
sudo smartctl -a /dev/sdc
```

### Partition Drives (if needed)

```bash
# If drives are unformatted:

# Purple 2TB
sudo fdisk /dev/sdb
# n (new), p (primary), 1, defaults, w (write)
sudo mkfs.ext4 -L purple /dev/sdb1

# Red 8TB
sudo fdisk /dev/sdc
# n (new), p (primary), 1, defaults, w (write)
sudo mkfs.ext4 -L red8 /dev/sdc1
```

### Create Mount Points

```bash
sudo mkdir -p /mnt/{purple,red8}
```

### Configure fstab

```bash
# Get UUIDs
sudo blkid

# Edit fstab
sudo nano /etc/fstab

# Add these lines:
UUID=<purple-uuid>  /mnt/purple  ext4  defaults,noatime  0  2
UUID=<red8-uuid>    /mnt/red8    ext4  defaults,noatime  0  2
```

### Mount and Verify

```bash
sudo mount -a
df -h

# Should show:
# /mnt/purple - 2TB
# /mnt/red8   - 8TB
```

### Create Directory Structure

```bash
# On Red 8TB
sudo mkdir -p /mnt/red8/{media,downloads,data,sync,backup}

# On Purple 2TB
sudo mkdir -p /mnt/purple/frigate

# Create symlinks in /srv
sudo mkdir -p /srv
sudo ln -s /mnt/red8/media /srv/media
sudo ln -s /mnt/red8/downloads /srv/downloads
sudo ln -s /mnt/red8/data /srv/data
sudo ln -s /mnt/red8/sync /srv/sync
sudo ln -s /mnt/red8/backup /srv/backup
sudo ln -s /mnt/purple/frigate /srv/frigate

# Set ownership
sudo chown -R 1000:1000 /mnt/red8 /mnt/purple /srv
```

---

## Phase 3: Docker Installation

```bash
# Install Docker (official method)
curl -fsSL https://get.docker.com | sudo sh

# Add user to docker group
sudo usermod -aG docker augusto

# Logout and login again
exit
# SSH back in

# Verify
docker --version
docker compose version

# Test
docker run hello-world
```

---

## Phase 4: Tailscale Installation

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to Headscale
sudo tailscale up --login-server=https://hs.cronova.dev --authkey=<key>

# Verify
tailscale status
tailscale ip

# Expected IP: 100.x.x.12 range
```

---

## Phase 5: NFS Server Setup

### Option A: Ansible Playbook (Recommended)

Run from your MacBook after NAS is accessible via SSH:

```bash
cd ~/homelab/ansible

# Test connection first
ansible -i inventory.yml nas -m ping

# Run NFS server playbook (creates dirs, symlinks, exports, firewall)
ansible-playbook -i inventory.yml playbooks/nfs-server.yml -l nas
```

The playbook automatically:
- Creates /srv symlinks to drive mounts
- Configures /etc/exports with correct permissions
- Opens firewall ports (111, 2049)
- Starts NFS server

### Option B: Manual Setup

If Ansible isn't available:

```bash
# Install NFS
sudo apt install -y nfs-kernel-server

# Configure exports
sudo nano /etc/exports

# Add:
/srv/frigate    192.168.1.10(rw,sync,no_subtree_check,no_root_squash)
/srv/media      192.168.1.0/24(ro,sync,no_subtree_check)
/srv/downloads  192.168.1.0/24(rw,sync,no_subtree_check)
/srv/backup     192.168.1.0/24(rw,sync,no_subtree_check)

# Apply and start
sudo exportfs -ra
sudo exportfs -v
sudo systemctl enable nfs-kernel-server
sudo systemctl start nfs-kernel-server

# Open firewall
sudo ufw allow from 192.168.1.0/24 to any port 111
sudo ufw allow from 192.168.1.0/24 to any port 2049
```

---

## Phase 6: Clone Homelab Repo

```bash
# Create opt directory
sudo mkdir -p /opt/homelab
sudo chown augusto:augusto /opt/homelab

# Clone repo
git clone git@github.com:ajhermosilla/homelab.git /opt/homelab/repo

# Or via HTTPS if SSH not configured
git clone https://github.com/ajhermosilla/homelab.git /opt/homelab/repo
```

---

## Phase 7: Deploy Docker Services

### Storage Stack (Samba + Syncthing)

```bash
cd /opt/homelab/repo/docker/fixed/nas/storage

# Create .env from example
cp .env.example .env
nano .env

# Set values:
# TZ=America/Asuncion
# PUID=1000
# PGID=1000
# SAMBA_USER=augusto
# SAMBA_PASSWORD=<generate-strong-password>
# MEDIA_PATH=/srv/media
# DATA_PATH=/srv/data
# DOWNLOADS_PATH=/srv/downloads
# BACKUP_PATH=/srv/backup
# SYNC_PATH=/srv/sync

# Start services
docker compose up -d

# Verify
docker compose ps
docker compose logs -f
```

### Backup Stack (Restic REST)

```bash
cd /opt/homelab/repo/docker/fixed/nas/backup

# Create backup directory
sudo mkdir -p /srv/backup/restic
sudo chown 1000:1000 /srv/backup/restic

# Create htpasswd file
sudo apt install -y apache2-utils
htpasswd -B -c htpasswd augusto
# Enter password when prompted

# Create .env
cp .env.example .env
nano .env
# BACKUP_DATA=/srv/backup/restic

# Start service
docker compose up -d

# Verify
docker compose ps
curl http://localhost:8000/
```

---

## Phase 8: Verification

### Network Connectivity

```bash
# From MacBook via Tailscale
ping 100.x.x.12  # NAS Tailscale IP
ssh augusto@100.x.x.12

# From local network
ping 192.168.1.12
```

### Samba Shares

```bash
# From MacBook Finder:
# Go → Connect to Server → smb://192.168.1.12/media

# Or via Tailscale:
# smb://100.x.x.12/media
```

### NFS (test from Docker VM later)

```bash
# On Docker VM:
sudo apt install nfs-common
sudo mount -t nfs 192.168.1.12:/srv/frigate /mnt/nas/frigate
```

### Syncthing

```bash
# Access web UI via Tailscale
# http://100.x.x.12:8384

# Or SSH tunnel:
ssh -L 8384:localhost:8384 augusto@100.x.x.12
# Then open http://localhost:8384
```

### Restic REST

```bash
# Test API
curl http://192.168.1.12:8000/

# Initialize repo from Docker VM later
```

---

## Post-Deployment

### Add DNS Entries (Pi-hole)

| Hostname | IP |
|----------|-----|
| nas.home | 192.168.1.12 |
| syncthing.home | 192.168.1.12 |

### Add Uptime Kuma Monitors

| Service | Check |
|---------|-------|
| NAS SSH | TCP 192.168.1.12:22 |
| Samba | TCP 192.168.1.12:445 |
| Syncthing | HTTP 192.168.1.12:8384 |
| Restic REST | HTTP 192.168.1.12:8000 |
| NFS | TCP 192.168.1.12:2049 |

### BIOS Settings

- **Restore on AC Power Loss**: Power On (auto-boot after outage)
- **Wake on LAN**: Enabled (optional)

---

## Troubleshooting

### Drive Not Mounting
```bash
# Check drive is detected
lsblk
sudo fdisk -l

# Check SMART health
sudo apt install smartmontools
sudo smartctl -H /dev/sdb

# Manual mount test
sudo mount /dev/sdb1 /mnt/purple
```

### NFS Not Working
```bash
# Check service status
sudo systemctl status nfs-kernel-server

# Verify exports
sudo exportfs -v

# Check firewall
sudo ufw status

# Test from Docker VM
showmount -e 192.168.1.12
```

### Samba Connection Failed
```bash
# Check container logs
docker logs samba

# Test authentication
smbclient -L localhost -U augusto

# Check ports
ss -tlnp | grep -E '139|445'
```

### Tailscale Won't Connect
```bash
# Check status
tailscale status

# Re-authenticate (get new key from Headscale)
sudo tailscale up --login-server=https://hs.cronova.dev --authkey=<new-key> --reset
```

---

## Rollback Plan

If something goes wrong:

1. **Docker issues**: `docker compose down && docker compose up -d`
2. **Drive mount issues**: Boot from USB, check fstab
3. **Network issues**: Connect via keyboard/monitor, check `/etc/network/interfaces`
4. **Full reinstall**: Debian reinstall on SSD only (data drives untouched)

---

## Time Estimate

| Phase | Estimate |
|-------|----------|
| Debian install | 20-30 min |
| Drive setup | 15-20 min |
| Docker + Tailscale | 10-15 min |
| NFS setup | 10 min |
| Docker services | 15-20 min |
| Verification | 15-20 min |
| **Total** | ~1.5-2 hours |

---

## Camera Installation (After NAS)

Once NAS is running with NFS:

1. Mount PoE cameras on wall/ceiling
2. Connect to TP-Link PoE switch (ports 2-3)
3. Cameras auto-get DHCP from IoT VLAN (192.168.10.x)
4. Set static IPs via camera web UI:
   - Cam 1: 192.168.10.101
   - Cam 2: 192.168.10.102
5. Add firewall rule in OPNsense: IoT → 192.168.1.x:5000 (Frigate)
6. Configure cameras in Frigate config

---

## References

- [docs/hardware.md](hardware.md) - Full hardware specs
- [docs/nfs-setup.md](nfs-setup.md) - NFS configuration details
- [docs/deployment-order.md](deployment-order.md) - Service dependencies
- [docker/fixed/nas/](../docker/fixed/nas/) - Docker compose files
